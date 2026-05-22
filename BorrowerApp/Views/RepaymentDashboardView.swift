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
                        
                        if let nextEmi = viewModel.emiSchedule.first(where: { $0.status == .upcoming || $0.status == .overdue }) {
                            heroCard(for: nextEmi)
                        } else {
                            SectionCard(title: "All Caught Up!") {
                                Text("There are no upcoming EMIs for this loan.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        SectionCard(title: "Loan Details") {
                            LabeledContent("Principal", value: Formatting.currency(activeLoan.principal))
                            LabeledContent("Disbursed on", value: Formatting.date(activeLoan.disbursementDate))
                            LabeledContent("Status", value: activeLoan.status.rawValue.capitalized)
                            if activeLoan.status == .active {
                                LabeledContent("Remaining EMIs", value: "\(viewModel.emiSchedule.filter { $0.status != .paid }.count)")
                            }
                        }
                        
                        NavigationLink(destination: FullScheduleView(viewModel: viewModel)) {
                            HStack {
                                Text("View Full Schedule")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
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
    
    private func heroCard(for emi: EMI) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Next Payment Due")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Text(Formatting.currency(emi.totalAmount))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(Formatting.date(emi.dueDate))
                    .font(.headline)
                    .foregroundStyle(emi.status == .overdue ? Color.red : Color.blue)
            }
            
            Button {
                Task {
                    await viewModel.payEMI(emi)
                }
            } label: {
                Text("Pay Now")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 15, y: 8)
    }
}

struct FullScheduleView: View {
    var viewModel: RepaymentViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.m) {
                let upcoming = viewModel.emiSchedule.filter { $0.status == .upcoming || $0.status == .overdue }
                if !upcoming.isEmpty {
                    SectionCard(title: "Upcoming EMIs") {
                        ForEach(Array(upcoming.enumerated()), id: \.element.id) { index, emi in
                            emiRow(emi, isNext: index == 0)
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
            }
            .padding(Spacing.m)
        }
        .navigationTitle("Full Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func emiRow(_ emi: EMI, isNext: Bool = false) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(Formatting.currency(emi.totalAmount)).font(.lmsHeadline)
                Text("Due: \(Formatting.date(emi.dueDate))").font(.lmsCaption)
            }
            Spacer()
            if emi.status == .paid {
                StatusBadge(emi.status.rawValue.capitalized, tone: .success)
            } else if isNext {
                Button("Pay") {
                    Task {
                        await viewModel.payEMI(emi)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                StatusBadge(emi.status.rawValue.capitalized, tone: emi.status == .overdue ? .danger : .warning)
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
