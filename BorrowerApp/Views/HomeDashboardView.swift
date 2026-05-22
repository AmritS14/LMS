import SwiftUI

struct HomeDashboardView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    
    @State private var viewModel = DashboardViewModel()
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
                                                NavigationLink(destination: RepaymentDashboardView(loan: loan)) {
                                                    VStack {
                                                        loanHeroCard(loan)
                                                        Spacer(minLength: 0)
                                                    }
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .tag(loan.id as UUID?)
                                                .padding(.horizontal)
                                            }
                                        }
                                        .tabViewStyle(.page(indexDisplayMode: .never))
                                        .frame(height: 250)
                                    } else if let loan = viewModel.activeLoans.first {
                                        NavigationLink(destination: RepaymentDashboardView(loan: loan)) {
                                            loanHeroCard(loan)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal)
                                    }
                                }
                                
                                NavigationLink(destination: NewLoanApplicationView()) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                        Text("Apply for a New Loan")
                                            .font(.headline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundStyle(.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .padding(.horizontal)
                                .padding(.top, 16)
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
                    NavigationLink(destination: BorrowerProfileView()) {
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


    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No active loans")
                .font(.headline)
            Text("You don't have any active loans or pending applications.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                
            NavigationLink(destination: NewLoanApplicationView()) {
                Text("Calculate & Apply")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 8)
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
