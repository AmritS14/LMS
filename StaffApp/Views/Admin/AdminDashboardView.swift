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
    @State private var isAmountVisible: Bool = true
    @State private var showDetails: Bool = false

    var body: some View {
        List {
            // Total Distribution Card
            Button {
                showDetails = true
            } label: {
                distributionCard
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .padding(.bottom, Spacing.m)

            // Recent Applications List
            recentApplicationsList
        }
        .listStyle(.insetGrouped)
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
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL DISTRIBUTION")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(isAmountVisible ? viewModel.snapshot.stats.totalAmount : "••••••")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
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
        .padding(20)
        .background(
            Color.blue.gradient,
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

    /// List of separate Recent Application cards
    private var recentApplicationsList: some View {
        Section {
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
            }
        } header: {
            Text("Recent Applications").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
        }
    }
}

#Preview {
    NavigationStack {
        AdminDashboardView(viewModel: DashboardViewModel(), userVM: UserManagementViewModel())
    }
}
