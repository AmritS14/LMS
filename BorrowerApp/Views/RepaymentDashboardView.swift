import SwiftUI

struct RepaymentDashboardView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    var loan: Loan?
    @State private var viewModel = RepaymentViewModel()

    var body: some View {
        List {
            if viewModel.isLoading {
                Section {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .listRowBackground(Color.clear)
                }
            } else if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.lmsDanger)
                }
            } else if let activeLoan = viewModel.activeLoan {
                Section("Loan Details") {
                    LabeledContent("Principal", value: Formatting.currency(activeLoan.principal))
                    LabeledContent("Disbursed", value: Formatting.date(activeLoan.disbursementDate))
                    LabeledContent("Status", value: activeLoan.status.rawValue.capitalized)
                    if activeLoan.status == .active {
                        LabeledContent("Next EMI", value: Formatting.currency(nextEMIAmount))
                        LabeledContent("Due Date", value: nextEMIDate)
                    }
                }

                let upcoming = viewModel.emiSchedule.filter { $0.status == .upcoming || $0.status == .overdue }
                if !upcoming.isEmpty {
                    Section("Upcoming EMIs") {
                        ForEach(upcoming) { emi in emiRow(emi) }
                    }
                }

                let paid = viewModel.emiSchedule.filter { $0.status == .paid }
                Section("Payment History") {
                    if paid.isEmpty {
                        Text("No payments yet").foregroundStyle(.secondary)
                    } else {
                        ForEach(paid) { emi in emiRow(emi) }
                    }
                }
            } else {
                Section {
                    ContentUnavailableView(
                        "No Loan Data",
                        systemImage: "doc.text",
                        description: Text("Loan information is not available.")
                    )
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(loan?.status == .settled ? "Loan History" : "Repayments")
        .navigationBarTitleDisplayMode(.large)
        .task {
            guard let env else { return }
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
            VStack(alignment: .leading, spacing: 2) {
                Text(Formatting.currency(emi.totalAmount))
                    .font(.subheadline.weight(.semibold))
                Text("Due \(Formatting.date(emi.dueDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            switch emi.status {
            case .upcoming, .overdue:
                Button("Pay") {
                    Task { await viewModel.payEMI(emi) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            case .paid:
                StatusBadge("Paid", tone: .success)
            }
        }
    }
}

#Preview {
    NavigationStack {
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
}
