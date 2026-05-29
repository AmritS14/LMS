import SwiftUI

// MARK: - Tab 2: Portfolio

struct ManagerPortfolioView: View {
    @Environment(ManagerStore.self) private var store
    @State private var showFilters = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.l) {
                summaryCardsSection
                portfolioHealthSection
                loanCategoriesSection
                collectionSection
                npaSection
                branchPerformanceSection
            }
            .padding(.vertical, Spacing.m)
        }
        .background(Color.lmsBackground)
        .navigationTitle("Portfolio")
        .toolbarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                }
                .accessibilityLabel("Filters")
            }
        }
        .sheet(isPresented: $showFilters) {
            portfolioFilterSheet
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
            let healthy = 1.0 - store.portfolioSummary.npaRatio - 0.08 // 8% at-risk
            let atRisk = 0.08
            let npa = store.portfolioSummary.npaRatio

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

    // MARK: Branch Performance

    private var branchPerformanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Branch Performance",
                          actionTitle: "Officers") {
                // navigation handled via route
            }
            .padding(.horizontal, Spacing.m)

            ForEach(store.branchPerformanceItems) { branch in
                HStack(spacing: Spacing.sm) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(branch.branchName)
                            .font(.subheadline.weight(.medium))
                        Text("\(branch.totalApplications) applications")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(Formatting.percent(branch.approvalRate, fractionDigits: 0))
                            .font(.subheadline.weight(.semibold))
                        Text(branch.avgDecisionTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(Spacing.m)
                .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                .padding(.horizontal, Spacing.m)
            }
        }
    }

    // MARK: Filters Sheet

    @MainActor
    private var portfolioFilterSheet: some View {
        NavigationStack {
            List {
                Section("Branch") {
                    ForEach(["All", "MG Road"], id: \.self) { branch in
                        Button {
                            store.selectedBranch = branch == "All" ? nil : branch
                        } label: {
                            HStack {
                                Text(branch)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if (store.selectedBranch ?? "All") == (branch == "All" ? (store.selectedBranch ?? "All") : branch) && branch != "All" {
                                    Image(systemName: "checkmark").foregroundStyle(Color.lmsAccent)
                                } else if branch == "All" && store.selectedBranch == nil {
                                    Image(systemName: "checkmark").foregroundStyle(Color.lmsAccent)
                                }
                            }
                        }
                    }
                }

                Section("Region") {
                    ForEach(["All", "South India", "North India", "West India"], id: \.self) { region in
                        Button {
                            store.selectedRegion = region == "All" ? nil : region
                        } label: {
                            HStack {
                                Text(region).foregroundStyle(.primary)
                                Spacer()
                                if (region == "All" && store.selectedRegion == nil) || store.selectedRegion == region {
                                    Image(systemName: "checkmark").foregroundStyle(Color.lmsAccent)
                                }
                            }
                        }
                    }
                }

                Section("Loan Type") {
                    Button {
                        store.selectedLoanTypeFilter = nil
                    } label: {
                        HStack {
                            Text("All").foregroundStyle(.primary)
                            Spacer()
                            if store.selectedLoanTypeFilter == nil {
                                Image(systemName: "checkmark").foregroundStyle(Color.lmsAccent)
                            }
                        }
                    }
                    ForEach(LoanType.allCases) { type in
                        Button {
                            store.selectedLoanTypeFilter = type
                        } label: {
                            HStack {
                                Text(type.rawValue.capitalized).foregroundStyle(.primary)
                                Spacer()
                                if store.selectedLoanTypeFilter == type {
                                    Image(systemName: "checkmark").foregroundStyle(Color.lmsAccent)
                                }
                            }
                        }
                    }
                }

                Section("Risk Level") {
                    ForEach(["All", "Low", "Medium", "High", "Critical"], id: \.self) { risk in
                        Button {
                            store.selectedRiskFilter = risk == "All" ? nil : risk
                        } label: {
                            HStack {
                                Text(risk).foregroundStyle(.primary)
                                Spacer()
                                if (risk == "All" && store.selectedRiskFilter == nil) || store.selectedRiskFilter == risk {
                                    Image(systemName: "checkmark").foregroundStyle(Color.lmsAccent)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showFilters = false }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        store.selectedBranch = nil
                        store.selectedRegion = nil
                        store.selectedLoanTypeFilter = nil
                        store.selectedRiskFilter = nil
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
        case .personal: .lmsInfo
        case .business: .lmsWarning
        case .vehicle: .lmsSuccess
        case .education: .lmsDanger
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
