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
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if viewModel.isLoading {
                            ProgressView().padding(.top, 40)
                        } else if let error = viewModel.errorMessage {
                            Text(error).foregroundStyle(.red).padding()
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
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if viewModel.activeLoans.count > 1 {
                                            HStack(spacing: 6) {
                                                ForEach(viewModel.activeLoans) { loan in
                                                    Circle()
                                                        .fill(selectedLoanID == loan.id ? Color.blue : Color(.systemGray4))
                                                        .frame(width: 6, height: 6)
                                                        .animation(.easeInOut, value: selectedLoanID)
                                                }
                                            }
                                            .padding(.bottom, 6)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                    .padding(.bottom, 4)

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
                                        VStack(spacing: 24) {
                                            loanHeroCard(loan)
                                            emiListSection(for: loan)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 32)
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

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("\(loan.loanType.rawValue.capitalized) Loan", systemImage: icon(for: loan.loanType))
                    .font(.subheadline).bold()
                    .foregroundStyle(.blue)
                Spacer()
                StatusPill(status: .disbursed)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Outstanding Balance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Formatting.currency(outstanding))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
            }

            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemFill))
                            .frame(height: 8)
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: max(8, geo.size.width * progress), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(paidCount) of \(total) EMIs paid")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))% complete")
                        .font(.caption).bold()
                        .foregroundStyle(.blue)
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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.07), radius: 10, y: 3)
    }

    // MARK: - Status Tracker Card
    func statusTrackerCard(_ app: LoanApplication) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(app.loanType.rawValue.capitalized) Loan Application")
                        .font(.headline)
                    Text(Formatting.currency(app.requestedAmount))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: icon(for: app.loanType))
                    .foregroundStyle(.blue)
                    .font(.title2)
            }
            if app.status == .rejected {
                HStack(spacing: 10) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red).font(.title2)
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

                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(isDone || isCurrent ? Color.blue : Color(.systemFill))
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
                                .foregroundStyle(isCurrent ? .blue : .secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(width: 55)
                        }

                        if idx < order.count - 1 {
                            Rectangle()
                                .fill(isDone ? Color.blue : Color(.systemFill))
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                                .offset(y: -10)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - EMI List
    func emiListSection(for loan: Loan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming EMIs")
                .font(.headline)
                .padding(.leading, 4)

            let scheduleToUse = (selectedLoanID == loan.id) ? repaymentViewModel.emiSchedule : loan.emiSchedule
            let pendingEMIs = scheduleToUse.filter { $0.status == .upcoming || $0.status == .overdue }.prefix(3)

            if pendingEMIs.isEmpty {
                Text("No upcoming payments.")
                    .font(.subheadline)
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
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No active loans")
                .font(.headline)
            Text("Go to the Apply tab to calculate and submit a loan application.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Helpers
    func stat(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline).bold()
            Text(title).font(.caption2).foregroundStyle(.secondary)
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

// MARK: - Status Pill
struct StatusPill: View {
    let status: ApplicationStatus
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(statusColor.opacity(0.12))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }
    var statusColor: Color {
        switch status {
        case .disbursed, .approved, .closed: return .green
        case .rejected: return .red
        case .recommended: return .blue
        default: return .orange
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
                    .font(.subheadline).bold()
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(Formatting.currency(emi.totalAmount)).font(.subheadline).bold()
                Text("Due \(Formatting.date(emi.dueDate))")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            switch emi.status {
            case .paid:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green).font(.title3)
            case .overdue:
                Button("Pay Now", action: onPay)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.small)
            case .upcoming:
                Text("Upcoming")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color(.systemFill))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 1)
    }

    var statusColor: Color {
        switch emi.status {
        case .paid: return .green
        case .overdue: return .red
        case .upcoming: return .blue
        }
    }
}
