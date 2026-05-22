import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {

    @EnvironmentObject var viewModel: AppViewModel

    @State private var expandedId: UUID?

    var body: some View {

        ScrollView(.vertical, showsIndicators: false) {

            VStack(spacing: 24) {

                // MARK: Header
                DashboardHeaderSection()

                // MARK: KPI Overview
                KPIOverviewSection()

                // MARK: Recent Applications
                RecentApplicationsSection(
                    expandedId: $expandedId
                )

                // MARK: Recovery Management
                RecoveryManagementButton()

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

    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {

        HStack(alignment: .center, spacing: 15) {
            
            Button {
                viewModel.navigationPath.append(AppDestination.profile)
            } label: {
                AvatarView(
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
                
                Text(viewModel.officerProfile.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                Text(viewModel.selectedBranch)
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
                    
                    Image(systemName: "bell.badge.fill")
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
                    
                    CountBadge(
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

    @EnvironmentObject var viewModel: AppViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {

        VStack(alignment: .leading) {

            SectionHeader(
                title: "Performance Overview",
                subtitle: "Today's metrics"
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

        VStack(alignment: .leading) {

            Image(systemName: kpi.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(kpi.color)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(kpi.color.opacity(0.12))
                )

            Text("\(kpi.value)")
                .font(
                    .system(
                        size: 28,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.primary)

            Text(kpi.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 170, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white))
    }
}

// MARK: - Recent Applications Section

struct RecentApplicationsSection: View {

    @EnvironmentObject var viewModel: AppViewModel

    @Binding var expandedId: UUID?

    private var recentApplications: [LoanApplication] {

        Array(viewModel.filteredApplications.prefix(3))
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            SectionHeader(
                title: "Recent Applications",
                subtitle: "\(viewModel.filteredApplications.count) applications",
                actionTitle: "View All"
            ) {

                viewModel.navigationPath.append(
                    AppDestination.allapplications
                )
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {

                ForEach(recentApplications) { application in

                    ApplicationCardView(
                        application: application,
                        isExpanded: expandedId == application.id
                    )
                    .environmentObject(viewModel)
                    .contentShape(Rectangle())
                    .onTapGesture {

                        withAnimation()
                        {

                            if expandedId == application.id {

                                expandedId = nil

                            } else {

                                expandedId = application.id
                            }
                        }

                        let feedback = UIImpactFeedbackGenerator(
                            style: .light
                        )

                        feedback.impactOccurred()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ApplicationCardView: View {

    @EnvironmentObject var viewModel: AppViewModel

    let application: LoanApplication
    let isExpanded: Bool

    var body: some View {

        PremiumCard {

            VStack(alignment: .leading, spacing: 12) {

                // MARK: Top Row

                HStack(alignment: .top, spacing: 12) {

                    AvatarView(
                        initials: application.borrowerInitials,
                        size: 42,
                        colors:
                            application.riskLevel == .critical
                            ? [.red, Color(red: 0.75, green: 0.05, blue: 0.05)]
                            : [
                                Color(red: 0.2, green: 0.5, blue: 1.0),
                                Color(red: 0.4, green: 0.3, blue: 0.9)
                            ]
                    )

                    VStack(alignment: .leading, spacing: 3) {

                        HStack(spacing: 6) {

                            Text(application.borrowerName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)

                            if application.fraudFlag {

                                Image(systemName: "exclamationmark.shield.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.red)
                            }
                            Spacer()
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text(
                            "\(application.loanType) • \(AppFormatters.formatCurrency(application.loanAmount))"
                        )
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                }

                // MARK: Status Row

                HStack(spacing: 8) {

                    StatusBadge(
                        text: application.status.rawValue,
                        color: application.status.color,
                        icon: application.status.icon,
                        size: .small
                    )

//                    StatusBadge(
//                        text: application.riskLevel.rawValue,
//                        color: application.riskLevel.color,
//                        icon: application.riskLevel.icon,
//                        size: .small
//                    )

                    Spacer()

                    
                }

                // MARK: Expanded Details

                if isExpanded {

                    VStack(spacing: 0) {

                        Divider()
                            .padding(.vertical, 8)

                        VStack(spacing: 6) {

                            DetailRow(
                                icon: application.kycStatus.icon,
                                title: "KYC Status",
                                value: application.kycStatus.rawValue,
                                valueColor: application.kycStatus.color
                            )

                            DetailRow(
                                icon: "gauge.medium",
                                title: "Eligibility Score",
                                value: "\(application.eligibilityScore)/100",
                                valueColor:
                                    application.eligibilityScore >= 70
                                    ? .green
                                    : (
                                        application.eligibilityScore >= 50
                                        ? .orange
                                        : .red
                                    )
                            )

                            DetailRow(
                                icon: "indianrupeesign.circle.fill",
                                title: "EMI Amount",
                                value: AppFormatters.formatCurrency(application.emiAmount),
                                valueColor: .primary
                            )

                            DetailRow(
                                icon: "calendar",
                                title: "Applied On",
                                value: AppFormatters.formatDate(application.applicationDate),
                                valueColor: .primary
                            )

                            DetailRow(
                                icon: "briefcase.fill",
                                title: "Employment",
                                value: application.employmentType,
                                valueColor: .primary
                            )

                            DetailRow(
                                icon: "percent",
                                title: "Interest Rate",
                                value: String(format: "%.2f%%", application.interestRate),
                                valueColor: .primary
                            )
                        }
                      
                        // MARK: View Details Button

                        Button {

                            viewModel.selectedApplication = application
                            viewModel.navigationPath.append(AppDestination.loanReview)

                        } label: {

                            HStack(spacing: 6) {

                                Text("View Full Details")
                                    .font(.system(size: 14, weight: .semibold))

                                
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.blue,
                                                Color.blue.opacity(0.8)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 12)

                        // MARK: Message Borrower Button

                        Button {

                            if let conversation = viewModel.conversations.first(where: {
                                $0.borrowerName == application.borrowerName
                            }) {

                                viewModel.selectedConversation = conversation

                                viewModel.navigationPath.append(
                                    AppDestination.communications
                                )
                            }

                        } label: {

                            HStack(spacing: 6) {

                                Image(systemName: "message.fill")
                                    .font(.system(size: 13))

                                Text("Message Borrower")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                }
            }
        }
    }
}

// MARK: - Recovery Management Button

struct RecoveryManagementButton: View {

    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            SectionHeader(
                title: "Recovery Management",
                subtitle: "Manage overdue recoveries"
            )
            .padding(.horizontal, 20)

            Button {

                viewModel.navigationPath.append(
                    AppDestination.recovery
                )

            } label: {

                HStack(spacing: 14) {

                    ZStack {

                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 52, height: 52)

                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 4) {

                        Text("Recovery Management")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold
                                )
                            )

                        Text("Track overdue & pending recoveries")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(
                            .system(
                                size: 12,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            Color(
                                .secondarySystemGroupedBackground
                            )
                        )
                )
                .padding(.horizontal, 20)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        DashboardView()
            .environmentObject(AppViewModel())
    }
}
