import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {

    @Environment(AppViewModel.self) var viewModel

    var body: some View {

        ScrollView(.vertical, showsIndicators: false) {

            VStack(spacing: 24) {

                // MARK: Header
                DashboardHeaderSection()

                // MARK: KPI Overview
                KPIOverviewSection()

                // MARK: Recovery Section
                RecoveryVerificationView()

                Spacer(minLength: 40)
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .toolbarTitleDisplayMode(.inlineLarge)
    }
}

// MARK: - Dashboard Header Section

struct DashboardHeaderSection: View {

    @Environment(AppViewModel.self) var viewModel

    var body: some View {

        HStack(alignment: .center, spacing: 15) {
            
            Button {
                viewModel.navigationPath.append(AppDestination.profile)
            } label: {
                LOAvatarView(
                    initials: viewModel.officerProfile.avatarInitials,
                    size: 44,
                    colors: [
                        Color(red: 0.2, green: 0.5, blue: 1.0),
                        Color(red: 0.4, green: 0.3, blue: 0.9)
                    ]
                )
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 5) {
                
                Text(viewModel.officerProfile.name.isEmpty ? "Welcome" : viewModel.officerProfile.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                Text(viewModel.selectedBranch.isEmpty ? viewModel.officerProfile.designation : viewModel.selectedBranch)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                
                viewModel.navigationPath.append(
                    AppDestination.notifications
                )
                
            } label: {
                
                ZStack(alignment: .topTrailing) {
                    
                    Image(systemName: "bell.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    Color(
                                        .secondarySystemGroupedBackground
                                    )
                                )
                        )
                    
                    LOCountBadge(
                        count: viewModel.unreadNotifications
                    )
                    .offset(x: 6, y: -4)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
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

        VStack(alignment: .leading) {

            LOSectionHeader(
                title: "Today's Activity",
                subtitle: "Daily metrics overview"
            )
            .padding(.horizontal, 20)

            LazyVGrid(columns: columns) {

                ForEach(viewModel.kpiData) { kpi in

                    KPICardView(kpi: kpi)
                }
            }
            .padding(.horizontal)
        }
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

// MARK: - Preview

#Preview {

    NavigationStack {

        DashboardView()
            .environment(AppViewModel())
    }
}
