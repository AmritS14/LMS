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
    @State private var showDetails: Bool = false

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

            // Total Distribution Card
            distributionCard
                .contentShape(Rectangle())
                .onTapGesture {
                    showDetails = true
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.bottom, Spacing.m)

            // Recent Applications List
            recentApplicationsList
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Overview")
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
            try? await viewModel.refreshDashboard()
        }
        .task {
            viewModel.configure(environment: env)
            await viewModel.loadDashboard()
            viewModel.subscribeToRealtimeChanges()
        }
        .onAppear {
            viewModel.isAmountVisible = false
        }
        .onDisappear {
            viewModel.unsubscribeFromRealtime()
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
                    Text(viewModel.isAmountVisible ? Formatting.compactIndianRupee(viewModel.rawTotalAmount) : "₹••••••")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Image(systemName: viewModel.isAmountVisible ? "eye" : "eye.slash")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            viewModel.isAmountVisible.toggle()
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(viewModel.isAmountVisible ? "Hide amount" : "Show amount")
                    .accessibilityAddTraits(.isButton)
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
            if viewModel.isLoading && viewModel.snapshot.recentApplications.isEmpty {
                HStack {
                    Spacer()
                    ProgressView("Loading applications...")
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .padding(.vertical, 20)
            } else if viewModel.snapshot.recentApplications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Recent Applications")
                        .font(.lmsHeadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.snapshot.recentApplications) { app in
                    NavigationLink(destination: AdminApplicationDetailView(applicationID: app.id)) {
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
                                    app.status.displayLabel.capitalized,
                                    tone: app.status == .approved ? .success : .warning
                                )
                                
                                Text(app.date)
                                    .font(.lmsCaption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
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
