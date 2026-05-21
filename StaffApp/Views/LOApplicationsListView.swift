import SwiftUI

struct LOApplicationsListView: View {
    @State private var applications: [LoanApplication] = []
    @State private var searchText = ""
    @State private var selectedFilter: FilterTab = .active
    @State private var isLoading = true

    enum FilterTab: String, CaseIterable {
        case active = "Active"
        case incomplete = "Incomplete"
        case processed = "Processed"
    }

    private var filtered: [LoanApplication] {
        let byStatus: [LoanApplication]
        switch selectedFilter {
        case .active:
            byStatus = applications.filter { $0.status == .submitted || $0.status == .underReview }
        case .incomplete:
            byStatus = applications.filter { $0.status == .additionalInfoRequired }
        case .processed:
            byStatus = applications.filter { $0.status == .recommended || $0.status == .approved || $0.status == .rejected || $0.status == .disbursed || $0.status == .closed }
        }

        if searchText.isEmpty { return byStatus }
        let q = searchText.lowercased()
        return byStatus.filter { app in
            let name = MockData.borrowerUser(for: app.borrowerID)?.fullName.lowercased() ?? ""
            return name.contains(q) || app.id.uuidString.lowercased().contains(q) || app.loanType.rawValue.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented filter
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(FilterTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(Spacing.m)

                if isLoading {
                    Spacer()
                    ProgressView("Loading applications…")
                    Spacer()
                } else if filtered.isEmpty {
                    EmptyStateView(
                        icon: selectedFilter == .processed ? "checkmark.seal.fill" : "tray",
                        title: selectedFilter == .processed ? "All Caught Up!" : "Nothing here yet",
                        message: selectedFilter == .processed
                            ? "No processed applications at the moment."
                            : "No applications matching the current filter."
                    )
                } else {
                    List(filtered) { app in
                        NavigationLink {
                            LOApplicationDetailView(application: app)
                        } label: {
                            ApplicationRow(application: app)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: Spacing.m, bottom: 4, trailing: Spacing.m))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Applications")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .searchable(text: $searchText, prompt: "Search borrower, ID or type")
            .task {
                await load()
            }
            .refreshable { await load() }
        }
    }

    private func load() async {
        isLoading = true
        if let apps = try? await MockData.sharedLoanService.fetchAssignedApplications(officerID: MockData.loanOfficerUser.id) {
            applications = apps
        }
        isLoading = false
    }
}

struct ApplicationRow: View {
    let application: LoanApplication

    private var borrowerName: String {
        MockData.borrowerUser(for: application.borrowerID)?.fullName ?? "—"
    }

    private var creditScore: Int? {
        MockData.borrowerProfile(for: application.borrowerID)?.creditScore
    }

    private var isFraudFlagged: Bool { MockData.fraudFlagged(application) }

    private var statusTone: StatusBadge.Tone {
        switch application.status {
        case .submitted: return .info
        case .underReview: return .warning
        case .additionalInfoRequired: return .danger
        case .recommended, .approved: return .success
        case .rejected: return .danger
        default: return .neutral
        }
    }

    var body: some View {
        HStack(spacing: Spacing.m) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(Color.lmsNavyBlue.opacity(0.12))
                    .frame(width: 46, height: 46)
                Text(borrowerName.prefix(1))
                    .font(.lmsTitle2)
                    .foregroundStyle(Color.lmsNavyBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(borrowerName).font(.lmsHeadline)
                    if isFraudFlagged {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundStyle(Color.lmsDanger)
                            .font(.caption)
                    }
                }
                Text("\(application.loanType.rawValue.capitalized) · \(Formatting.currency(application.requestedAmount))")
                    .font(.lmsCaption)
                    .foregroundStyle(.secondary)
                if let score = creditScore {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption2)
                        Text("CIBIL: \(score)")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(score >= 700 ? Color.lmsSuccess : score >= 600 ? Color.lmsWarning : Color.lmsDanger)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                StatusBadge(application.status.displayName, tone: statusTone)
                Text(Formatting.date(application.updatedAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(Spacing.m)
        .background(.background, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    LOApplicationsListView()
}
