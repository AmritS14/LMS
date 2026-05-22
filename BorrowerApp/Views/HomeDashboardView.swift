import SwiftUI

struct HomeDashboardView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var viewModel = DashboardViewModel()
    @State private var repaymentViewModel = RepaymentViewModel()
    @State private var selectedLoanID: UUID?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.ml) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, Spacing.xl)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Couldn't Load Dashboard",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if viewModel.activeLoans.isEmpty && viewModel.applications.isEmpty {
                    emptyState
                        .padding(.horizontal, Spacing.m)
                        .padding(.top, Spacing.m)
                } else {
                    contentSections
                }
            }
            .padding(.bottom, Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(Color.lmsBackground.ignoresSafeArea())
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .task { await loadData() }
        .onChange(of: selectedLoanID) { _, newID in
            guard let newID,
                  let env,
                  let loan = viewModel.activeLoans.first(where: { $0.id == newID }) else { return }
            Task { await repaymentViewModel.loadRepaymentData(loanService: env.loans, loan: loan) }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var contentSections: some View {
        let pendingApps = viewModel.applications.filter { $0.status != .disbursed && $0.status != .closed }
        if let app = pendingApps.first {
            statusTrackerCard(app)
                .padding(.horizontal, Spacing.m)
        }

        if !viewModel.activeLoans.isEmpty {
            HStack(alignment: .firstTextBaseline) {
                Text("Active Loans")
                    .font(.lmsHeadline)
                Spacer()
                if viewModel.activeLoans.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(viewModel.activeLoans) { loan in
                            Circle()
                                .fill(selectedLoanID == loan.id ? Color.accentColor : Color.lmsGray4)
                                .frame(width: 6, height: 6)
                                .animation(.easeInOut, value: selectedLoanID)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.s)

            if viewModel.activeLoans.count > 1 {
                TabView(selection: $selectedLoanID) {
                    ForEach(viewModel.activeLoans) { loan in
                        loanHeroCard(loan)
                            .padding(.horizontal, Spacing.m)
                            .tag(loan.id as UUID?)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 260)

                if let selectedID = selectedLoanID,
                   let selectedLoan = viewModel.activeLoans.first(where: { $0.id == selectedID }) {
                    emiListSection(for: selectedLoan)
                        .padding(.horizontal, Spacing.m)
                }
            } else if let loan = viewModel.activeLoans.first {
                VStack(spacing: Spacing.l) {
                    loanHeroCard(loan)
                    emiListSection(for: loan)
                }
                .padding(.horizontal, Spacing.m)
            }
        }
    }

    // MARK: - Loan Hero Card
    private func loanHeroCard(_ loan: Loan) -> some View {
        let outstanding = loan.outstandingBalance
        let paidCount = loan.emiSchedule.filter { $0.status == .paid }.count
        let total = loan.tenureMonths
        let progress = total > 0 ? Double(paidCount) / Double(total) : 0
        let emiAmount = EMICalculator.calculate(
            principal: loan.principal,
            annualInterestRate: loan.interestRate,
            tenureMonths: loan.tenureMonths,
            startDate: loan.disbursementDate
        ).monthlyInstallment

        return VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                Label("\(loan.loanType.rawValue.capitalized) Loan", systemImage: icon(for: loan.loanType))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
                Spacer()
                StatusBadge(ApplicationStatus.disbursed.rawValue.capitalized, tone: .success)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Outstanding Balance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(Formatting.currency(outstanding))
                    .font(.lmsHeroAmount)
                    .contentTransition(.numericText())
            }

            VStack(alignment: .leading, spacing: Spacing.xs_s) {
                ProgressView(value: progress)
                    .tint(.accentColor)
                HStack {
                    Text("\(paidCount) of \(total) EMIs paid")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))% complete")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                }
            }

            Divider()

            HStack {
                stat(title: "Monthly EMI", value: Formatting.currency(emiAmount))
                Divider().frame(height: 32)
                stat(title: "Rate", value: Formatting.percent(loan.interestRate))
                Divider().frame(height: 32)
                stat(title: "Tenure", value: "\(loan.tenureMonths) mo")
            }
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    // MARK: - Status Tracker
    private func statusTrackerCard(_ app: LoanApplication) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("\(app.loanType.rawValue.capitalized) Loan Application")
                        .font(.lmsHeadline)
                    Text(Formatting.currency(app.requestedAmount))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: icon(for: app.loanType))
                    .foregroundStyle(.tint)
                    .font(.title2)
            }

            if app.status == .rejected {
                Label("Application Rejected", systemImage: "xmark.circle.fill")
                    .foregroundStyle(Color.lmsDanger)
                    .font(.subheadline.weight(.semibold))
            } else {
                HStack(spacing: 0) {
                    let order: [ApplicationStatus] = [.draft, .submitted, .underReview, .approved, .disbursed]
                    ForEach(Array(order.enumerated()), id: \.offset) { idx, step in
                        let isDone = isStepDone(current: app.status, step: step, order: order)
                        let isCurrent = app.status == step

                        VStack(spacing: Spacing.xs) {
                            ZStack {
                                Circle()
                                    .fill(isDone || isCurrent ? Color.accentColor : Color.lmsFill)
                                    .frame(width: 26, height: 26)
                                if isDone {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                } else if isCurrent {
                                    Circle().fill(.white).frame(width: 9, height: 9)
                                }
                            }
                            Text(step.rawValue.capitalized)
                                .font(.caption2.weight(isCurrent ? .semibold : .regular))
                                .foregroundStyle(isCurrent ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(width: 60)
                        }

                        if idx < order.count - 1 {
                            Rectangle()
                                .fill(isDone ? Color.accentColor : Color.lmsFill)
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                                .offset(y: -10)
                        }
                    }
                }
            }
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    // MARK: - EMI List
    private func emiListSection(for loan: Loan) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Upcoming EMIs")
                    .font(.lmsHeadline)
                Spacer()
                NavigationLink("View All") {
                    RepaymentDashboardView(loan: loan)
                }
                .font(.subheadline)
            }

            let scheduleToUse = (selectedLoanID == loan.id) ? repaymentViewModel.emiSchedule : loan.emiSchedule
            let pendingEMIs = scheduleToUse.filter { $0.status == .upcoming || $0.status == .overdue }.prefix(3)

            if pendingEMIs.isEmpty {
                Text("No upcoming payments.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.m)
                    .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            } else {
                VStack(spacing: Spacing.s) {
                    ForEach(pendingEMIs) { emi in
                        EMIRow(emi: emi) {
                            Task { await repaymentViewModel.payEMI(emi) }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Active Loans", systemImage: "doc.text.magnifyingglass")
        } description: {
            Text("Go to the Apply tab to calculate and submit a loan application.")
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.l)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    // MARK: - Helpers
    private func stat(title: String, value: String) -> some View {
        VStack(spacing: Spacing.xxs) {
            Text(value).font(.subheadline.weight(.semibold))
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func isStepDone(current: ApplicationStatus, step: ApplicationStatus, order: [ApplicationStatus]) -> Bool {
        guard let ci = order.firstIndex(of: current),
              let si = order.firstIndex(of: step) else { return false }
        return si < ci
    }

    private func icon(for type: LoanType) -> String {
        switch type {
        case .personal:  return "person.fill"
        case .home:      return "house.fill"
        case .vehicle:   return "car.fill"
        case .education: return "graduationcap.fill"
        case .business:  return "briefcase.fill"
        }
    }

    private func loadData() async {
        guard let env, let userID = session.currentUser?.id else { return }
        await viewModel.fetchDashboardData(loanService: env.loans, borrowerID: userID)
        if let first = viewModel.activeLoans.first {
            selectedLoanID = first.id
            await repaymentViewModel.loadRepaymentData(loanService: env.loans, loan: first)
        }
    }
}

// MARK: - EMI Row Card
struct EMIRow: View {
    let emi: EMI
    let onPay: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Text("\(emi.installmentNumber)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(Formatting.currency(emi.totalAmount))
                    .font(.subheadline.weight(.semibold))
                Text("Due \(Formatting.date(emi.dueDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            switch emi.status {
            case .paid:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.lmsSuccess)
                    .font(.title3)
            case .overdue:
                Button("Pay Now", action: onPay)
                    .buttonStyle(.borderedProminent)
                    .tint(.lmsDanger)
                    .controlSize(.small)
            case .upcoming:
                StatusBadge("Upcoming", tone: .info)
            }
        }
        .padding(Spacing.sm)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }

    private var statusColor: Color {
        switch emi.status {
        case .paid:     return .lmsSuccess
        case .overdue:  return .lmsDanger
        case .upcoming: return .accentColor
        }
    }
}

#Preview {
    NavigationStack { HomeDashboardView() }
        .environment(SessionStore(
            currentUser: MockAuthService.seedBorrower,
            borrowerProfile: MockAuthService.seedBorrowerProfile
        ))
        .environment(\.appEnvironment, AppEnvironment(
            auth: MockAuthService(),
            loans: MockLoanService(),
            documents: MockDocumentService(),
            notifications: MockNotificationService(),
            messaging: MockMessagingService(),
            keychain: MockKeychainService()
        ))
}
