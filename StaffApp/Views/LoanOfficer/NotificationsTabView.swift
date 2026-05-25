//
//  NotificationsTabView.swift
//  loan officer
//
//  Created by Aadya Tiwari on 21/05/26.
//

import SwiftUI

// MARK: - Notifications Tab

struct NotificationsTabView: View {
    @Environment(AppViewModel.self) var viewModel
    
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

    var body: some View {
        VStack(spacing: 0) {
            // Priority Filter Chips
            filterChipsSection
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGroupedBackground))

            if filteredNotifications.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.tertiary)
                    Text("No Notifications")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("You have no \(selectedFilter.lowercased()) notifications.")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .padding()
                Spacer()
            } else {
                List {
                    // Unread Summary Card
                    if unreadCount > 0 {
                        unreadSummaryCard
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    viewModel.markAllNotificationsRead()
                                }
                            }
                    }

                    ForEach(filteredNotifications) { notification in
                        notificationCard(notification)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteNotification(notification)
                                    }
                                } label: {
                                    Label("Dismiss", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    withAnimation {
                                        if notification.isRead {
                                            if let index = viewModel.notifications.firstIndex(where: { $0.id == notification.id }) {
                                                viewModel.notifications[index].isRead = false
                                            }
                                        } else {
                                            viewModel.markNotificationRead(notification)
                                        }
                                    }
                                } label: {
                                    if notification.isRead {
                                        Label("Unread", systemImage: "envelope.badge")
                                    } else {
                                        Label("Read", systemImage: "envelope.open")
                                    }
                                }
                                .tint(.blue)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                if unreadCount > 0 {
//                    Button("Mark All Read") {
//                        withAnimation {
//                            viewModel.markAllNotificationsRead()
//                        }
//                    }
//                    .font(.system(size: 15, weight: .medium))
//                }
//            }
//        }
    }

    // MARK: Unread Summary
    private var unreadSummaryCard: some View {
        LOPremiumCard {
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
                    Text("Tap to mark all as read")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: Filter Chips
    private var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
                                    .fill(selectedFilter == filter ? Color.blue : Color(.secondarySystemGroupedBackground))
                            )
                    }
                }
            }
        }
    }

    // MARK: Notification Card
    private func notificationCard(_ notification: AppNotification) -> some View {
        LOPremiumCard {
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
                        .multilineTextAlignment(.leading)

                    HStack {
                        Text(AppFormatters.timeAgo(notification.timestamp))
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)

                        Spacer()

                        if notification.priority == 1 {
                            LOStatusBadge(text: "Urgent", color: .red, icon: "exclamationmark.triangle.fill", size: .small)
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                viewModel.markNotificationRead(notification)
            }
            
            // Look up borrower name from title or message and deep-link
            if let matchedApp = viewModel.recentApplications.first(where: { app in
                notification.title.localizedCaseInsensitiveContains(app.borrowerName) ||
                notification.message.localizedCaseInsensitiveContains(app.borrowerName)
            }) {
                viewModel.selectedApplication = matchedApp
                viewModel.navigationPath.append(AppDestination.loanReview)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsTabView()
            .environment(AppViewModel())
    }
}
