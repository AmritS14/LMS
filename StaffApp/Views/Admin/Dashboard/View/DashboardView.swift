//
//  DashboardView.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI

// MARK: - Admin Dashboard View

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    @Bindable var userVM: UserManagementViewModel
    @State private var isAmountVisible: Bool = true
    @State private var showDetails: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                // Total Distribution Card
                Button {
                    showDetails = true
                } label: {
                    distributionCard
                }
                .buttonStyle(.plain)

                // Recent Applications List
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    Text("Recent Applications")
                        .font(.lmsTitle2)
                        .foregroundStyle(.primary)

                    recentApplicationsList
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.xl)
        }
        .background(AdminColor.background)
        .navigationTitle("Dashboard")
        .navigationDestination(isPresented: $showDetails) {
            DistributionDetailsView(viewModel: viewModel, userVM: userVM)
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
            await viewModel.refreshDashboard()
        }
    }

    // MARK: - Subviews

    /// Card for Total Distribution
    private var distributionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("TOTAL DISTRIBUTION")
                        .font(.lmsSubheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(isAmountVisible ? viewModel.snapshot.stats.totalAmount : "••••••")
                        .font(.lmsTitle)
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Button {
                    isAmountVisible.toggle()
                } label: {
                    Image(systemName: isAmountVisible ? "eye" : "eye.slash")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            
            HStack(spacing: 0) {
                statColumn(title: "Total user", value: "\(viewModel.snapshot.stats.totalUser)")
                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.25))
                statColumn(title: "Active Loans", value: "\(viewModel.snapshot.stats.activeLoans)")
                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.25))
                statColumn(title: "Application", value: "\(viewModel.snapshot.stats.applications)")
            }
        }
        .padding(Spacing.m)
        .background(
            AdminColor.accentGradient,
            in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
        )
        .shadow(color: AdminColor.accent.opacity(0.25), radius: 10, x: 0, y: 5)
    }
    
    private func statColumn(title: String, value: String) -> some View {
        VStack(spacing: Spacing.s) {
            Text(title)
                .font(.lmsCaption)
                .foregroundStyle(.white.opacity(0.85))
            Text(value)
                .font(.lmsTitle2)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    /// List of separate Recent Application cards
    private var recentApplicationsList: some View {
        VStack(spacing: AdminSpacing.cardGap) {
            ForEach(viewModel.snapshot.recentApplications) { app in
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
}

#Preview {
    NavigationStack {
        DashboardView(viewModel: DashboardViewModel(), userVM: UserManagementViewModel())
    }
}
