//
//  DashboardView.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI

// MARK: - Admin Dashboard View

struct AdminDashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    @Bindable var userVM: UserManagementViewModel
    @Environment(\.appEnvironment) private var env
    @State private var showAddStaff = false


    var body: some View {
        List {
            if let error = viewModel.error {
                Section {
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
                }
            }

            distributionCard
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.bottom, Spacing.m)



            auditActivitySection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Dashboard")
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
                        .font(.title3)
                }
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
        .onAppear {
            // Amount visibility was removed
        }
        .onDisappear {
            viewModel.unsubscribeFromRealtime()
        }
        .sheet(isPresented: $showAddStaff) {
            AddStaffSheet(viewModel: userVM)
        }
    }

    // MARK: - Subviews

    /// Card for Total Distribution Stats
    private var distributionCard: some View {
        HStack(spacing: 0) {
            statColumn(title: "Total Borrowers", value: "\(viewModel.snapshot.stats.totalUser)")
            
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: 40)
                
            statColumn(title: "Active Loans", value: "\(viewModel.snapshot.stats.activeLoans)")
            
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: 40)
                
            statColumn(title: "Application", value: "\(viewModel.snapshot.stats.applications)")
        }
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.55, blue: 1.0), Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }
    
    private func statColumn(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }



    private var auditActivitySection: some View {
        Section {
            if viewModel.recentAuditLogs.isEmpty {
                Text("No recent audit activity.")
                    .font(.adminSecondary)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, Spacing.s)
            } else {
                ForEach(viewModel.recentAuditLogs, id: \.id) { entry in
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
                    .padding(.vertical, Spacing.xs)
                }
            }
        } header: {
            HStack {
                Text("AUDIT ACTIVITY")
                    .font(.adminSectionHeader)
                    .foregroundStyle(Color.secondary)
                Spacer()
                NavigationLink(destination: AuditListView()) {
                    Text("See All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.leading, 8)
            .padding(.bottom, 4)
            .textCase(.uppercase)
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
