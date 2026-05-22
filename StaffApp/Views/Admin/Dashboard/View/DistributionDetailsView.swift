//
//  DistributionDetailsView.swift
//  LMS(GU)
//
//  Created by Antigravity on 22/05/26.
//

import SwiftUI

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
            
            Text("Aggregated across all approved active loans")
                .font(.lmsCaption)
                .foregroundStyle(.white.opacity(0.7))
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

    private var loanDistributionSection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            SectionHeaderView(title: "Loan Portfolio Breakdown", systemImage: "chart.pie.fill")
            
            VStack(spacing: Spacing.m) {
                distributionRow(title: "Home Loans", amount: "₹45.00 L", percentage: 0.547, color: .indigo)
                Divider()
                distributionRow(title: "Business Loans", amount: "₹20.50 L", percentage: 0.249, color: .orange)
                Divider()
                distributionRow(title: "Personal Loans", amount: "₹8.50 L", percentage: 0.103, color: .cyan)
                Divider()
                distributionRow(title: "Vehicle Loans", amount: "₹8.20 L", percentage: 0.100, color: .teal)
            }
            .padding(AdminSpacing.cardPadding)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
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
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var applicationStatusSection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            SectionHeaderView(title: "Active Loans & Applications", systemImage: "folder.badge.gearshape")
            
            HStack(spacing: Spacing.s) {
                NavigationLink(destination: DemographicUserListView(role: nil, viewModel: userVM)) {
                    cardView(
                        count: "\(viewModel.snapshot.stats.totalUser)",
                        title: "Total Users",
                        color: .blue
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: DashboardLoansListView(title: "Active Loans", applications: viewModel.snapshot.recentApplications.filter { $0.status == .approved })) {
                    cardView(
                        count: "\(viewModel.snapshot.stats.activeLoans)",
                        title: "Active Loans",
                        color: AdminColor.accent
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: DashboardLoansListView(title: "Applications", applications: viewModel.snapshot.recentApplications)) {
                    cardView(
                        count: "\(viewModel.snapshot.stats.applications)",
                        title: "Applications",
                        color: .green
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func cardView(count: String, title: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(count)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            HStack(spacing: 2) {
                Text("View Details")
                    .font(.system(size: 9, weight: .medium))
                Image(systemName: "chevron.right")
                    .font(.system(size: 7))
            }
            .foregroundStyle(color)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.m)
        .padding(.horizontal, Spacing.xs)
        .background(Color.primary.opacity(0.02), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    // MARK: - Row Helpers

    private func distributionRow(title: String, amount: String, percentage: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(title)
                    .font(.lmsHeadline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(amount)
                    .font(.lmsHeadline)
                    .foregroundStyle(.primary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.05))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.gradient)
                        .frame(width: geo.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Spacer()
                Text(String(format: "%.1f%%", percentage * 100))
                    .font(.lmsCaption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func statRow(title: String, count: Int, systemImage: String) -> some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(AdminColor.accent)
                .frame(width: 24, alignment: .center)
            
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
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

