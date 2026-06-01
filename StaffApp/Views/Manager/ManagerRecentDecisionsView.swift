import SwiftUI

struct ManagerRecentDecisionsView: View {
    @Environment(ManagerStore.self) private var store
    @State private var searchText = ""
    @State private var selectedFilter: Filter = .all

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case approved = "Approved"
        case rejected = "Rejected"
        case returned = "Returned"

        var id: String { rawValue }

        func matches(_ action: ManagerRecentAction) -> Bool {
            switch self {
            case .all: true
            case .approved: action.kind == .approve
            case .rejected: action.kind == .reject
            case .returned: action.kind == .sendBack
            }
        }
    }

    private var filteredActions: [ManagerRecentAction] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.recentActions.filter { action in
            guard selectedFilter.matches(action) else { return false }
            guard !query.isEmpty else { return true }
            return action.name.localizedCaseInsensitiveContains(query)
                || action.amount.localizedCaseInsensitiveContains(query)
                || action.kind.verb.localizedCaseInsensitiveContains(query)
        }
    }

    // Helper metrics
    private var totalCount: Int { store.recentActions.count }
    private var approvedCount: Int { store.recentActions.filter { $0.kind == .approve }.count }
    private var rejectedCount: Int { store.recentActions.filter { $0.kind == .reject }.count }
    private var returnedCount: Int { store.recentActions.filter { $0.kind == .sendBack }.count }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.l) {
                // Metric Summary Cards
                metricSummarySection

                // Filter Chips
                filterChipsSection

                // Main List of Decisions
                VStack(spacing: 0) {
                    if filteredActions.isEmpty {
                        ContentUnavailableView(
                            "No decisions found",
                            systemImage: "checklist.checked.inverse",
                            description: Text("Try adjusting your search or filters.")
                        )
                        .padding(.vertical, Spacing.xxl)
                    } else {
                        ForEach(filteredActions) { action in
                            decisionRow(action)
                            
                            if action.id != filteredActions.last?.id {
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                }
                .padding(.vertical, Spacing.xs)
                .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                .padding(.horizontal, Spacing.m)
            }
            .padding(.vertical, Spacing.m)
        }
        .background(Color.lmsBackground)
        .navigationTitle("Recent Decisions")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search applicant or amount")
    }

    // MARK: - Metric Summary Section

    private var metricSummarySection: some View {
        HStack(spacing: Spacing.s) {
            summaryCard(
                title: "Approved",
                count: approvedCount,
                color: .lmsSuccess,
                gradient: [Color.lmsSuccess.opacity(0.15), Color.lmsSuccess.opacity(0.02)]
            )
            summaryCard(
                title: "Rejected",
                count: rejectedCount,
                color: .lmsDanger,
                gradient: [Color.lmsDanger.opacity(0.15), Color.lmsDanger.opacity(0.02)]
            )
            summaryCard(
                title: "Returned",
                count: returnedCount,
                color: .lmsWarning,
                gradient: [Color.lmsWarning.opacity(0.15), Color.lmsWarning.opacity(0.02)]
            )
        }
        .padding(.horizontal, Spacing.m)
    }

    private func summaryCard(title: String, count: Int, color: Color, gradient: [Color]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("\(count)")
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(color)
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                        .strokeBorder(color.opacity(0.12), lineWidth: 1)
                )
        }
    }

    // MARK: - Filter Chips

    private var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                ForEach(Filter.allCases) { filter in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, Spacing.m)
                            .padding(.vertical, Spacing.xs - 2)
                            .background(selectedFilter == filter ? Color.lmsAccent : Color.lmsFill, in: Capsule())
                            .foregroundStyle(selectedFilter == filter ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.m)
        }
    }

    // MARK: - Decision Row

    private func decisionRow(_ action: ManagerRecentAction) -> some View {
        Group {
            if let applicationID = action.applicationID {
                NavigationLink(value: ManagerRoute.review(applicationID)) {
                    rowContent(action)
                }
                .buttonStyle(ScaleButtonStyle())
            } else {
                rowContent(action)
            }
        }
    }

    private func rowContent(_ action: ManagerRecentAction) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: action.kind.rowIcon)
                .font(.title3)
                .foregroundStyle(action.kind.themeColor)
                .frame(width: 38, height: 38)
                .background(
                    action.kind.themeColor.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: CornerRadius.small)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(action.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    if action.applicationID != nil {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Text("\(action.kind.verb) • \(action.amount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(action.timeText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s + 2)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        ManagerRecentDecisionsView()
            .environment(ManagerStore.preview)
    }
}
