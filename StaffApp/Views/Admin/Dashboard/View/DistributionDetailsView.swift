//
//  DistributionDetailsView.swift
//  LMS(GU)
//
//  Created by Antigravity on 22/05/26.
//

import SwiftUI
import Charts

struct DistributionDetailsView: View {
    @Bindable var viewModel: DashboardViewModel
    @Bindable var userVM: UserManagementViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                // Main Highlight Header Card
                mainHeaderCard

                // 1. Loan Type Distribution breakdown
                loanDistributionSection

                // 2. User Statistics breakdown
                userStatsSection

                // 3. Application Status summary
                applicationStatusSection
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.xl)
        }
        .background(AdminColor.background)
        .navigationTitle("Distribution Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var mainHeaderCard: some View {
        VStack(spacing: Spacing.s) {
            Text("TOTAL DISTRIBUTION")
                .font(.lmsSubheadline)
                .foregroundStyle(.white.opacity(0.8))
            
            Text(viewModel.snapshot.stats.totalAmount)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.l)
        .padding(.horizontal, Spacing.m)
        .background(
            AdminColor.accentGradient,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .shadow(color: AdminColor.accent.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    private let portfolioData: [(category: String, amountStr: String, amount: Double, percentage: Double, color: Color)] = [
        ("Home", "₹45L", 45.00, 0.547, .indigo),
        ("Business", "₹20.5L", 20.50, 0.249, .orange),
        ("Personal", "₹8.5L", 8.50, 0.103, .cyan),
        ("Vehicle", "₹8.2L", 8.20, 0.100, .teal)
    ]

    private var loanDistributionSection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            SectionHeaderView(title: "Loan Portfolio Breakdown", systemImage: "chart.bar.fill")
            
            VStack {
                Chart {
                    ForEach(portfolioData, id: \.category) { item in
                        BarMark(
                            x: .value("Category", item.category),
                            y: .value("Amount", item.amount)
                        )
                        .foregroundStyle(item.color.gradient)
                        .cornerRadius(6)
                        .annotation(position: .top, alignment: .center) {
                            VStack(spacing: 2) {
                                Text(item.amountStr)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.primary)
                                Text(String(format: "%.1f%%", item.percentage * 100))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.bottom, 2)
                        }
                    }
                }
                .frame(height: 220)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel() {
                            if let category = value.as(String.self) {
                                Text(category)
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
            .padding(AdminSpacing.cardPadding)
            .padding(.top, Spacing.m)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
    }

    private var userStatsSection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            SectionHeaderView(title: "User Demographics", systemImage: "person.3.fill")
            
            VStack(spacing: Spacing.s) {
                NavigationLink(destination: DemographicUserListView(role: .borrower, viewModel: userVM)) {
                    statRow(title: "Borrowers", count: userVM.users.filter { $0.role == .borrower }.count, systemImage: "person.crop.circle")
                }
                .buttonStyle(.plain)
                
                Divider()
                
                NavigationLink(destination: DemographicUserListView(role: .loanOfficer, viewModel: userVM)) {
                    statRow(title: "Loan Officers", count: userVM.users.filter { $0.role == .loanOfficer }.count, systemImage: "briefcase.fill")
                }
                .buttonStyle(.plain)
                
                Divider()
                
                NavigationLink(destination: DemographicUserListView(role: .manager, viewModel: userVM)) {
                    statRow(title: "Managers", count: userVM.users.filter { $0.role == .manager }.count, systemImage: "person.2.fill")
                }
                .buttonStyle(.plain)
                
                Divider()
                
                NavigationLink(destination: DemographicUserListView(role: .admin, viewModel: userVM)) {
                    statRow(title: "Admins", count: userVM.users.filter { $0.role == .admin }.count, systemImage: "shield.fill")
                }
                .buttonStyle(.plain)
            }
            .padding(AdminSpacing.cardPadding)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
    }

    private var applicationStatusSection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            SectionHeaderView(title: "Active Loans & Applications", systemImage: "folder.badge.gearshape")
            
            VStack(spacing: Spacing.s) {
                NavigationLink(destination: DemographicUserListView(role: nil, viewModel: userVM)) {
                    statRow(title: "Total Users", count: viewModel.snapshot.stats.totalUser, systemImage: "")
                }
                .buttonStyle(.plain)
                
                Divider()
                
                NavigationLink(destination: DashboardLoansListView(title: "Active Loans", applications: viewModel.snapshot.recentApplications.filter { $0.status == .approved })) {
                    statRow(title: "Active Loans", count: viewModel.snapshot.stats.activeLoans, systemImage: "")
                }
                .buttonStyle(.plain)
                
                Divider()
                
                NavigationLink(destination: DashboardLoansListView(title: "Applications", applications: viewModel.snapshot.recentApplications)) {
                    statRow(title: "Applications", count: viewModel.snapshot.stats.applications, systemImage: "")
                }
                .buttonStyle(.plain)
            }
            .padding(AdminSpacing.cardPadding)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
    }

    // Row Helpers

    private func statRow(title: String, count: Int, systemImage: String) -> some View {
        HStack(spacing: Spacing.s) {
            Text(title)
                .font(.lmsSubheadline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.lmsHeadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.04), in: Capsule())
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Demographic User List View

struct DemographicUserListView: View {
    let role: UserRole?
    @Bindable var viewModel: UserManagementViewModel

    var filteredUsers: [User] {
        if let role {
            return viewModel.users.filter { $0.role == role }
        } else {
            return viewModel.users
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AdminSpacing.cardGap) {
                if filteredUsers.isEmpty {
                    Text("No users found.")
                        .font(.lmsSubheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 20)
                } else {
                    ForEach(filteredUsers) { user in
                        NavigationLink(destination: UserDetailsView(viewModel: viewModel, user: user)) {
                            UserRowView(user: user, profile: viewModel.staffProfiles[user.id])
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.m)
        }
        .background(AdminColor.background)
        .navigationTitle(role != nil ? "\(role!.displayName)s" : "Total Users")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Dashboard Loans List View

struct DashboardLoansListView: View {
    let title: String
    let applications: [RecentApplication]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AdminSpacing.cardGap) {
                if applications.isEmpty {
                    Text("No records found.")
                        .font(.lmsSubheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 20)
                } else {
                    ForEach(applications) { app in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(app.name)
                                    .font(.lmsHeadline)
                                    .foregroundStyle(.primary)
                                Text("\(app.loanType.rawValue.capitalized) • \(app.amount)")
                                    .font(.lmsCaption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: Spacing.xs) {
                                StatusBadge(
                                    app.status.rawValue.capitalized,
                                    tone: app.status == .approved ? .success : .warning
                                )
                                
                                Text(app.date)
                                    .font(.lmsCaption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(AdminSpacing.cardPadding)
                        .background(
                            AdminColor.cardBackground,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                    }
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.m)
        }
        .background(AdminColor.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

