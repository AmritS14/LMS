import SwiftUI

// MARK: - Tab 2: Portfolio

struct ManagerPortfolioView: View {
    @Environment(ManagerStore.self) private var store
    @State private var showFilters = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.l) {
                greetingSection
                summaryCardsSection
                loanCategoriesSection
                officerPerformanceSection
                collectionSection
            }
            .padding(.vertical, Spacing.m)
        }
        .background(Color.lmsBackground)
        .navigationTitle("Dashboard")
        .toolbarTitleDisplayMode(.large)

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


    // MARK: Loan Categories

    private var loanCategoriesSection: some View {
        SectionCard(title: "Loan Categories") {
            ForEach(store.loanCategories) { category in
                VStack(spacing: Spacing.sm) {
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
        }
        .padding(.horizontal, Spacing.m)
    }

    // MARK: Collection Efficiency

    private var collectionSection: some View {
        NavigationLink(value: ManagerRoute.applicationsFiltered(.all)) {
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
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.m)
    }



    // MARK: Greeting

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(store.greetingDateText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
            HStack {
                Text("Officer Performance")
                    .font(.lmsHeadline)
                    .foregroundStyle(.primary)
                Spacer()
                NavigationLink(value: ManagerRoute.officerPerformance) {
                    Text("See All")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.lmsAccent)
                }
            }
            .padding(.horizontal, Spacing.m)

            VStack(spacing: 0) {
                ForEach(store.officerPerformance.prefix(3)) { officer in
                    NavigationLink(value: ManagerRoute.officerDetail(officer.name)) {
                        HStack(spacing: Spacing.sm) {
                            AvatarView(initials: officer.initials, size: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(officer.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(officer.avgDecisionTime)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text("Avg time")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, Spacing.s)
                    }
                    .buttonStyle(.plain)

                    if officer.id != store.officerPerformance.prefix(3).last?.id {
                        Divider().padding(.leading, 56 + Spacing.m)
                    }
                }
            }
            .padding(.vertical, Spacing.xs)
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .padding(.horizontal, Spacing.m)
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
