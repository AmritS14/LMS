import SwiftUI

// MARK: - Tab 1 Root: Applications

// Unified manager daily workflow screen. Replaces the old Dashboard with a
// single scrollable view combining the priority queue, review CTA, recent
// decisions, and quick insights. Title: "Applications", Subtitle: "Branch Overview".
struct ManagerApplicationsTabView: View {
    @Environment(ManagerStore.self) private var store
    @State private var showRecentDecisions = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.l) {
                subtitleRow
                priorityActionsSection

                NavigationLink(value: ManagerRoute.applications) {
                    Text("Review Applications")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: CornerRadius.button))
                .controlSize(.large)
                .padding(.horizontal, Spacing.m)

                recentDecisionsSection
                smartInsightBanner
            }
            .padding(.vertical, Spacing.m)
        }
        .background(Color.lmsBackground)
        .navigationTitle("Applications")
        .toolbarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: ManagerRoute.notifications) {
                    Image(systemName: "bell")
                        .font(.title3)
                }
                .badge(store.unreadNotificationCount)
                .accessibilityLabel("Notifications")
            }
        }
        .refreshable { await store.refreshAll() }
        .navigationDestination(isPresented: $showRecentDecisions) {
            ManagerRecentDecisionsView()
        }
    }

    // MARK: Subtitle

    private var subtitleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Branch Overview")
                    .font(.lmsTitle3)
                    .foregroundStyle(.primary)
                Text(store.greetingDateText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Branch: \(store.branchName)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.m)
    }

    // MARK: Priority Queue

    private var priorityActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("PRIORITY QUEUE")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.m)

            HStack(spacing: Spacing.m) {
                priorityCard(icon: "clock.badge.exclamationmark",
                             count: store.pendingReviewCount,
                             title: "Pending Review", subtitle: "Needs attention",
                             accent: .lmsAccent, filter: .pending)
                priorityCard(icon: "exclamationmark.triangle",
                             count: store.escalatedCount,
                             title: "Escalated", subtitle: "Critical review",
                             accent: .lmsDanger, filter: .escalated)
                priorityCard(icon: "arrow.uturn.backward.circle",
                             count: store.sentBackCount,
                             title: "Sent Back", subtitle: "Awaiting correction",
                             accent: .lmsWarning, filter: .sentBack)
            }
            .padding(.horizontal, Spacing.m)
        }
    }

    private func priorityCard(icon: String, count: Int, title: String,
                               subtitle: String, accent: Color,
                               filter: ManagerApplicationsView.Filter) -> some View {
        NavigationLink(value: ManagerRoute.applicationsFiltered(filter)) {
            VStack(alignment: .leading, spacing: 0) {
                accent
                    .frame(height: 6)
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack {
                        Spacer()
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(accent)
                            .padding(.top, Spacing.xs)
                    }

                    Text("\(count)")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.subheadline).foregroundStyle(.primary)
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .padding(Spacing.m)
            }
            .background(Color.lmsSurface)
            .clipShape(.rect(cornerRadius: CornerRadius.medium))
            .frame(height: 170)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: Recent Decisions

    private var recentDecisionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Recent Decisions",
                          actionTitle: "See All") {
                showRecentDecisions = true
            }
            .padding(.horizontal, Spacing.m)

            VStack(spacing: 0) {
                ForEach(store.recentActions.prefix(5)) { action in
                    recentActionRow(action)
                    if action.id != store.recentActions.prefix(5).last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .padding(.vertical, Spacing.xs)
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .padding(.horizontal, Spacing.m)
        }
    }

    private func recentActionRow(_ action: ManagerRecentAction) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: action.kind.rowIcon)
                .font(.title3)
                .foregroundStyle(action.kind.themeColor)
                .frame(width: 36, height: 36)
                .background(action.kind.themeColor.opacity(0.12),
                             in: RoundedRectangle(cornerRadius: CornerRadius.small))

            VStack(alignment: .leading, spacing: 2) {
                Text(action.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
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
        .padding(.vertical, Spacing.s)
    }

    // MARK: Smart Insight Banner

    private var smartInsightBanner: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundStyle(Color.lmsWarning)
                .frame(width: 40, height: 40)
                .background(Color.lmsWarning.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Approval rate increased 2.5% this week")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Text("\(store.highRiskCount) applications need urgent review")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(Spacing.m)
        .background(Color.lmsWarning.opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .padding(.horizontal, Spacing.m)
    }
}

#Preview {
    ManagerNavigationStack {
        ManagerApplicationsTabView()
    }
    .environment(ManagerStore.preview)
    .environment(SessionStore())
}
