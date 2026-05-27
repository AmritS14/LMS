import SwiftUI

// MARK: - Filter Structures
struct AuditFilterCriteria {
    var dateRange: AuditDateFilter = .all
    var actionType: String = "All"
    var actorRole: String = "All"
    var status: String = "All"
}

enum AuditDateFilter: String, CaseIterable, Identifiable {
    case all = "All Time"
    case today = "Today"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    var id: String { self.rawValue }
}

// MARK: - Redesigned Audit Trail View
struct AuditTrailView: View {
    // Session list of entries
    @State private var entries: [AuditEntry] = AdminSeedData.auditEntries
    
    // Search & Filter State
    @State private var searchText = ""
    @State private var filterCriteria = AuditFilterCriteria()
    @State private var showFilterSheet = false
    
    // Log Details Sheet State
    @State private var selectedEntryForDetails: AuditEntry? = nil
    
    // Export Flow State
    @State private var isExporting = false
    @State private var exportProgressText = ""
    @State private var showExportShareSheet = false
    @State private var exportURL: URL? = nil
    @State private var simulateExportFail = false
    
    // Interactive Simulation States
    @State private var isLoading = false
    @State private var hasError = false
    
    // Toast Feedback HUD State
    @State private var toastMessage: String? = nil
    @State private var showToast = false
    
    // Available filter pickers lists
    private let actionTypes = ["All", "Updated role", "Reviewed application", "Verified document", "Deleted log", "Created user"]
    private let actorRoles = ["All", "Admin", "Manager", "Loan Officer"]
    private let statuses = ["All", "Success", "Failure"]
    
    // MARK: - Computed Properties
    private var filteredEntries: [AuditEntry] {
        entries.filter { entry in
            // Search
            if !searchText.isEmpty {
                let search = searchText.lowercased()
                let matchesSearch = entry.action.lowercased().contains(search) ||
                                    entry.entityType.lowercased().contains(search) ||
                                    actorName(for: entry.actorID).lowercased().contains(search)
                if !matchesSearch { return false }
            }
            
            // Date Filter
            let daysAgo = Calendar.current.dateComponents([.day], from: entry.timestamp, to: Date()).day ?? 0
            switch filterCriteria.dateRange {
            case .today:
                if daysAgo > 0 { return false }
            case .last7Days:
                if daysAgo > 7 { return false }
            case .last30Days:
                if daysAgo > 30 { return false }
            case .all:
                break
            }
            
            // Action Type Filter
            if filterCriteria.actionType != "All", entry.action != filterCriteria.actionType {
                return false
            }
            
            // Role Filter
            if filterCriteria.actorRole != "All", entry.actorRole.displayName != filterCriteria.actorRole {
                return false
            }
            
            // Status Filter
            let status = entry.metadata["status"] ?? "Success"
            if filterCriteria.status != "All", status != filterCriteria.status {
                return false
            }
            
            return true
        }
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Compliance banner
                complianceBanner
                
                // Simulation control bar
                simulationControlBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                
                // Search bar and filter toggle
                HStack(spacing: 12) {
                    SearchBarView(text: $searchText, placeholder: "Search logs by User, Action or Target...")
                    
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.body)
                            .padding(8)
                            .background(isFiltersApplied ? Color.blue.opacity(0.12) : Color.primary.opacity(0.04), in: Circle())
                            .foregroundStyle(isFiltersApplied ? .blue : .primary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                
                Divider()
                
                if isLoading {
                    skeletonLoadingView
                } else if hasError {
                    errorStateView
                } else if filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(filteredEntries.enumerated()), id: \.element.id) { index, entry in
                                Button {
                                    selectedEntryForDetails = entry
                                } label: {
                                    timelineRow(entry: entry, isLast: index == filteredEntries.count - 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            
            // Loading Export HUD overlay
            if isExporting {
                exportProgressOverlay
            }
            
            // Toast HUD
            if showToast, let msg = toastMessage {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: msg.contains("Failed") ? "xmark.octagon.fill" : "checkmark.circle.fill")
                            .foregroundStyle(msg.contains("Failed") ? .red : .green)
                        Text(msg)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
                    .shadow(radius: 6)
                    .padding(.bottom, 36)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle("Audit Trail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { startExport(format: "CSV") }) {
                        Label("Export CSV", systemImage: "doc.text")
                    }
                    Button(action: { startExport(format: "PDF") }) {
                        Label("Export PDF", systemImage: "doc.plaintext")
                    }
                    Divider()
                    Button(action: { simulateExportFail.toggle() }) {
                        Label(simulateExportFail ? "Export: Force Success" : "Export: Force Fail", systemImage: simulateExportFail ? "checkmark.shield" : "xmark.shield")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(isLoading || hasError)
            }
        }
        
        // Log Details Presentation Sheet
        .sheet(item: $selectedEntryForDetails) { entry in
            logDetailView(entry: entry)
        }
        
        // Bottom Sheet Filter
        .sheet(isPresented: $showFilterSheet) {
            bottomSheetFilterView
        }
        
        // Share sheet bridge
        .sheet(isPresented: $showExportShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    // MARK: - Timeline Card Row
    private func timelineRow(entry: AuditEntry, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline line and circle
            VStack(spacing: 0) {
                Circle()
                    .fill(timelineCircleColor(for: entry.actorRole))
                    .frame(width: 12, height: 12)
                
                if !isLast {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(.top, 4)
            .padding(.leading, 24)
            
            // Content Card
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.action)
                            .font(.lmsHeadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text("\(entry.entityType) • ID: \(entry.entityID.uuidString.prefix(8))")
                            .font(.lmsCaption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    let status = entry.metadata["status"] ?? "Success"
                    StatusBadge(status, tone: status == "Success" ? .success : .danger, size: .small)
                }
                
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(actorName(for: entry.actorID))
                        .font(.lmsSubheadline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
            .padding(.trailing, 24)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Log Detail Sheet View
    private func logDetailView(entry: AuditEntry) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(entry.action)
                                .font(.lmsTitle2)
                                .fontWeight(.bold)
                            Spacer()
                            let status = entry.metadata["status"] ?? "Success"
                            StatusBadge(status, tone: status == "Success" ? .success : .danger)
                        }
                        
                        Divider()
                        
                        detailField(label: "Audit Event ID", value: entry.id.uuidString)
                        detailField(label: "Timestamp", value: entry.timestamp.formatted(date: .long, time: .complete))
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    
                    // Actor Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Actor Details")
                            .font(.lmsHeadline)
                            .foregroundStyle(.secondary)
                        
                        Divider()
                        
                        detailField(label: "Full Name", value: actorName(for: entry.actorID))
                        detailField(label: "Role", value: entry.actorRole.displayName)
                        detailField(label: "User UUID ID", value: entry.actorID.uuidString)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    
                    // Target Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Target Entity")
                            .font(.lmsHeadline)
                            .foregroundStyle(.secondary)
                        
                        Divider()
                        
                        detailField(label: "Entity/Target Type", value: entry.entityType)
                        detailField(label: "Target Record UUID ID", value: entry.entityID.uuidString)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    
                    // Metadata Card
                    if !entry.metadata.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Event Metadata")
                                .font(.lmsHeadline)
                                .foregroundStyle(.secondary)
                            
                            Divider()
                            
                            ForEach(Array(entry.metadata.keys.sorted()), id: \.self) { key in
                                if key != "status" {
                                    detailField(label: key.capitalized, value: entry.metadata[key] ?? "")
                                }
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Audit Log Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        selectedEntryForDetails = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Sheet Filter View
    private var bottomSheetFilterView: some View {
        NavigationStack {
            Form {
                Section("Date Period") {
                    Picker("Closed Date", selection: $filterCriteria.dateRange) {
                        ForEach(AuditDateFilter.allCases) { opt in
                            Text(opt.rawValue).tag(opt)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Action Type") {
                    Picker("Select Action", selection: $filterCriteria.actionType) {
                        ForEach(actionTypes, id: \.self) { act in
                            Text(act).tag(act)
                        }
                    }
                }
                
                Section("Actor Role") {
                    Picker("Select Role", selection: $filterCriteria.actorRole) {
                        ForEach(actorRoles, id: \.self) { role in
                            Text(role).tag(role)
                        }
                    }
                }
                
                Section("Status") {
                    Picker("Select Status", selection: $filterCriteria.status) {
                        ForEach(statuses, id: \.self) { st in
                            Text(st).tag(st)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Filter Audit Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        filterCriteria = AuditFilterCriteria()
                        showFilterSheet = false
                    }
                    .foregroundStyle(.red)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        showFilterSheet = false
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    // MARK: - Helper Views & Components
    
    private var complianceBanner: some View {
        HStack {
            Image(systemName: "shield.fill")
                .font(.caption)
                .foregroundStyle(.blue)
            Text("Read Only - Compliance Audit Trail")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.blue)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.12))
    }
    
    private var simulationControlBar: some View {
        HStack {
            Text("Simulator Tools:")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                isLoading = true
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    isLoading = false
                }
            } label: {
                Label("Sim Load", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 10, weight: .bold))
            }
            .buttonStyle(.bordered)
            
            Button {
                hasError.toggle()
            } label: {
                Label(hasError ? "Clear Error" : "Sim Error", systemImage: "exclamationmark.triangle")
                    .font(.system(size: 10, weight: .bold))
            }
            .buttonStyle(.bordered)
            .tint(hasError ? .green : .red)
        }
    }
    
    private var exportProgressOverlay: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 20) {
                    ProgressView()
                        .tint(.white)
                    Text(exportProgressText)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding(24)
                .background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
            }
    }
    
    private func detailField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.lmsBody)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var isFiltersApplied: Bool {
        filterCriteria.dateRange != .all ||
        filterCriteria.actionType != "All" ||
        filterCriteria.actorRole != "All" ||
        filterCriteria.status != "All"
    }
    
    private func actorName(for actorID: UUID) -> String {
        AdminSeedData.users.first(where: { $0.id == actorID })?.fullName ?? "System Administrator"
    }
    
    private func timelineCircleColor(for role: UserRole) -> Color {
        switch role {
        case .admin: return .blue
        case .manager: return .purple
        case .loanOfficer: return .orange
        case .borrower: return .green
        }
    }
    
    // MARK: - Simulation States Subviews
    
    private var skeletonLoadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<4) { _ in
                HStack(alignment: .top, spacing: 16) {
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 12, height: 12)
                        .padding(.top, 4)
                        .padding(.leading, 24)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 160, height: 20)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 240, height: 16)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.trailing, 24)
                }
            }
            Spacer()
        }
        .padding(.top, 16)
    }
    
    private var errorStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
            Text("Could not load logs")
                .font(.headline)
            Text("A network connection problem was detected. Please verify your connection.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Retry") {
                hasError = false
                isLoading = true
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    isLoading = false
                }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "list.clipboard")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No Audit Activity")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("There are no compliance log records matching current criteria.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func startExport(format: String) {
        isExporting = true
        exportProgressText = "Exporting data..."
        triggerToast("Export Started")
        
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            
            if simulateExportFail {
                await MainActor.run {
                    isExporting = false
                    triggerToast("Export Failed")
                }
            } else {
                // Create mock file
                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent("LMS_Audit_Export_\(Int.random(in: 1000...9999)).\(format.lowercased())")
                try? "LMS Audit Event Logs Mock Export Data (\(format))".write(to: fileURL, atomically: true, encoding: .utf8)
                
                await MainActor.run {
                    isExporting = false
                    exportURL = fileURL
                    triggerToast("Export Completed")
                    showExportShareSheet = true
                }
            }
        }
    }
    
    private func triggerToast(_ message: String) {
        toastMessage = message
        withAnimation(.easeOut(duration: 0.25)) {
            showToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeIn(duration: 0.25)) {
                showToast = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        AuditTrailView()
    }
}