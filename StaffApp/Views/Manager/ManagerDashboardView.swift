import SwiftUI

struct ManagerDashboardView: View {
    @Environment(ManagerStore.self) private var store
    @State private var showProfile = false

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

                branchPerformanceSection
                smartInsightsSection
            }
            .padding(.vertical, Spacing.m)
        }
        .background(Color.lmsBackground)
        .navigationTitle("Dashboard")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: ManagerRoute.notifications) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell").font(.title3)
//                        if store.unreadNotificationCount > 0 {
//                            CountBadge(count: store.unreadNotificationCount)
//                                .offset(x: 8, y: -6)
//                        }
                    }
                }
                .badge(store.unreadNotificationCount)
                .accessibilityLabel("Notifications")
            }

        }
        .sheet(isPresented: $showProfile) { StaffProfileView() }
        .task { await store.refreshAll() }
    }

    // MARK: Subtitle

    private var subtitleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(store.greetingDateText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Branch: \(store.branchName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.m)
    }

    // MARK: Priority actions

    private var priorityActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Applications")
                .font(.lmsTitle3)
                .padding(.horizontal, Spacing.m)

            HStack(spacing: Spacing.m) {
                priorityCard(icon: "clock.badge.exclamationmark",
                             count: store.pendingReviewCount,
                             title: "Pending Review", subtitle: "Needs attention",
                             accent: .lmsAccent)
                priorityCard(icon: "arrow.uturn.backward.circle",
                             count: store.sentBackCount,
                             title: "Sent Back", subtitle: "Awaiting correction",
                             accent: .lmsWarning)
                priorityCard(icon: "exclamationmark.triangle",
                             count: store.escalatedCount,
                             title: "Escalated", subtitle: "Critical review",
                             accent: .lmsDanger)
            }
            .padding(.horizontal, Spacing.m)
        }
    }

    private func priorityCard(icon: String, count: Int, title: String,
                              subtitle: String, accent: Color) -> some View {
        NavigationLink(value: ManagerRoute.applications) {
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
//                    .frame(minHeight: 30)
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

    // MARK: Branch performance

    private var branchPerformanceSection: some View {
        SectionCard(title: "Branch Performance") {
            HStack(spacing: Spacing.l) {
                VStack(spacing: Spacing.s) {
                    CircularProgress(progress: store.approvalRate, color: .lmsAccent, lineWidth: 7, size: 76)
                    Text("Approval Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Avg Decision Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(store.avgDecisionTime)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down").font(.caption2.weight(.bold))
                        Text("14% faster").font(.caption2)
                    }
                    .foregroundStyle(Color.lmsSuccess)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.m)
                .background(Color.lmsBackground, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
        }
        .padding(.horizontal, Spacing.m)
    }

    // MARK: Smart insight

    private var smartInsightsSection: some View {
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
        ManagerDashboardView()
    }
    .environment(ManagerStore.preview)
    .environment(SessionStore())
}
