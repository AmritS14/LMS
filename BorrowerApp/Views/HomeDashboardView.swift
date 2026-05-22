import SwiftUI

struct HomeDashboardView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    
    @State private var viewModel = DashboardViewModel()
    @State private var repaymentViewModel = RepaymentViewModel()
    @State private var selectedLoanID: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.lmsBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.ml) {
                        if viewModel.isLoading {
                            ProgressView().padding(.top, 40)
                        } else if let error = viewModel.errorMessage {
                            Text(error).foregroundStyle(Color.lmsDanger).padding()
                        } else {
                            if viewModel.activeLoans.isEmpty && viewModel.applications.isEmpty {
                                emptyState.padding(.horizontal)
                            } else {
                                let pendingApps = viewModel.applications.filter { $0.status != .disbursed && $0.status != .closed }
                                if let app = pendingApps.first {
                                    statusTrackerCard(app).padding(.horizontal)
                                }

                                if !viewModel.activeLoans.isEmpty {
                                    HStack(alignment: .bottom) {
                                        Text("Active Loans")
                                            .font(.lmsHeadline)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if viewModel.activeLoans.count > 1 {
                                            HStack(spacing: Spacing.xs_s) {
                                                ForEach(viewModel.activeLoans) { loan in
                                                    Circle()
                                                        .fill(selectedLoanID == loan.id ? Color.lmsAccent : Color.lmsGray4)
                                                        .frame(width: 6, height: 6)
                                                        .animation(.easeInOut, value: selectedLoanID)
                                                }
                                            }
                                            .padding(.bottom, Spacing.xs_s)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, Spacing.s)
                                    .padding(.bottom, Spacing.xs)

                                    if viewModel.activeLoans.count > 1 {
                                        TabView(selection: $selectedLoanID) {
                                            ForEach(viewModel.activeLoans) { loan in
                                                VStack {
                                                    loanHeroCard(loan)
                                                    Spacer(minLength: 0) // Push to top
                                                }
                                                .tag(loan.id as UUID?)
                                                .padding(.horizontal)
                                            }
                                        }
                                        .tabViewStyle(.page(indexDisplayMode: .never))
                                        .frame(height: 250)
                                        
                                        if let selectedID = selectedLoanID,
                                           let selectedLoan = viewModel.activeLoans.first(where: { $0.id == selectedID }) {
                                            emiListSection(for: selectedLoan)
                                                .padding(.horizontal)
                                        }
                                    } else if let loan = viewModel.activeLoans.first {
                                        VStack(spacing: Spacing.l) {
                                            loanHeroCard(loan)
                                            emiListSection(for: loan)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, Spacing.xl)
                }
            }
            .navigationTitle("Dashboard")
//            .navigationBarTitleDisplayMode(.large)
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: BorrowerProfileView().toolbar(.hidden, for: .tabBar)) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                    }
                }
            }
            .task {
                if let env = env, let userID = session.currentUser?.id {
                    await viewModel.fetchDashboardData(loanService: env.loans, borrowerID: userID)
                    if let first = viewModel.activeLoans.first {
                        selectedLoanID = first.id
                        await repaymentViewModel.loadRepaymentData(loanService: env.loans, loan: first)
                    }
                }
            }
            .onChange(of: selectedLoanID) { _, newID in
                if let newID = newID, let env = env, let loan = viewModel.activeLoans.first(where: { $0.id == newID }) {
                    Task {
                        await repaymentViewModel.loadRepaymentData(loanService: env.loans, loan: loan)
                    }
                }
            }
        }
    }

    // MARK: - Loan Hero Card
    func loanHeroCard(_ loan: Loan) -> some View {
        let outstanding = loan.outstandingBalance
        let paidCount = loan.emiSchedule.filter { $0.status == .paid }.count
        let total = loan.tenureMonths
        let progress = total > 0 ? Double(paidCount) / Double(total) : 0
        let emiAmount = EMICalculator.calculate(principal: loan.principal, annualInterestRate: loan.interestRate, tenureMonths: loan.tenureMonths, startDate: loan.disbursementDate).monthlyInstallment

        return VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                Label("\(loan.loanType.rawValue.capitalized) Loan", systemImage: icon(for: loan.loanType))
                    .font(.lmsSubheadline).bold()
                    .foregroundStyle(Color.lmsAccent)
                Spacer()
                StatusBadge(ApplicationStatus.disbursed.rawValue.capitalized, tone: .success)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Outstanding Balance")
                    .font(.lmsCaption)
                    .foregroundStyle(.secondary)
                Text(Formatting.currency(outstanding))
                    .font(.lmsHeroAmount)
            }

            VStack(alignment: .leading, spacing: Spacing.xs_s) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.lmsFill)
                            .frame(height: 8)
                        Capsule()
                            .fill(Color.lmsAccent)
                            .frame(width: max(8, geo.size.width * progress), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(paidCount) of \(total) EMIs paid")
                        .font(.lmsCaption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))% complete")
                        .font(.lmsCaption).bold()
                        .foregroundStyle(Color.lmsAccent)
                }
            }

            Divider()

            HStack {
                stat(title: "Monthly EMI", value: Formatting.currency(emiAmount))
                Divider().frame(height: 32)
                stat(title: "Rate", value: Formatting.percent(loan.interestRate))
                Divider().frame(height: 32)
                stat(title: "Tenure", value: "\(loan.tenureMonths)m")
            }
        }
        .padding()
        .background(Color.lmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }

    // MARK: - Status Tracker Card
    func statusTrackerCard(_ app: LoanApplication) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("\(app.loanType.rawValue.capitalized) Loan Application")
                        .font(.lmsHeadline)
                    Text(Formatting.currency(app.requestedAmount))
                        .font(.lmsSubheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: icon(for: app.loanType))
                    .foregroundStyle(Color.lmsAccent)
                    .font(.title2)
            }
            if app.status == .rejected {
                HStack(spacing: Spacing.input) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.lmsDanger).font(.title2)
                    VStack(alignment: .leading) {
                        Text("Application Rejected").bold()
                    }
                }
            } else {
                HStack(spacing: 0) {
                    let order: [ApplicationStatus] = [.draft, .submitted, .underReview, .approved, .disbursed]
                    ForEach(Array(order.enumerated()), id: \.offset) { idx, step in
                        let isDone = isStepDone(current: app.status, step: step, order: order)
                        let isCurrent = app.status == step

                        VStack(spacing: Spacing.xs) {
                            ZStack {
                                Circle()
                                    .fill(isDone || isCurrent ? Color.lmsAccent : Color.lmsFill)
                                    .frame(width: 28, height: 28)
                                if isDone {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                } else if isCurrent {
                                    Circle().fill(.white).frame(width: 10, height: 10)
                                }
                            }
                            Text(step.rawValue.capitalized)
                                .font(.system(size: 9, weight: isCurrent ? .bold : .regular))
                                .foregroundStyle(isCurrent ? Color.lmsAccent : .secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(width: 55)
                        }

                        if idx < order.count - 1 {
                            Rectangle()
                                .fill(isDone ? Color.lmsAccent : Color.lmsFill)
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                                .offset(y: -10)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.lmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }

    // MARK: - EMI List
    func emiListSection(for loan: Loan) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Upcoming EMIs")
                .font(.lmsHeadline)
                .padding(.leading, Spacing.xs)

            let scheduleToUse = (selectedLoanID == loan.id) ? repaymentViewModel.emiSchedule : loan.emiSchedule
            let pendingEMIs = scheduleToUse.filter { $0.status == .upcoming || $0.status == .overdue }.prefix(3)

            if pendingEMIs.isEmpty {
                Text("No upcoming payments.")
                    .font(.lmsSubheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(pendingEMIs) { emi in
                    EMIRow(emi: emi) {
                        Task { await repaymentViewModel.payEMI(emi) }
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.lmsHeroIcon)
                .foregroundStyle(.secondary)
            Text("No active loans")
                .font(.lmsHeadline)
            Text("Go to the Apply tab to calculate and submit a loan application.")
                .font(.lmsSubheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color.lmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }

    // MARK: - Helpers
    func stat(title: String, value: String) -> some View {
        VStack(spacing: Spacing.xxs) {
            Text(value).font(.lmsSubheadline).bold()
            Text(title).font(.lmsCaption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    func isStepDone(current: ApplicationStatus, step: ApplicationStatus, order: [ApplicationStatus]) -> Bool {
        guard let ci = order.firstIndex(of: current),
              let si = order.firstIndex(of: step) else { return false }
        return si < ci
    }

    func icon(for type: LoanType) -> String {
        switch type {
        case .personal: return "person.fill"
        case .home: return "house.fill"
        case .vehicle: return "car.fill"
        case .education: return "graduationcap.fill"
        case .business: return "briefcase.fill"
        }
    }
}

// MARK: - EMI Row Card
struct EMIRow: View {
    let emi: EMI
    let onPay: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text("\(emi.installmentNumber)")
                    .font(.lmsSubheadline).bold()
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(Formatting.currency(emi.totalAmount)).font(.lmsSubheadline).bold()
                Text("Due \(Formatting.date(emi.dueDate))")
                    .font(.lmsCaption).foregroundStyle(.secondary)
            }

            Spacer()

            switch emi.status {
            case .paid:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.lmsSuccess).font(.title3)
            case .overdue:
                Button("Pay Now", action: onPay)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.lmsDanger)
                    .controlSize(.small)
            case .upcoming:
                StatusBadge("Upcoming", tone: .info)
            }
        }
        .padding(14)
        .background(Color.lmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
    }

    var statusColor: Color {
        switch emi.status {
        case .paid: return Color.lmsSuccess
        case .overdue: return Color.lmsDanger
        case .upcoming: return Color.lmsAccent
        }
    }
}

#Preview {
    HomeDashboardView()
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
