import SwiftUI

struct HomeDashboardView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var viewModel = DashboardViewModel()
    @State private var repaymentViewModel = RepaymentViewModel()
    @State private var selectedLoanID: UUID?
    @State private var emiToPay: EMI?
    @State private var showSupportSheet = false

    var body: some View {
        ScrollView {
            mainContent
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
        .sheet(item: $emiToPay, content: paySheet)
        .sheet(isPresented: $showSupportSheet) {
            NavigationStack { BorrowerMessagingView() }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
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
    }

    private func paySheet(emi: EMI) -> some View {
        let loan = viewModel.activeLoans.first(where: { $0.id == selectedLoanID })
        return PayEMISheet(emi: emi, loan: loan) {
            Task {
                await repaymentViewModel.payEMI(emi)
                emiToPay = nil
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    @ViewBuilder
    private var contentSections: some View {
        let pendingApps = viewModel.applications.filter { $0.status != .disbursed && $0.status != .closed }
        if !pendingApps.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Pending Applications")
                        .font(.title3.bold())
                    Spacer()
                }
                .padding(.horizontal, Spacing.m)
                
                ForEach(pendingApps) { app in
                    NavigationLink(destination: ApplicationTrackingView()) {
                        statusTrackerCard(app)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, Spacing.m)
                    .padding(.bottom, Spacing.s)
                }
            }
            .padding(.top, Spacing.s)
        }

        if !viewModel.activeLoans.isEmpty {
            HStack(alignment: .firstTextBaseline) {
                Text("Active Loans")
                    .font(.title3.bold())
                Spacer()
                if viewModel.activeLoans.count > 1 {
                    Text("\(activeLoanIndex + 1) of \(viewModel.activeLoans.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.s)

            if viewModel.activeLoans.count > 1 {
                TabView(selection: $selectedLoanID) {
                    ForEach(viewModel.activeLoans) { loan in
                        NavigationLink(destination: RepaymentDashboardView(loan: loan)) {
                            loanHeroCard(loan)
                                .padding(.horizontal, Spacing.m)
                                .padding(.bottom, Spacing.xl)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .tag(loan.id as UUID?)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                .frame(height: 250)
            } else if let loan = viewModel.activeLoans.first {
                NavigationLink(destination: RepaymentDashboardView(loan: loan)) {
                    loanHeroCard(loan)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, Spacing.m)
            }
            
            // Apply for a New Loan Button (as seen in screenshot)
            NavigationLink(destination: NewLoanApplicationView()) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Apply for a New Loan")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.m)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.s)
        }
    }

    private var activeLoanIndex: Int {
        guard let id = selectedLoanID,
              let idx = viewModel.activeLoans.firstIndex(where: { $0.id == id }) else { return 0 }
        return idx
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
        let nextEMI = nextUpcomingEMI(for: loan)

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

            if let nextEMI {
                Button {
                    emiToPay = nextEMI
                } label: {
                    HStack {
                        Image(systemName: nextEMI.status == .overdue ? "exclamationmark.circle.fill" : "creditcard.fill")
                        Text(nextEMI.status == .overdue ? "Pay Overdue EMI" : "Pay Next EMI")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(Formatting.currency(nextEMI.totalAmount))
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(nextEMI.status == .overdue ? .lmsDanger : .accentColor)
                .controlSize(.large)
                .buttonBorderShape(.roundedRectangle(radius: CornerRadius.button))
            }
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    private func nextUpcomingEMI(for loan: Loan) -> EMI? {
        let schedule = (selectedLoanID == loan.id && !repaymentViewModel.emiSchedule.isEmpty)
            ? repaymentViewModel.emiSchedule
            : loan.emiSchedule
        return schedule
            .filter { $0.status == .upcoming || $0.status == .overdue }
            .sorted { $0.dueDate < $1.dueDate }
            .first
    }

    // MARK: - Status Tracker
    private func statusTrackerCard(_ app: LoanApplication) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("\(app.loanType.rawValue.capitalized) Loan Application")
                        .font(.subheadline.weight(.semibold))
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
                            emiToPay = emi
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
        Button(action: onPay) {
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
                        .foregroundStyle(.primary)
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
                    StatusBadge("Overdue", tone: .danger)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                case .upcoming:
                    StatusBadge("Upcoming", tone: .info)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(Spacing.sm)
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(emi.status == .paid)
    }

    private var statusColor: Color {
        switch emi.status {
        case .paid:     return .lmsSuccess
        case .overdue:  return .lmsDanger
        case .upcoming: return .accentColor
        }
    }
}

// MARK: - Pay EMI Sheet
struct PayEMISheet: View {
    let emi: EMI
    let loan: Loan?
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    @State private var didSucceed = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if didSucceed {
                    successContent
                } else {
                    paymentContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.lmsBackground.ignoresSafeArea())
            .navigationTitle(didSucceed ? "Payment Successful" : "Pay EMI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(didSucceed ? "Done" : "Cancel") { dismiss() }
                }
            }
        }
    }

    private var paymentContent: some View {
        VStack(spacing: Spacing.l) {
            VStack(spacing: Spacing.xs) {
                Text("Amount Due")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(Formatting.currency(emi.totalAmount))
                    .font(.lmsHeroAmount)
                Text("Installment #\(emi.installmentNumber) • Due \(Formatting.date(emi.dueDate))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, Spacing.l)

            VStack(spacing: 0) {
                breakdownRow("Principal", Formatting.currency(emi.principalComponent))
                Divider().padding(.leading, Spacing.m)
                breakdownRow("Interest", Formatting.currency(emi.interestComponent))
                if let loan {
                    Divider().padding(.leading, Spacing.m)
                    breakdownRow("Loan", "\(loan.loanType.rawValue.capitalized) Loan")
                }
            }
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .padding(.horizontal, Spacing.m)

            HStack(spacing: Spacing.s) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.secondary)
                Text("Secure payment via UPI")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            PrimaryButton(
                "Pay \(Formatting.currency(emi.totalAmount))",
                isLoading: isProcessing
            ) {
                Task { await processPayment() }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.m)
        }
    }

    private var successContent: some View {
        VStack(spacing: Spacing.l) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.lmsSuccess.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Color.lmsSuccess)
            }
            VStack(spacing: Spacing.xs) {
                Text("Payment Successful")
                    .font(.title2.weight(.semibold))
                Text("\(Formatting.currency(emi.totalAmount)) paid towards installment #\(emi.installmentNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.l)
            }
            Spacer()
            PrimaryButton("Done") { dismiss() }
                .padding(.horizontal, Spacing.m)
                .padding(.bottom, Spacing.m)
        }
    }

    private func breakdownRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
        .padding(Spacing.m)
    }

    private func processPayment() async {
        isProcessing = true
        try? await Task.sleep(for: .milliseconds(900))
        onConfirm()
        isProcessing = false
        withAnimation(.easeInOut) { didSucceed = true }
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
