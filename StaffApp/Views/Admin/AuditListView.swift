import SwiftUI

@MainActor
@Observable
final class AuditViewModel {
    var entries: [AuditEntry] = []
    var isLoading = false
    var error: String? = nil

    private var environment: AppEnvironment?

    func configure(environment: AppEnvironment?) {
        self.environment = environment
    }

    func loadLogs() async {
        guard let environment else { return }
        
        isLoading = true
        error = nil
        do {
            self.entries = try await environment.admin.fetchAuditLogs()
        } catch {
            self.error = error.localizedDescription
            print("Failed to fetch audit logs: \(error)")
        }
        isLoading = false
    }

    func generateCSV(from filteredEntries: [AuditEntry]) -> URL? {
        var csvString = "ID,Timestamp,Actor Role,Actor ID,Action,Entity Type,Entity ID,Metadata\n"
        
        let formatter = ISO8601DateFormatter()
        
        for entry in filteredEntries {
            let id = entry.id.uuidString
            let timestamp = formatter.string(from: entry.timestamp)
            let actorRole = entry.actorRole.displayName
            let actorID = entry.actorID.uuidString
            let action = entry.action.replacingOccurrences(of: "\"", with: "\"\"")
            let entityType = entry.entityType.replacingOccurrences(of: "\"", with: "\"\"")
            let entityID = entry.entityID.uuidString
            
            let metaString = entry.metadata.map { "\($0.key): \($0.value)" }.joined(separator: "; ")
            let escapedMeta = metaString.replacingOccurrences(of: "\"", with: "\"\"")
            
            let row = "\(id),\(timestamp),\(actorRole),\(actorID),\"\(action)\",\"\(entityType)\",\(entityID),\"\(escapedMeta)\"\n"
            csvString.append(row)
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("AuditLogs_\(Date().timeIntervalSince1970).csv")
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }
}

struct AuditListView: View {
    @State private var viewModel = AuditViewModel()
    @Environment(\.appEnvironment) private var env
    
    @State private var searchText = ""
    
    // Filter State
    @State private var selectedEntityType: String = "All Types"
    @State private var selectedActorRole: String = "All Roles"
    @State private var selectedActionType: String = "All Activities"
    @State private var selectedDateRange: String = "Today"
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    
    @State private var exportURL: URL?
    @State private var showExportSheet = false
    @State private var showFilterSheet = false
    
    // Filter Options
    private let entityTypes = ["All Types", "Application", "User", "Loan", "EMI", "Document", "Configuration"]
    private let roles = ["All Roles", "Admin", "Manager", "Loan Officer", "Borrower"]
    private let actionTypes = ["All Activities", "Application Submitted", "Application Assigned", "Document Uploaded", "Document Verified", "EMI Paid", "Loan Approved", "Loan Rejected", "User Created", "User Updated", "Configuration Updated"]
    private let dateRanges = ["Today", "Last 7 Days", "Last 30 Days", "Custom Date Range"]
    
    private var filteredEntries: [AuditEntry] {
        viewModel.entries.filter { entry in
            var matches = true
            
            // Actor Role
            if selectedActorRole != "All Roles" && entry.actorRole.displayName != selectedActorRole {
                matches = false
            }
            
            // Entity Type (matching substring since DB might use 'LoanApplication', 'User', etc.)
            if selectedEntityType != "All Types" && !entry.entityType.localizedCaseInsensitiveContains(selectedEntityType.replacingOccurrences(of: " ", with: "")) {
                matches = false
            }
            
            // Action Type
            if selectedActionType != "All Activities" && entry.action != selectedActionType {
                matches = false
            }
            
            // Date Filter
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            switch selectedDateRange {
            case "Today":
                if !calendar.isDateInToday(entry.timestamp) { matches = false }
            case "Last 7 Days":
                if let days = calendar.dateComponents([.day], from: entry.timestamp, to: startOfDay).day, days > 7 { matches = false }
            case "Last 30 Days":
                if let days = calendar.dateComponents([.day], from: entry.timestamp, to: startOfDay).day, days > 30 { matches = false }
            case "Custom Date Range":
                if entry.timestamp < customStartDate || entry.timestamp > customEndDate { matches = false }
            default: break
            }
            
            // Advanced Search
            if !searchText.isEmpty {
                let search = searchText.lowercased()
                let actorMatch = entry.actorID.uuidString.lowercased().contains(search)
                let entityMatch = entry.entityID.uuidString.lowercased().contains(search)
                let actionMatch = entry.action.lowercased().contains(search)
                let metaMatch = entry.metadata.values.contains { $0.lowercased().contains(search) }
                
                if !actorMatch && !entityMatch && !actionMatch && !metaMatch {
                    matches = false
                }
            }
            
            return matches
        }
    }
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView().progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let error = viewModel.error {
                ContentUnavailableView("Failed to Load Logs", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if filteredEntries.isEmpty {
                if viewModel.entries.isEmpty {
                    ContentUnavailableView("No Activity Yet", systemImage: "clock", description: Text("No audit records are available."))
                } else {
                    ContentUnavailableView("No Logs Found", systemImage: "doc.text.magnifyingglass", description: Text("No audit logs match your search criteria."))
                }
            } else {
                ForEach(filteredEntries, id: \.id) { entry in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(entry.action)
                                .font(.adminCardTitle)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.adminCaption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("\(entry.actorRole.displayName) • \(entry.entityType)")
                            .font(.adminSecondary)
                            .foregroundStyle(.secondary)
                            
                        if let details = entry.metadata.first {
                            Text("\(details.key.capitalized): \(details.value)")
                                .font(.adminCaption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
        }
        .navigationTitle("Audit Activity")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Audit Activity"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        if let url = viewModel.generateCSV(from: filteredEntries) {
                            exportURL = url
                            showExportSheet = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle((selectedRoleIsActive || selectedEntityIsActive || selectedActionIsActive || selectedDateIsActive) ? Color.lmsInfo : .primary)
                    }
                }
            }
        }
        .task {
            viewModel.configure(environment: env)
            await viewModel.loadLogs()
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            NavigationStack {
                Form {
                    Section("Entity Type") {
                        Picker("Entity", selection: $selectedEntityType) {
                            ForEach(entityTypes, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Section("Actor Role") {
                        Picker("Role", selection: $selectedActorRole) {
                            ForEach(roles, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Section("Action Type") {
                        Picker("Action", selection: $selectedActionType) {
                            ForEach(actionTypes, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Section("Date Range") {
                        Picker("Range", selection: $selectedDateRange) {
                            ForEach(dateRanges, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        
                        if selectedDateRange == "Custom Date Range" {
                            DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                            DatePicker("End Date", selection: $customEndDate, displayedComponents: .date)
                        }
                    }
                }
                .navigationTitle("Filter Logs")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Reset") {
                            selectedEntityType = "All Types"
                            selectedActorRole = "All Roles"
                            selectedActionType = "All Activities"
                            selectedDateRange = "Today"
                            customStartDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                            customEndDate = Date()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Apply") {
                            showFilterSheet = false
                        }
                        .fontWeight(.bold)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    private var selectedRoleIsActive: Bool { selectedActorRole != "All Roles" }
    private var selectedEntityIsActive: Bool { selectedEntityType != "All Types" }
    private var selectedActionIsActive: Bool { selectedActionType != "All Activities" }
    private var selectedDateIsActive: Bool { selectedDateRange != "Today" }
}

#Preview {
    NavigationStack {
        AuditListView()
    }
}
