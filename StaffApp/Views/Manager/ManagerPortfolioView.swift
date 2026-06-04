import SwiftUI

// MARK: - Tab 2: Portfolio

struct ManagerPortfolioView: View {
    @Environment(ManagerStore.self) private var store
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.l) {
                greetingSection
                summaryCardsSection
                portfolioHealthSection
                loanCategoriesSection
                officerPerformanceSection
                collectionSection
                npaSection
            }
            .padding(.vertical, Spacing.m)
        }
        .background(Color.lmsBackground)
        .navigationTitle("Dashboard")
        .toolbarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.m) {
                    NavigationLink(value: ManagerRoute.notifications) {
                        Image(systemName: "bell.fill").font(.title3)
                    }
                    .badge(store.unreadNotificationCount)
                    .accessibilityLabel("Notifications")

                    NavigationLink(value: ManagerRoute.profile) {
                        Image(systemName: "person.crop.circle").font(.title3)
                    }
                    .accessibilityLabel("Profile")
                }
            }
        }
        .refreshable { await store.refreshAll() }
    }

    // MARK: Summary Cards

    private var summaryCardsSection: some View {
        VStack(spacing: Spacing.m) {
            HStack(spacing: Spacing.m) {
                summaryCard(
                    icon: "banknote",
                    title: "Total Loans",
                    value: "\(store.portfolioSummary.totalLoans)",
                    subtitle: "\(store.portfolioSummary.activeLoans) active",
                    accent: .lmsAccent
                )
                summaryCard(
                    icon: "indianrupeesign.circle",
                    title: "Disbursed",
                    value: Formatting.currency(store.portfolioSummary.totalDisbursement),
                    subtitle: "Total disbursement",
                    accent: .lmsSuccess
                )
            }
            HStack(spacing: Spacing.m) {
                summaryCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Collection",
                    value: Formatting.percent(store.portfolioSummary.collectionEfficiency, fractionDigits: 1),
                    subtitle: "Efficiency rate",
                    accent: .lmsInfo
                )
                summaryCard(
                    icon: "exclamationmark.triangle",
                    title: "NPA Ratio",
                    value: Formatting.percent(store.portfolioSummary.npaRatio, fractionDigits: 1),
                    subtitle: "\(store.portfolioSummary.overdueLoans) overdue",
                    accent: .lmsDanger
                )
            }
        }
        .padding(.horizontal, Spacing.m)
    }

    private func summaryCard(icon: String, title: String, value: String,
                              subtitle: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(accent)
                    .frame(width: 32, height: 32)
                    .background(accent.opacity(0.12),
                                 in: RoundedRectangle(cornerRadius: CornerRadius.small))
                Spacer()
            }
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    // MARK: Portfolio Health

    private var portfolioHealthSection: some View {
        SectionCard(title: "Portfolio Health") {
            let npa = store.portfolioSummary.npaRatio
            let atRisk = store.atRiskPercent
            let healthy = max(0, 1.0 - npa - atRisk)

            VStack(alignment: .leading, spacing: Spacing.s) {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.lmsSuccess)
                            .frame(width: geo.size.width * healthy)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.lmsWarning)
                            .frame(width: geo.size.width * atRisk)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.lmsDanger)
                            .frame(width: geo.size.width * npa)
                    }
                }
                .frame(height: 12)

                HStack(spacing: Spacing.l) {
                    healthLegend(color: .lmsSuccess, label: "Healthy", value: Formatting.percent(healthy, fractionDigits: 0))
                    healthLegend(color: .lmsWarning, label: "At Risk", value: Formatting.percent(atRisk, fractionDigits: 0))
                    healthLegend(color: .lmsDanger, label: "NPA", value: Formatting.percent(npa, fractionDigits: 1))
                }
            }
        }
        .padding(.horizontal, Spacing.m)
    }

    private func healthLegend(color: Color, label: String, value: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.caption.weight(.semibold)).foregroundStyle(.primary)
        }
    }

    // MARK: Loan Categories

    private var loanCategoriesSection: some View {
        SectionCard(title: "Loan Categories") {
            ForEach(store.loanCategories) { category in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: loanTypeIcon(category.loanType))
                        .font(.body.weight(.medium))
                        .foregroundStyle(loanTypeColor(category.loanType))
                        .frame(width: 28, height: 28)
                        .background(loanTypeColor(category.loanType).opacity(0.12),
                                     in: RoundedRectangle(cornerRadius: CornerRadius.small))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.loanType.rawValue.capitalized)
                            .font(.subheadline.weight(.medium))
                        Text("\(category.count) loans • \(category.amountText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(Formatting.percent(category.percentage, fractionDigits: 0))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                // Progress bar
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.lmsGray5)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(loanTypeColor(category.loanType))
                                .frame(width: geo.size.width * category.percentage)
                        }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, Spacing.m)
    }

    // MARK: Collection Efficiency

    private var collectionSection: some View {
        SectionCard(title: "Collection Health") {
            HStack(spacing: Spacing.l) {
                VStack(spacing: Spacing.s) {
                    CircularProgress(progress: store.portfolioSummary.recoveryRate, color: .lmsSuccess, lineWidth: 7, size: 72)
                    Text("Recovery Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: Spacing.s) {
                    CircularProgress(progress: store.portfolioSummary.paidEMIPercent, color: .lmsAccent, lineWidth: 7, size: 72)
                    Text("Paid EMI %")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: Spacing.s) {
                    Text("\(store.portfolioSummary.overdueLoans)")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.lmsDanger)
                    Text("Overdue\nLoans")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Spacing.m)
    }

    // MARK: NPA Monitoring

    private var npaSection: some View {
        SectionCard(title: "NPA Monitoring") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NPA Ratio")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(Formatting.percent(store.portfolioSummary.npaRatio, fractionDigits: 2))
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.lmsDanger)
                }
                Spacer()
                NavigationLink(value: ManagerRoute.riskAlerts) {
                    Label("View Alerts", systemImage: "exclamationmark.shield")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(.lmsDanger)
                .controlSize(.small)
            }

            if store.unreadRiskAlertCount > 0 {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.lmsWarning)
                    Text("\(store.unreadRiskAlertCount) unread risk alerts require attention")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(Spacing.sm)
                .background(Color.lmsWarning.opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            }
        }
        .padding(.horizontal, Spacing.m)
    }



    // MARK: Greeting

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Branch: \(store.branchName)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.m)
    }

    // MARK: Officer Performance

    private var officerPerformanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("Officer Performance")
                    .font(.lmsHeadline)
                Spacer()
                NavigationLink(value: ManagerRoute.officerPerformance) {
                    Text("See All")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.lmsAccent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.m)

            VStack(spacing: 0) {
                ForEach(Array(store.officerPerformance.prefix(3).enumerated()), id: \.element.id) { index, officer in
                    NavigationLink(value: ManagerRoute.officerDetail(officer.name)) {
                        HStack(spacing: Spacing.sm) {
                            AvatarView(initials: officer.initials, size: 40)

                            Text(officer.name)
                                .font(.body)
                                .foregroundStyle(.primary)

                            Spacer()

                            if officer.avgDecisionTime != "—" && officer.avgDecisionTime != "-" {
                                Text(officer.avgDecisionTime)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < store.officerPerformance.prefix(3).count - 1 {
                        Divider()
                            .padding(.leading, 56 + Spacing.m)
                    }
                }
            }
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, Spacing.m)
        }
    }

    // MARK: Helpers

    private func loanTypeIcon(_ type: LoanType) -> String {
        switch type {
        case .home: "house"
        case .personal: "person"
        case .business: "building.2"
        case .vehicle: "car"
        case .education: "graduationcap"
        }
    }

    private func loanTypeColor(_ type: LoanType) -> Color {
        switch type {
        case .home: .lmsAccent
        case .personal: .purple
        case .business: .lmsWarning
        case .vehicle: .lmsSuccess
        case .education: .lmsInfo
        }
    }
}

#Preview {
    ManagerNavigationStack {
        ManagerPortfolioView()
    }
    .environment(ManagerStore.preview)
    .environment(SessionStore())
}
