import SwiftUI

// Wraps a manager tab root in a NavigationStack that resolves every
// ManagerRoute, mirroring OfficerNavigationStack so screens stay free of
// navigationDestination boilerplate.
struct ManagerNavigationStack<Root: View>: View {
    @ViewBuilder var root: () -> Root

    var body: some View {
        NavigationStack {
            root()
                .navigationDestination(for: ManagerRoute.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func destination(for route: ManagerRoute) -> some View {
        switch route {
        case .applications:
            ManagerApplicationsView()
        case .applicationsFiltered(let filter):
            ManagerApplicationsView(initialFilter: filter)
        case .review(let id):
            ApplicationReviewView(applicationID: id)
        case .notifications:
            ManagerNotificationsView()
        case .officerPerformance:
            OfficerPerformanceView()
        case .officerDetail(let name):
            OfficerDetailView(officerName: name)
        case .auditLogs:
            AuditLogsView()
        case .loanPolicies:
            LoanPoliciesView()
        case .riskAlerts:
            RiskAlertsView()
        case .profile:
            ManagerProfileView()
        }
    }
}

// Manager notification feed. Reuses the shared OfficerNotification model and
// its tone/icon mapping, driven by ManagerStore.
struct ManagerNotificationsView: View {
    @Environment(ManagerStore.self) private var store

    var body: some View {
        List {
            if store.unreadNotificationCount > 0 {
                Section {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "bell.badge.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.lmsAccent)
                            .frame(width: 40, height: 40)
                            .background(Color.lmsAccent.opacity(0.12),
                                        in: RoundedRectangle(cornerRadius: CornerRadius.small))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(store.unreadNotificationCount) unread").font(.headline)
                            Text("Swipe to read or dismiss").font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Read all") { store.markAllNotificationsRead() }
                            .font(.subheadline.weight(.semibold))
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.lmsAccent)
                    }
                }
            }

            Section("All Notifications") {
                ForEach(store.notifications) { notification in
                    row(notification)
                        .swipeActions(edge: .leading) {
                            Button { store.markNotificationRead(notification) } label: {
                                Label("Read", systemImage: "envelope.open")
                            }
                            .tint(.lmsInfo)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.dismissNotification(notification)
                            } label: {
                                Label("Dismiss", systemImage: "xmark.circle")
                            }
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ notification: OfficerNotification) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: notification.type.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(notification.type.tint)
                .frame(width: 40, height: 40)
                .background(notification.type.tint.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: CornerRadius.small))
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    if !notification.isRead {
                        Circle().fill(Color.lmsAccent).frame(width: 8, height: 8)
                    }
                }
                Text(notification.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack {
                    Text(OfficerFormat.timeAgo(notification.timestamp))
                        .font(.caption2).foregroundStyle(.tertiary)
                    Spacer()
                    if notification.priority == 1 {
                        StatusBadge("Urgent", tone: .danger,
                                    icon: "exclamationmark.triangle.fill", size: .small)
                    }
                }
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture { store.markNotificationRead(notification) }
    }
}
