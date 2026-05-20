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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                // Total Distribution Card
                distributionCard

                // Recent Applications List
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("Recent Application")
                        .font(.lmsTitle2)
                        .foregroundStyle(.primary)

                    recentApplicationsCard
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .bold))
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
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("TOTAL DISTRIBUTION")
                    .font(.lmsSubheadline)
                    .foregroundStyle(.secondary)
                Text(viewModel.snapshot.stats.totalAmount)
                    .font(.lmsTitle)
                    .foregroundStyle(Color.lmsAccent)
            }
            
            HStack(spacing: 0) {
                statColumn(title: "Total user", value: "\(viewModel.snapshot.stats.totalUser)")
                Divider().frame(height: 40)
                statColumn(title: "Active Loans", value: "\(viewModel.snapshot.stats.activeLoans)")
                Divider().frame(height: 40)
                statColumn(title: "Application", value: "\(viewModel.snapshot.stats.applications)")
            }
        }
        .padding(Spacing.m)
        .background(
            Color(UIColor.systemBackground),
            in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
        )
    }
    
    private func statColumn(title: String, value: String) -> some View {
        VStack(spacing: Spacing.s) {
            Text(title)
                .font(.lmsCaption)
                .foregroundStyle(Color.lmsAccent)
            Text(value)
                .font(.lmsTitle2)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }

    /// Card for Recent Applications
    private var recentApplicationsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.snapshot.recentApplications.enumerated()), id: \.element.id) { index, app in
                HStack(alignment: .top) {
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
                .padding(.vertical, Spacing.s)
                .padding(.horizontal, Spacing.m)
                
                if index < viewModel.snapshot.recentApplications.count - 1 {
                    Divider()
                        .padding(.horizontal, Spacing.m)
                }
            }
        }
        .padding(.vertical, Spacing.s)
        .background(
            Color(UIColor.systemBackground),
            in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
        )
    }
}

#Preview {
    NavigationStack {
        DashboardView(viewModel: DashboardViewModel())
    }
}
