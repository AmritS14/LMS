import SwiftUI

struct ManagerApplicationsView: View {
    @Environment(ManagerStore.self) private var store
    @State private var searchText = ""
    @State private var filter: Filter = .all
    @State private var loanTypeFilter: LoanType? = nil
    @State private var riskFilter: RiskLevel? = nil
    @State private var sortByAmount = false

    // Allow pre-setting the filter from navigation
    var initialFilter: Filter? = nil

    private var isFiltered: Bool {
        loanTypeFilter != nil || riskFilter != nil || sortByAmount
    }

    enum Filter: String, CaseIterable, Identifiable, Hashable {
        case all = "All"
        case pending = "Pending"
        case escalated = "Escalated"
        case approved = "Approved"
        case rejected = "Rejected"
        case sentBack = "Sent Back"

        var id: String { rawValue }

        func matches(_ app: ManagerApplication) -> Bool {
            switch self {
            case .all: true
            case .pending:
                app.status == .submitted || app.status == .underReview || app.status == .recommended
            case .escalated:
                app.status == .escalated
            case .approved:
                app.status == .approved || app.status == .disbursed
            case .rejected:
                app.status == .rejected
            case .sentBack:
                app.status == .additionalInfoRequired
            }
        }
    }

    private var filteredApps: [ManagerApplication] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var apps = store.applications.filter { app in
            guard filter.matches(app) else { return false }
            if let lt = loanTypeFilter, app.loanType != lt { return false }
            if let rl = riskFilter, app.riskLevel != rl { return false }
            guard !query.isEmpty else { return true }
            return app.borrowerName.localizedCaseInsensitiveContains(query)
                || app.subtitle.localizedCaseInsensitiveContains(query)
                || app.officerName.localizedCaseInsensitiveContains(query)
        }
        if sortByAmount {
            apps.sort { $0.base.loanAmount > $1.base.loanAmount }
        }
        return apps
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Spacing.m) {
                if filteredApps.isEmpty {
                    ContentUnavailableView("No applications found",
                                           systemImage: "doc.text.magnifyingglass",
                                           description: Text("Try a different search or filter."))
                        .padding(.top, Spacing.xxl)
                } else {
                    ForEach(filteredApps) { app in
                        applicationCard(app)
                    }
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.lmsBackground)
        .navigationTitle("Applications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Loan Type
                    Section("Loan Type") {
                        Button {
                            loanTypeFilter = nil
                        } label: {
                            Label("All Types", systemImage: loanTypeFilter == nil ? "checkmark" : "line.horizontal.3.decrease")
                        }
                        ForEach(LoanType.allCases, id: \.self) { type in
                            Button {
                                loanTypeFilter = loanTypeFilter == type ? nil : type
                            } label: {
                                Label(type.rawValue.capitalized,
                                      systemImage: loanTypeFilter == type ? "checkmark" : "creditcard")
                            }
                        }
                    }

                    // Risk Level
                    Section("Risk Level") {
                        Button {
                            riskFilter = nil
                        } label: {
                            Label("All Risks", systemImage: riskFilter == nil ? "checkmark" : "line.horizontal.3.decrease")
                        }
                        ForEach(RiskLevel.allCases, id: \.self) { risk in
                            Button {
                                riskFilter = riskFilter == risk ? nil : risk
                            } label: {
                                Label(risk.rawValue.capitalized,
                                      systemImage: riskFilter == risk ? "checkmark" : "shield")
                            }
                        }
                    }

                    // Sort
                    Section("Sort") {
                        Toggle(isOn: $sortByAmount) {
                            Label("Highest Amount First", systemImage: "indianrupeesign.arrow.trianglehead.counterclockwise.rotate.90")
                        }
                    }

                    // Clear all
                    if isFiltered {
                        Divider()
                        Button(role: .destructive) {
                            loanTypeFilter = nil
                            riskFilter = nil
                            sortByAmount = false
                        } label: {
                            Label("Clear Filters", systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isFiltered ? Color.lmsAccent : .primary)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search applicant, ref, or officer")
        .searchScopes($filter, activation: .automatic) {
            ForEach(Filter.allCases) { scope in
                Text(scope.rawValue).tag(scope)
            }
        }
        .refreshable { await store.refreshAll() }
        .onAppear {
            if let initialFilter, filter == .all {
                filter = initialFilter
            }
        }
    }

    // MARK: Application card

    private func applicationCard(_ app: ManagerApplication) -> some View {
        NavigationLink(value: ManagerRoute.review(app.id)) {
            VStack(spacing: Spacing.m) {
                HStack(alignment: .top, spacing: Spacing.m) {
                    AvatarView(initials: app.borrowerInitials, size: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.borrowerName)
                            .font(.lmsTitle3)
                            .foregroundStyle(.primary)
                        Text(app.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    StatusBadge(app.riskLevel.rawValue, tone: app.riskLevel.tone, icon: app.riskLevel.icon, size: .small)
                }

                Divider()

                HStack {
                    labeled("Amount", app.amountText)
                    Spacer()
                    labeled("Officer", app.officerName)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Status").font(.caption).foregroundStyle(.secondary)
                        StatusBadge(app.status.displayLabel, tone: app.status.tone, size: .small)
                    }
                }
            }
            .padding(Spacing.m)
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .contextMenu {
            if app.status != .approved && app.status != .rejected && app.status != .disbursed {
                Button {
                    Task {
                        try? await store.decide(.approve, on: app, remarks: "Quick approved from list.")
                    }
                } label: {
                    Label("Quick Approve", systemImage: "checkmark.seal.fill")
                }

                Button(role: .destructive) {
                    Task {
                        try? await store.decide(.reject, on: app, remarks: "Quick rejected from list.")
                    }
                } label: {
                    Label("Quick Reject", systemImage: "xmark.octagon.fill")
                }

                Divider()
            }

            NavigationLink(value: ManagerRoute.review(app.id)) {
                Label("View Details", systemImage: "doc.text.magnifyingglass")
            }
        }
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(.primary)
        }
    }
}

#Preview {
    NavigationStack {
        ManagerApplicationsView()
            .environment(ManagerStore.preview)
    }
}
