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

@MainActor
@Observable
final class ArchiveViewModel {
    var loans: [ArchiveLoanItem] = []
    var isLoading = false
    var error: String? = nil
    private var environment: AppEnvironment?

    func configure(environment: AppEnvironment?) {
        self.environment = environment
    }

    func load() async {
        guard let env = environment else {
            // Previews
            self.loans = []
            return
        }
        isLoading = true
        error = nil
        do {
            struct DBLoan: Decodable {
                let id: UUID
                let borrower_id: UUID
                let loan_product_id: UUID
                let principal: Decimal
                let status: String
                let updated_at: Date
                
                struct NestedUser: Decodable { let full_name: String }
                let users: NestedUser?
                
                struct NestedProduct: Decodable { let name: String }
                let loan_products: NestedProduct?
            }
            
            // We fetch loans that are either settled or archived
            let response = try await SupabaseManager.shared.client
                .from("loans")
                .select("id, borrower_id, loan_product_id, principal, status, updated_at, users:users!loans_borrower_id_fkey(full_name), loan_products(name)")
                .or("status.eq.settled,status.eq.archived")
                .execute()
                
            let dbLoans = try SupabaseManager.shared.decoder.decode([DBLoan].self, from: response.data)
            self.loans = dbLoans.map { db in
                ArchiveLoanItem(
                    id: db.id,
                    loanIDString: String(db.id.uuidString.prefix(8)).uppercased(),
                    borrowerName: db.users?.full_name ?? "Unknown",
                    loanType: .personal, // Simplification for UI
                    principal: db.principal,
                    closedDate: db.updated_at,
                    isArchived: db.status.lowercased() == "archived",
                    status: db.status.lowercased() == "archived" ? .settled : .settled
                )
            }
        } catch {
            self.error = error.localizedDescription
            print("Failed to fetch archive loans: \(error)")
        }
        isLoading = false
    }

    func archiveLoan(_ id: UUID) async throws {
        guard let env = environment else { return }
        try await env.admin.archiveLoan(id: id)
        if let idx = loans.firstIndex(where: { $0.id == id }) {
            loans[idx].isArchived = true
        }
    }

    func restoreLoan(_ id: UUID) async throws {
        guard let env = environment else { return }
        try await env.admin.restoreLoan(id: id)
        if let idx = loans.firstIndex(where: { $0.id == id }) {
            loans[idx].isArchived = false
        }
    }
    
    func generateCSV(from filteredLoans: [ArchiveLoanItem]) -> URL? {
        var csvString = "Loan ID,Borrower Name,Principal,Closed Date,Archived\n"
        let formatter = ISO8601DateFormatter()
        for loan in filteredLoans {
            let id = loan.loanIDString
            let name = loan.borrowerName.replacingOccurrences(of: "\"", with: "\"\"")
            let principal = "\(loan.principal)"
            let date = formatter.string(from: loan.closedDate)
            let archived = loan.isArchived ? "Yes" : "No"
            csvString.append("\(id),\"\(name)\",\(principal),\(date),\(archived)\n")
        }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("LoanArchives_\(Date().timeIntervalSince1970).csv")
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }
}

// MARK: - Archive List View
struct ArchiveListView: View {
    @State private var viewModel = ArchiveViewModel()
    @Environment(\.appEnvironment) private var env
    
    @State private var exportURL: URL?
    @State private var showExportSheet = false
    
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
    
    @State private var showSimErrorAlert = false
    @State private var errorText = ""
    
    // MARK: - Computed Properties
    private var filteredLoans: [ArchiveLoanItem] {
        viewModel.loans.filter { loan in
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
        Group {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading Archives...")
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hasError {
                ContentUnavailableView("Data Error", systemImage: "exclamationmark.triangle", description: Text("Failed to load loan archives."))
            } else if filteredLoans.isEmpty {
                ContentUnavailableView("No Archives", systemImage: "archivebox", description: Text("No records match your filters."))
            } else {
                List {
                    ForEach(filteredLoans) { loan in
                        archiveRow(for: loan)
                    }
                }
            }
        }
        .navigationTitle("Loan Archives")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Borrower, ID or Type..."
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section("Date Range") {
                        ForEach(DateRangeFilter.allCases) { opt in
                            Button { selectedDateRange = opt } label: {
                                HStack {
                                    Text(opt.rawValue)
                                    if selectedDateRange == opt { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                    Section("Loan Category") {
                        Button { selectedCategory = nil } label: {
                            HStack {
                                Text("All Types")
                                if selectedCategory == nil { Image(systemName: "checkmark") }
                            }
                        }
                        ForEach(LoanType.allCases) { type in
                            Button { selectedCategory = type } label: {
                                HStack {
                                    Text(type.rawValue.capitalized)
                                    if selectedCategory == type { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                    Section("Archive Status") {
                        ForEach(ArchiveStatusFilter.allCases) { opt in
                            Button { selectedArchiveStatus = opt } label: {
                                HStack {
                                    Text(opt.rawValue)
                                    if selectedArchiveStatus == opt { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                    
                    if selectedDateRange != .all || selectedCategory != nil || selectedArchiveStatus != .all || !searchText.isEmpty {
                        Divider()
                        Button(role: .destructive) {
                            searchText = ""
                            selectedDateRange = .all
                            selectedCategory = nil
                            selectedArchiveStatus = .all
                        } label: {
                            Label("Clear Filters", systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundStyle((selectedDateRange != .all || selectedCategory != nil || selectedArchiveStatus != .all) ? Color.blue : Color.primary)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let url = viewModel.generateCSV(from: filteredLoans) {
                        exportURL = url
                        showExportSheet = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        // Confirmation Dialog - Archive
        .alert("Archive Loan?", isPresented: $showArchiveConfirmAlert, presenting: pendingArchiveActionItem) { item in
            Button("Cancel", role: .cancel) {
                pendingArchiveActionItem = nil
            }
            Button("Archive", role: .destructive) {
                if let item = pendingArchiveActionItem {
                    Task {
                        try? await viewModel.archiveLoan(item.id)
                    }
                }
            }
        } message: { item in
            Text("Are you sure you want to archive \(item.loanIDString)? This will lock the record as read-only.")
        }
        // Confirmation Dialog - Restore
        .alert("Restore Loan?", isPresented: $showRestoreConfirmAlert, presenting: pendingRestoreActionItem) { item in
            Button("Cancel", role: .cancel) {
                pendingRestoreActionItem = nil
            }
            Button("Restore", role: .cancel) { // Note: using cancel or standard role since it's a positive action
                if let item = pendingRestoreActionItem {
                    Task {
                        try? await viewModel.restoreLoan(item.id)
                    }
                }
            }
        } message: { item in
            Text("Restore \(item.loanIDString) to active records?")
        }
        .alert("Notice", isPresented: $showSimErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorText)
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    @ViewBuilder
    private func archiveRow(for loan: ArchiveLoanItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(loan.loanIDString)
                    .font(.adminCardTitle)
                    .foregroundStyle(.primary)
                Spacer()
                if loan.isArchived {
                    Label("Archived", systemImage: "lock.fill")
                        .font(.adminCaption)
                        .foregroundStyle(.orange)
                } else {
                    Text(loan.status.rawValue.capitalized)
                        .font(.adminCaption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(loan.status == .settled ? Color.lmsSuccess.opacity(0.12) : Color.lmsInfo.opacity(0.12), in: Capsule())
                        .foregroundStyle(loan.status == .settled ? Color.lmsSuccess : Color.lmsInfo)
                }
            }
            
            Text(loan.borrowerName)
                .font(.adminSecondary)
                .foregroundStyle(.primary)
            
            Text("\(loan.loanType.rawValue.capitalized) • \(Formatting.currency(loan.principal))")
                .font(.adminCaption)
                .foregroundStyle(.secondary)
            
            Text("Closed: \(loan.closedDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.adminCaption)
                .foregroundStyle(.secondary)
                
            if !loan.isArchived && !loan.isEligible {
                Text("Only completed loans can be archived.")
                    .font(.adminCaption)
                    .foregroundStyle(Color.lmsWarning)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, Spacing.xs)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if loan.isArchived {
                Button {
                    Task {
                        do {
                            try await viewModel.restoreLoan(loan.id)
                        } catch {
                            print("Restore error: \(error)")
                        }
                    }
                } label: {
                    Label("Restore", systemImage: "arrow.uturn.backward.circle.fill")
                }
                .tint(.green)
            } else {
                Button {
                    if loan.isEligible {
                        Task {
                            do {
                                try await viewModel.archiveLoan(loan.id)
                            } catch {
                                print("Archive error: \(error)")
                            }
                        }
                    } else {
                        errorText = "Unable to process. Only settled loans can be archived."
                        showSimErrorAlert = true
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

#Preview {
    NavigationStack {
        ArchiveListView()
    }
}
