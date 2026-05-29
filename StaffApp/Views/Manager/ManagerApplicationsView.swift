import SwiftUI

struct ManagerApplicationsView: View {
    @Environment(ManagerStore.self) private var store
    @State private var searchText = ""
    @State private var filter: Filter = .all

    // Allow pre-setting the filter from navigation
    var initialFilter: Filter? = nil

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
        return store.applications.filter { app in
            guard filter.matches(app) else { return false }
            guard !query.isEmpty else { return true }
            return app.borrowerName.localizedCaseInsensitiveContains(query)
                || app.subtitle.localizedCaseInsensitiveContains(query)
                || app.officerName.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            filterChips

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
        .searchable(text: $searchText, prompt: "Search applicant, ref, or officer")
        .refreshable { await store.refreshAll() }
        .onAppear {
            if let initialFilter, filter == .all {
                filter = initialFilter
            }
        }
    }

    // MARK: Filter chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                ForEach(Filter.allCases) { option in
                    Button {
                        filter = option
                    } label: {
                        Text(option.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(filter == option ? Color.lmsAccent : Color.lmsFill, in: Capsule())
                            .foregroundStyle(filter == option ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
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
                    store.decide(.approve, on: app, remarks: "Quick approved from list.")
                } label: {
                    Label("Quick Approve", systemImage: "checkmark.seal.fill")
                }

                Button(role: .destructive) {
                    store.decide(.reject, on: app, remarks: "Quick rejected from list.")
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
