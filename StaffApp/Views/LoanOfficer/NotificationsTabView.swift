import SwiftUI

struct NotificationsTabView: View {
    @Environment(LoanOfficerStore.self) private var store
    @State private var selectedType: OfficerNotificationType?

    private var filtered: [OfficerNotification] {
        guard let selectedType else { return store.notifications }
        return store.notifications.filter { $0.type == selectedType }
    }

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
                            Text("\(store.unreadNotificationCount) unread")
                                .font(.headline)
                            Text("Tap a notification to mark it read")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Read all") { store.markAllNotificationsRead() }
                            .font(.subheadline.weight(.semibold))
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.lmsAccent)
                    }
                }
            }

            if !store.urgentNotifications.isEmpty {
                Section("Urgent") {
                    ForEach(store.urgentNotifications) { notification in
                        row(notification)
                            .listRowBackground(Color.lmsDanger.opacity(0.08))
                    }
                }
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s) {
                        chip(label: "All", isSelected: selectedType == nil) {
                            selectedType = nil
                        }
                        ForEach(OfficerNotificationType.allCases, id: \.self) { type in
                            chip(label: type.rawValue,
                                 icon: type.icon,
                                 isSelected: selectedType == type) {
                                selectedType = (selectedType == type) ? nil : type
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.s)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            if filtered.isEmpty {
                ContentUnavailableView("All caught up",
                                       systemImage: "checkmark.circle.fill",
                                       description: Text("No notifications match the current filter."))
            } else {
                Section("All Notifications") {
                    ForEach(filtered) { notification in
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
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
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

    private func chip(label: String, icon: String? = nil, isSelected: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon).font(.caption2.weight(.semibold))
                }
                Text(label).font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xs)
            .background(isSelected ? Color.lmsAccent : Color.lmsFill, in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
