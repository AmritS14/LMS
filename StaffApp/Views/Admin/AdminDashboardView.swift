//
//  DashboardView.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI

// MARK: - Admin Dashboard View

struct AdminDashboardView: View {
    var viewModel: DashboardViewModel
    @Bindable var userVM: UserManagementViewModel
    @Environment(\.appEnvironment) private var env
    @State private var showAddStaff = false


    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.l) {
                if let error = viewModel.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Retry") {
                            Task { await viewModel.loadDashboard() }
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    }
                    .padding(Spacing.m)
                    .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                    .padding(.horizontal, Spacing.m)
                }

                subtitleRow
                summaryCardsSection
                auditActivitySection
            }
            .padding(.bottom, Spacing.m)
        }
        .background(Color.lmsBackground)
        .navigationTitle("Dashboard")
        .toolbarTitleDisplayMode(.large)
        .navigationDestination(for: UserManagementViewModel.Filter.self) { filter in
            UserListView(viewModel: userVM)
                .onAppear {
                    userVM.currentFilter = filter
                }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 20) {
                    NavigationLink(destination: AdminNotificationsView(viewModel: viewModel)) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.primary)
                            
                            if viewModel.unreadNotificationsCount > 0 {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .accessibilityLabel("Notifications")

                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Profile")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                )
            }
        }
        .refreshable {
            try? await viewModel.refreshDashboard()
        }
        .task {
            viewModel.configure(environment: env)
            await viewModel.loadDashboard()
            viewModel.subscribeToRealtimeChanges()
        }
        .onDisappear {
            viewModel.unsubscribeFromRealtime()
        }
        .sheet(isPresented: $showAddStaff) {
            AddStaffSheet(viewModel: userVM)
        }
    }

    // MARK: - Subviews

    private var subtitleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Role: Administrator")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.m)
    }

    private var summaryCardsSection: some View {
        VStack(spacing: Spacing.m) {
            HStack(spacing: Spacing.m) {
                summaryCard(
                    icon: "person.2.fill",
                    title: "Total Users",
                    value: "\(viewModel.snapshot.stats.totalUser)",
                    subtitle: "Registered accounts",
                    accent: .blue
                )
                summaryCard(
                    icon: "checkmark.circle.fill",
                    title: "Active Loans",
                    value: "\(viewModel.snapshot.stats.activeLoans)",
                    subtitle: "Servicing portfolio",
                    accent: .green
                )
            }
            HStack(spacing: Spacing.m) {
                summaryCard(
                    icon: "doc.text.fill",
                    title: "Applications",
                    value: "\(viewModel.snapshot.stats.applications)",
                    subtitle: "Total submissions",
                    accent: .orange
                )
                summaryCard(
                    icon: "indianrupeesign.circle.fill",
                    title: "Total Disbursed",
                    value: viewModel.snapshot.stats.totalAmount,
                    subtitle: "Total distribution",
                    accent: .purple
                )
            }
        }
        .padding(.horizontal, Spacing.m)
    }

    private func summaryCard(icon: String, title: String, value: String,
                              subtitle: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(accent)
                    .frame(width: 32, height: 32)
                    .background(accent.opacity(0.12),
                                 in: RoundedRectangle(cornerRadius: CornerRadius.small))
                Spacer()
            }
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    private var auditActivitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("Audit Activity")
                    .font(.lmsHeadline)
                Spacer()
                NavigationLink(destination: AuditListView()) {
                    Text("See All")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.lmsAccent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.m)

            VStack(spacing: 0) {
                if viewModel.recentAuditLogs.isEmpty {
                    Text("No recent audit activity.")
                        .font(.adminSecondary)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, Spacing.m)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(Array(viewModel.recentAuditLogs.prefix(5).enumerated()), id: \.element.id) { index, entry in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text(entry.action)
                                    .font(.adminCardTitle)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(entry.timestamp, format: .relative(presentation: .named))
                                    .font(.adminCaption)
                                    .foregroundStyle(.secondary)
                            }
                            Text("\(entry.actorRole.displayName) • \(entry.entityType)")
                                .font(.adminSecondary)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())

                        if index < viewModel.recentAuditLogs.prefix(5).count - 1 {
                            Divider()
                                .padding(.leading, Spacing.m)
                        }
                    }
                }
            }
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .padding(.horizontal, Spacing.m)
        }
    }
}

// MARK: - Admin Notifications View

struct AdminNotificationsView: View {
    var viewModel: DashboardViewModel

    var body: some View {
        List {
            if viewModel.unreadNotificationsCount > 0 {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(viewModel.unreadNotificationsCount) unread").font(.headline)
                            Text("Swipe to read or dismiss").font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Read all") { viewModel.markAllNotificationsRead() }
                            .font(.subheadline.weight(.semibold))
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.lmsAccent)
                    }
                }
            }

            Section("All Notifications") {
                if viewModel.notifications.isEmpty {
                    Text("No notifications.")
                        .font(.adminSecondary)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, Spacing.s)
                } else {
                    ForEach(viewModel.notifications) { notification in
                        row(notification)
                            .swipeActions(edge: .leading) {
                                Button { viewModel.markNotificationRead(notification) } label: {
                                    Label("Read", systemImage: "envelope.open")
                                }
                                .tint(.lmsInfo)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.dismissNotification(notification)
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
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ notification: AdminNotification) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "bell.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(notification.isRead ? .secondary : Color.lmsAccent)
                .frame(width: 32, height: 32)
                .background((notification.isRead ? Color.secondary : Color.lmsAccent).opacity(0.12),
                            in: RoundedRectangle(cornerRadius: CornerRadius.small))

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(notification.isRead ? .secondary : .primary)
                    Spacer()
                    Text(notification.createdAt, format: .relative(presentation: .named))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundStyle(notification.isRead ? .tertiary : .secondary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        AdminDashboardView(viewModel: DashboardViewModel(), userVM: UserManagementViewModel())
    }
}

#Preview {
    NavigationStack {
        AdminDashboardView(viewModel: DashboardViewModel(), userVM: UserManagementViewModel())
    }
}

#Preview {
    NavigationStack {
        AdminDashboardView(viewModel: DashboardViewModel(), userVM: UserManagementViewModel())
    }
}
