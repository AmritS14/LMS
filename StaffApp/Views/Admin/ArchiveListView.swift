import SwiftUI

// MARK: - Archive Loan Model
struct ArchiveLoanItem: Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var loanIDString: String
    var borrowerName: String
    var loanType: LoanType
    var principal: Decimal
    var closedDate: Date
    var isArchived: Bool
    var status: LoanStatus
    
    var isEligible: Bool {
        status == .settled
    }
}

// MARK: - Filter Options
enum DateRangeFilter: String, CaseIterable, Identifiable {
    case all = "All Dates"
    case last30Days = "Last 30 Days"
    case lastYear = "Last Year"
    var id: String { self.rawValue }
}

enum ArchiveStatusFilter: String, CaseIterable, Identifiable {
    case all = "All Statuses"
    case archived = "Archived"
    case active = "Active (Unarchived)"
    var id: String { self.rawValue }
}

// MARK: - Archive List View
struct ArchiveListView: View {
    @State private var loans: [ArchiveLoanItem] = {
        let users = AdminSeedData.users
        let borrowerUsers = users.filter { $0.role == .borrower }
        
        return [
            ArchiveLoanItem(
                loanIDString: "LN-8472910",
                borrowerName: borrowerUsers.count > 0 ? borrowerUsers[0].fullName : "Rohan Sharma",
                loanType: .personal,
                principal: 150000,
                closedDate: Calendar.current.date(byAdding: .day, value: -12, to: Date())!,
                isArchived: false,
                status: .settled
            ),
            ArchiveLoanItem(
                loanIDString: "LN-2947104",
                borrowerName: borrowerUsers.count > 1 ? borrowerUsers[1].fullName : "Priya Patel",
                loanType: .home,
                principal: 4500000,
                closedDate: Date(),
                isArchived: false,
                status: .active
            ),
            ArchiveLoanItem(
                loanIDString: "LN-3829471",
                borrowerName: borrowerUsers.count > 2 ? borrowerUsers[2].fullName : "Amit Singh",
                loanType: .vehicle,
                principal: 800000,
                closedDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
                isArchived: true,
                status: .settled
            ),
            ArchiveLoanItem(
                loanIDString: "LN-4820194",
                borrowerName: borrowerUsers.count > 3 ? borrowerUsers[3].fullName : "Neha Gupta",
                loanType: .education,
                principal: 1200000,
                closedDate: Date(),
                isArchived: false,
                status: .defaulted
            ),
            ArchiveLoanItem(
                loanIDString: "LN-1948201",
                borrowerName: borrowerUsers.count > 0 ? borrowerUsers[0].fullName : "Vikram Malhotra",
                loanType: .business,
                principal: 2500000,
                closedDate: Calendar.current.date(byAdding: .day, value: -45, to: Date())!,
                isArchived: false,
                status: .settled
            )
        ]
    }()
    
    // Search and Filter State
    @State private var searchText = ""
    @State private var selectedDateRange: DateRangeFilter = .all
    @State private var selectedCategory: LoanType? = nil
    @State private var selectedArchiveStatus: ArchiveStatusFilter = .all
    
    // Interactive Simulation States
    @State private var isLoading = false
    @State private var hasError = false
    
    // Alerts and Dialogs State
    @State private var pendingArchiveActionItem: ArchiveLoanItem? = nil
    @State private var showArchiveConfirmAlert = false
    
    @State private var pendingRestoreActionItem: ArchiveLoanItem? = nil
    @State private var showRestoreConfirmAlert = false
    
    // HUD State
    @State private var hudMessage: String? = nil
    @State private var showHUD = false
    
    // MARK: - Computed Properties
    private var filteredLoans: [ArchiveLoanItem] {
        loans.filter { loan in
            // Search match
            if !searchText.isEmpty {
                let search = searchText.lowercased()
                let matchesSearch = loan.borrowerName.lowercased().contains(search) ||
                                    loan.loanIDString.lowercased().contains(search) ||
                                    loan.loanType.rawValue.lowercased().contains(search)
                if !matchesSearch { return false }
            }
            
            // Date range match
            if selectedDateRange != .all {
                let daysAgo = Calendar.current.dateComponents([.day], from: loan.closedDate, to: Date()).day ?? 0
                switch selectedDateRange {
                case .last30Days:
                    if daysAgo > 30 { return false }
                case .lastYear:
                    if daysAgo > 365 { return false }
                case .all:
                    break
                }
            }
            
            // Category match
            if let category = selectedCategory, loan.loanType != category {
                return false
            }
            
            // Archive Status match
            switch selectedArchiveStatus {
            case .archived:
                if !loan.isArchived { return false }
            case .active:
                if loan.isArchived { return false }
            case .all:
                break
            }
            
            return true
        }
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Simulation controls bar
                simulationControlBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                
                // Search bar
                SearchBarView(text: $searchText, placeholder: "Search Borrower, ID or Type...")
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                
                // Filter chips panel
                filterChipsPanel
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                
                Divider()
                
                if isLoading {
                    skeletonLoadingView
                } else if hasError {
                    errorStateView
                } else if filteredLoans.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredLoans) { loan in
                            archiveCardRow(loan: loan)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if loan.isArchived {
                                        Button {
                                            pendingRestoreActionItem = loan
                                            showRestoreConfirmAlert = true
                                        } label: {
                                            Label("Restore", systemImage: "arrow.uturn.backward.circle.fill")
                                        }
                                        .tint(.green)
                                    } else {
                                        Button {
                                            if loan.isEligible {
                                                pendingArchiveActionItem = loan
                                                showArchiveConfirmAlert = true
                                            } else {
                                                triggerHUD("Unable to Process")
                                            }
                                        } label: {
                                            Label("Archive", systemImage: "archivebox.fill")
                                        }
                                        .tint(loan.isEligible ? .orange : .gray)
                                        .disabled(!loan.isEligible)
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            
            // HUD Banner Overlay
            if showHUD, let msg = hudMessage {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: msg == "Unable to Process" ? "xmark.octagon.fill" : "checkmark.circle.fill")
                            .foregroundStyle(msg == "Unable to Process" ? .red : .green)
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
        .navigationTitle("Loan Archives")
        .navigationBarTitleDisplayMode(.inline)
        
        // Confirmation Dialog - Archive
        .alert("Archive Loan?", isPresented: $showArchiveConfirmAlert, presenting: pendingArchiveActionItem) { item in
            Button("Cancel", role: .cancel) {
                pendingArchiveActionItem = nil
            }
            Button("Archive", role: .destructive) {
                if let idx = loans.firstIndex(where: { $0.id == item.id }) {
                    loans[idx].isArchived = true
                    triggerHUD("Archive Complete")
                }
                pendingArchiveActionItem = nil
            }
        } message: { item in
            Text("This loan will move to historical records.")
        }
        
        // Confirmation Dialog - Restore
        .alert("Restore Loan?", isPresented: $showRestoreConfirmAlert, presenting: pendingRestoreActionItem) { item in
            Button("Cancel", role: .cancel) {
                pendingRestoreActionItem = nil
            }
            Button("Restore") {
                if let idx = loans.firstIndex(where: { $0.id == item.id }) {
                    loans[idx].isArchived = false
                    triggerHUD("Restore Complete")
                }
                pendingRestoreActionItem = nil
            }
        } message: { item in
            Text("This loan will return to active records.")
        }
    }
    
    // MARK: - Card View Row
    private func archiveCardRow(loan: ArchiveLoanItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(loan.loanIDString)
                    .font(.lmsHeadline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if loan.isArchived {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        StatusBadge("Archived", tone: .warning, size: .small)
                    }
                } else {
                    StatusBadge(loan.status.rawValue.capitalized, tone: loan.status == .settled ? .success : (loan.status == .active ? .info : .danger), size: .small)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(loan.borrowerName)
                        .font(.lmsBody)
                        .foregroundStyle(.primary)
                }
                
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(loan.loanType.rawValue.capitalized) • \(Formatting.currency(loan.principal))")
                        .font(.lmsSubheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Closed: \(loan.closedDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.lmsSubheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Ineligibility validation warning & Locked read-only state UI
            if loan.isArchived {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Read-only record: Editing is locked.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            } else if !loan.isEligible {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Text("Only completed loans can be archived.")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        .opacity(loan.isArchived ? 0.8 : 1.0)
    }
    
    // MARK: - Filter Chips Panel
    private var filterChipsPanel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Date filter chip
                Menu {
                    ForEach(DateRangeFilter.allCases) { opt in
                        Button(opt.rawValue) { selectedDateRange = opt }
                    }
                } label: {
                    filterChip(title: "Date: \(selectedDateRange.rawValue)", isSelected: selectedDateRange != .all)
                }
                
                // Category filter chip
                Menu {
                    Button("All Types") { selectedCategory = nil }
                    ForEach(LoanType.allCases) { type in
                        Button(type.rawValue.capitalized) { selectedCategory = type }
                    }
                } label: {
                    filterChip(title: selectedCategory != nil ? selectedCategory!.rawValue.capitalized : "Loan Category", isSelected: selectedCategory != nil)
                }
                
                // Archive Status filter chip
                Menu {
                    ForEach(ArchiveStatusFilter.allCases) { opt in
                        Button(opt.rawValue) { selectedArchiveStatus = opt }
                    }
                } label: {
                    filterChip(title: selectedArchiveStatus.rawValue, isSelected: selectedArchiveStatus != .all)
                }
                
                // Clear Filters button
                if selectedDateRange != .all || selectedCategory != nil || selectedArchiveStatus != .all || !searchText.isEmpty {
                    Button(action: resetFilters) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Reset")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    }
                    .padding(.leading, 8)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func filterChip(title: String, isSelected: Bool) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            Image(systemName: "chevron.down")
                .font(.system(size: 8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.blue.opacity(0.12) : Color.primary.opacity(0.04), in: Capsule())
        .overlay(Capsule().stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1))
        .foregroundStyle(isSelected ? .blue : .primary)
    }
    
    // MARK: - Simulation Control Bar
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
    
    // MARK: - Simulation States Subviews
    private var skeletonLoadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<3) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 100, height: 20)
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 80, height: 20)
                    }
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 180, height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 220, height: 16)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
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
            Text("Unable to Process")
                .font(.headline)
            Text("A synchronization connection failure was detected. Please try again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Retry") {
                hasError = false
                isLoading = true
                Task {
                    try? await Task.sleep(for: .seconds(1.0))
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
            Image(systemName: "archivebox")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No Historical Records")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("There are no loans matching the selected search or criteria.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
    
    // MARK: - Actions
    private func resetFilters() {
        withAnimation {
            searchText = ""
            selectedDateRange = .all
            selectedCategory = nil
            selectedArchiveStatus = .all
        }
    }
    
    private func triggerHUD(_ message: String) {
        hudMessage = message
        withAnimation(.easeOut(duration: 0.25)) {
            showHUD = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeIn(duration: 0.25)) {
                showHUD = false
            }
        }
    }
}

// MARK: - Custom Search Bar Component
struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        ArchiveListView()
    }
}
