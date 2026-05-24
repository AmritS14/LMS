//
//  NotificationsTabView.swift
//  loan officer
//
//  Created by Aadya Tiwari on 21/05/26.
//

import SwiftUI

// MARK: - Notifications Tab

struct NotificationsTabView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    @State private var selectedFilter: String = "All"

    private let filters = ["All", "Fraud", "Approvals", "Assignments", "Overdue", "Escalations"]

    private var filteredNotifications: [AppNotification] {
        if selectedFilter == "All" { return viewModel.notifications }
        return viewModel.notifications.filter { notification in
            switch selectedFilter {
            case "Fraud": return notification.type == .fraudAlert
            case "Approvals": return notification.type == .pendingApproval
            case "Assignments": return notification.type == .assignedApplication
            case "Overdue": return notification.type == .overdueReminder
            case "Escalations": return notification.type == .escalation
            default: return true
            }
        }
    }

    private var unreadCount: Int {
        viewModel.notifications.filter { !$0.isRead }.count
    }

    private var urgentNotifications: [AppNotification] {
        viewModel.notifications.filter { $0.priority == 1 && !$0.isRead }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                // Unread Summary Card
                unreadSummaryCard

                // Urgent Alerts Card
                if !urgentNotifications.isEmpty {
                    urgentAlertsCard
                }

                // Priority Filter Chips
                filterChipsSection

                // Notification Cards
                ForEach(Array(filteredNotifications.enumerated()), id: \.element.id) { index, notification in
                    notificationCard(notification)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: selectedFilter)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    // MARK: Unread Summary
    private var unreadSummaryCard: some View {
        PremiumCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(unreadCount) unread alerts")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Text("Tap to mark as read")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: Urgent Alerts
    private var urgentAlertsCard: some View {
        GradientCard(gradient: [Color.red.opacity(0.85), Color(red: 0.75, green: 0.1, blue: 0.1)]) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("\(urgentNotifications.count) Urgent Alert\(urgentNotifications.count > 1 ? "s" : "")")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .opacity(0.7)
                }
                .foregroundColor(.white)

                ForEach(urgentNotifications) { notif in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                        Text(notif.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: Filter Chips
    private var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter)
                            .font(.system(size: 13, weight: selectedFilter == filter ? .semibold : .medium))
                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? Color.blue : Color(.tertiarySystemGroupedBackground))
                            )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: Notification Card
    private func notificationCard(_ notification: AppNotification) -> some View {
        PremiumCard {
            HStack(alignment: .top, spacing: 12) {
                // Type Icon
                ZStack {
                    Circle()
                        .fill(notification.type.color.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: notification.type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(notification.type.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)

                        Spacer()

                        if !notification.isRead {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(notification.message)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack {
                        Text(AppFormatters.timeAgo(notification.timestamp))
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)

                        Spacer()

                        if notification.priority == 1 {
                            StatusBadge(text: "Urgent", color: .red, icon: "exclamationmark.triangle.fill", size: .small)
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                viewModel.markNotificationRead(notification)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                // Dismiss action
            } label: {
                Label("Dismiss", systemImage: "xmark.circle")
            }
            .tint(.gray)
        }
        .swipeActions(edge: .leading) {
            Button {
                viewModel.markNotificationRead(notification)
            } label: {
                Label("Mark Read", systemImage: "envelope.open")
            }
            .tint(.blue)
        }
    }
}

#Preview {
    
    NavigationStack {
        NotificationsTabView()
            .environmentObject(AppViewModel())
    }
}
