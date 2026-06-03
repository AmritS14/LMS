import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {

    @Environment(AppViewModel.self) var viewModel

    var body: some View {

        ScrollView(.vertical, showsIndicators: false) {

            VStack(spacing: 24) {

                // MARK: Subtitle Row
                subtitleRow

                // MARK: KPI Overview
                KPIOverviewSection()

                // MARK: Recent Applications Section
                RecentApplicationsSection()

                Spacer(minLength: 40)
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
        .toolbarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                toolbarPill
            }
        }
    }

    private var subtitleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Branch: \(viewModel.selectedBranch.isEmpty ? (viewModel.officerProfile.branch.isEmpty ? "—" : viewModel.officerProfile.branch) : viewModel.selectedBranch)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var toolbarPill: some View {
        HStack(spacing: 20) {
            Button {
                viewModel.navigationPath.append(AppDestination.notifications)
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    if viewModel.unreadNotifications > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications")
            
            Button {
                viewModel.navigationPath.append(AppDestination.profile)
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
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


// MARK: - KPI Overview Section

struct KPIOverviewSection: View {

    @Environment(AppViewModel.self) var viewModel

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {

        LazyVGrid(columns: columns) {

            ForEach(viewModel.kpiData) { kpi in

                KPICardView(kpi: kpi)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - KPI Card View

struct KPICardView: View {

    let kpi: KPIData

    var body: some View {

        VStack(alignment: .leading, spacing: 8) {
            
            // Icon Badge
            ZStack {
                Circle()
                    .fill(kpi.color.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: kpi.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(kpi.color)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text("\(kpi.value)")
                    .font(
                        .system(
                            size: 26,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.primary)

                Text(kpi.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 105, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - Recent Applications Section

struct RecentApplicationsSection: View {
    @Environment(AppViewModel.self) var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LOSectionHeader(
                title: "Recent Applications",
                subtitle: "Latest files in queue",
                actionTitle: "View All",
                action: {
                    viewModel.navigationPath.append(AppDestination.allapplications)
                }
            )
            .padding(.horizontal, 20)

            VStack(spacing: 14) {
                if viewModel.recentApplications.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("No Applications Assigned")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                } else {
                    ForEach(viewModel.recentApplications.prefix(3)) { application in
                        Button {
                            viewModel.selectedApplication = application
                            viewModel.navigationPath.append(AppDestination.loanReview)
                        } label: {
                            applicationCard(application)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private func applicationCard(_ application: LOLoanApplication) -> some View {
        LOPremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    LOAvatarView(
                        initials: application.borrowerInitials,
                        size: 48,
                        colors: application.riskLevel == .critical ? [.red, .pink] : [.blue, .cyan]
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(application.borrowerName)
                                .font(.system(size: 16, weight: .semibold))
                            if application.fraudFlag {
                                Image(systemName: "exclamationmark.shield.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.red)
                            }
                        }
                        
                        Text(application.loanType)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        
                        Text(AppFormatters.formatCurrency(application.loanAmount))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                HStack(spacing: 8) {
                    LOStatusBadge(
                        text: application.status.rawValue,
                        color: application.status.color,
                        icon: application.status.icon,
                        size: .small
                    )
                    
                    Spacer()
                    
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(AppFormatters.timeAgo(application.applicationDate))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        DashboardView()
            .environment(AppViewModel())
    }
}
