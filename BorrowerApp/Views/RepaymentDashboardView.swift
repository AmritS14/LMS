import SwiftUI

struct RepaymentDashboardView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    
    var loan: Loan?
    @State private var viewModel = RepaymentViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    if viewModel.isLoading {
                        ProgressView().padding()
                    } else if let error = viewModel.errorMessage {
                        Text(error).foregroundStyle(Color.lmsDanger)
                    } else if let activeLoan = viewModel.activeLoan {
                        SectionCard(title: "Loan Details") {
                            LabeledContent("Principal", value: Formatting.currency(activeLoan.principal))
                            LabeledContent("Disbursed on", value: Formatting.date(activeLoan.disbursementDate))
                            LabeledContent("Status", value: activeLoan.status.rawValue.capitalized)
                            if activeLoan.status == .active {
                                LabeledContent("Next EMI", value: Formatting.currency(nextEMIAmount))
                                LabeledContent("Due Date", value: nextEMIDate)
                            }
                        }
                        
                        let upcoming = viewModel.emiSchedule.filter { $0.status == .upcoming || $0.status == .overdue }
                        if !upcoming.isEmpty {
                            SectionCard(title: "Upcoming EMIs") {
                                ForEach(upcoming) { emi in
                                    emiRow(emi)
                                }
                            }
                        }
                        
                        let paid = viewModel.emiSchedule.filter { $0.status == .paid }
                        SectionCard(title: "Payment History") {
                            if paid.isEmpty {
                                Text("No payments yet").foregroundStyle(.secondary)
                            } else {
                                ForEach(paid) { emi in
                                    emiRow(emi)
                                }
                            }
                        }
                    } else {
                        Text("No loan data.").foregroundStyle(.secondary)
                    }
                }
                .padding(Spacing.m)
            }
            .navigationTitle(loan?.status == .settled ? "Loan History" : "Repayments")
            .task {
                if let env = env {
                    if let providedLoan = loan {
                        await viewModel.loadRepaymentData(loanService: env.loans, loan: providedLoan)
                    } else if let userID = session.currentUser?.id {
                        do {
                            let loans = try await env.loans.fetchActiveLoans(borrowerID: userID)
                            if let first = loans.first(where: { $0.status == .active }) {
                                await viewModel.loadRepaymentData(loanService: env.loans, loan: first)
                            }
                        } catch {}
                    }
                }
            }
        }
    }
    
    private var nextEMIAmount: Decimal {
        viewModel.emiSchedule.first(where: { $0.status == .upcoming || $0.status == .overdue })?.totalAmount ?? 0
    }
    
    private var nextEMIDate: String {
        guard let emi = viewModel.emiSchedule.first(where: { $0.status == .upcoming || $0.status == .overdue }) else {
            return "—"
        }
        return Formatting.date(emi.dueDate)
    }
    
    private func emiRow(_ emi: EMI) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(Formatting.currency(emi.totalAmount)).font(.lmsHeadline)
                Text("Due: \(Formatting.date(emi.dueDate))").font(.lmsCaption)
            }
            Spacer()
            if emi.status == .upcoming || emi.status == .overdue {
                Button("Pay") {
                    Task {
                        await viewModel.payEMI(emi)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                StatusBadge(emi.status.rawValue.capitalized, tone: .success)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview { 
    RepaymentDashboardView() 
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
