import SwiftUI

struct LONotificationsView: View {
    @State private var notifications: [PushNotification] = []
    @State private var isLoading = true
    @State private var readIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            notificationsContent
                .navigationTitle("Notifications")
                .navigationBarItems(
                    trailing: Button("Mark All Read") {
                        withAnimation { readIDs = Set(notifications.map(\.id)) }
                    }
                    .font(.lmsCaption)
                    .opacity(notifications.isEmpty ? 0 : 1)
                )
                .task {
                    if let items = try? await MockData.sharedNotificationService.fetchHistory(limit: 20) {
                        notifications = items
                    }
                    isLoading = false
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    @ViewBuilder
    private var notificationsContent: some View {
        if isLoading {
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if notifications.isEmpty {
            EmptyStateView(icon: "bell.slash", title: "No Notifications", message: "You are all caught up.")
        } else {
            List(notifications) { notif in
                NotificationRow(
                    notification: notif,
                    isUnread: !readIDs.contains(notif.id)
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color(uiColor: .clear))
                .listRowInsets(EdgeInsets(top: 4, leading: Spacing.m, bottom: 4, trailing: Spacing.m))
                .onTapGesture {
                    withAnimation { _ = readIDs.insert(notif.id) }
                }
            }
            .listStyle(.plain)
        }
    }
}

struct NotificationRow: View {
    let notification: PushNotification
    let isUnread: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            // Icon
            ZStack {
                Circle()
                    .fill(topicColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: topicIcon)
                    .font(.title3)
                    .foregroundStyle(topicColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(isUnread ? .lmsHeadline : .lmsSubheadline)
                        .foregroundStyle(isUnread ? .primary : .secondary)
                    Spacer()
                    Text(timeAgo)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text(notification.body)
                    .font(.lmsCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if isUnread {
                Circle()
                    .fill(Color.lmsNavyBlue)
                    .frame(width: 9, height: 9)
                    .padding(.top, 6)
            }
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(isUnread ? Color.lmsNavyBlue.opacity(0.04) : Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
        .animation(.easeInOut, value: isUnread)
    }

    private var topicIcon: String {
        switch notification.topic {
        case .emiDue, .emiOverdue: return "exclamationmark.circle.fill"
        case .applicationStatus: return "doc.text.fill"
        case .disbursement: return "indianrupeesign.circle.fill"
        case .message: return "bubble.left.fill"
        case .system: return "gearshape.fill"
        }
    }

    private var topicColor: Color {
        switch notification.topic {
        case .emiOverdue: return .lmsDanger
        case .emiDue: return .lmsWarning
        case .applicationStatus: return .lmsNavyBlue
        case .disbursement: return .lmsSuccess
        case .message: return .lmsPrimary
        case .system: return .secondary
        }
    }

    private var timeAgo: String {
        let diff = Date().timeIntervalSince(notification.receivedAt)
        if diff < 60 { return "Just now" }
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }
}

#Preview {
    LONotificationsView()
}
