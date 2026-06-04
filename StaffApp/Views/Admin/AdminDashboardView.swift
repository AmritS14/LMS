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
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("Profile")
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
