import SwiftUI

struct RepaymentDashboardView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    var loan: Loan?
    @State private var viewModel = RepaymentViewModel()
    @State private var emiToPay: EMI?
    @State private var showForeclosureSheet = false

    var body: some View {
        List {
            if viewModel.isLoading {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .listRowBackground(Color.clear)
            } else if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.lmsDanger)
            } else if let activeLoan = viewModel.activeLoan {
                
                // Next Payment Card
                if activeLoan.status == .active {
                    Section {
                        nextPaymentCard(for: activeLoan)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                // Loan Details Card
                loanDetailsSection(for: activeLoan)
                
            } else {
                ContentUnavailableView(
                    "No Loan Data",
                    systemImage: "doc.text",
                    description: Text("Loan information is not available.")
                )
                .listRowBackground(Color.clear)
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
        .sheet(item: $emiToPay) { emi in
            PayEMISheet(emi: emi, loan: viewModel.activeLoan) {
                await viewModel.payEMI(emi)
                return viewModel.paymentSuccess
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showForeclosureSheet) {
            if let activeLoan = viewModel.activeLoan, let env {
                ForeclosureSheet(
                    loan: activeLoan,
                    loanService: env.loans
                ) {
                    Task {
                        if let userID = session.currentUser?.id {
                            if let loans = try? await env.loans.fetchActiveLoans(borrowerID: userID),
                               let first = loans.first(where: { $0.id == activeLoan.id }) {
                                await viewModel.loadRepaymentData(loanService: env.loans, loan: first)
                            }
                        }
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var nextEMI: EMI? {
        viewModel.emiSchedule.filter { $0.status == .upcoming || $0.status == .overdue }.min(by: { $0.dueDate < $1.dueDate })
    }

    // MARK: - Next Payment Card
    private func nextPaymentCard(for activeLoan: Loan) -> some View {
        VStack(spacing: Spacing.m) {
            Text("NEXT PAYMENT DUE")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(Formatting.currency(nextEMI?.totalAmount ?? 0))
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(.primary)
            
            if let dueDate = nextEMI?.dueDate {
                Text(Formatting.date(dueDate))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.blue)
            } else {
                Text("—")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button {
                if let emi = nextEMI {
                    emiToPay = emi
                }
            } label: {
                Text("Pay Now")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(nextEMI == nil)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }

    // MARK: - Loan Details Section
    @ViewBuilder
    private func loanDetailsSection(for activeLoan: Loan) -> some View {
        Section(header: Text("LOAN DETAILS")) {
            LabeledContent("Principal", value: Formatting.currency(activeLoan.principal))
            LabeledContent("Outstanding", value: Formatting.currency(activeLoan.outstandingBalance))
            LabeledContent("Disbursed on", value: Formatting.date(activeLoan.disbursementDate))
            LabeledContent("Status", value: activeLoan.status.rawValue.capitalized)
            
            let remaining = viewModel.emiSchedule.filter { $0.status != .paid }.count
            LabeledContent("Remaining EMIs", value: "\(remaining)")
            
            NavigationLink(destination: FullScheduleView(emiSchedule: viewModel.emiSchedule, onPayEMI: { emi in
                emiToPay = emi
            })) {
                Text("View Full Schedule")
            }
            
            if activeLoan.status == .active {
                Button(role: .destructive) {
                    showForeclosureSheet = true
                } label: {
                    Label("Foreclose Loan Early", systemImage: "clock.arrow.circlepath")
                }
            }
        }
    }
}

// MARK: - Full Schedule View
struct FullScheduleView: View {
    let emiSchedule: [EMI]
    let onPayEMI: (EMI) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("UPCOMING EMIS")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.m)
                    .padding(.top, Spacing.m)
                
                let upcoming = emiSchedule.filter { $0.status == .upcoming || $0.status == .overdue }.sorted(by: { $0.dueDate < $1.dueDate })
                
                if upcoming.isEmpty {
                    Text("No upcoming EMIs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Spacing.m)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(upcoming.enumerated()), id: \.element.id) { index, emi in
                            emiRow(emi, isFirstUpcoming: index == 0)
                            if index < upcoming.count - 1 {
                                Divider().padding(.leading, Spacing.m)
                            }
                        }
                    }
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
                    .padding(.horizontal, Spacing.m)
                }
                
                let paid = emiSchedule.filter { $0.status == .paid }.sorted(by: { $0.dueDate > $1.dueDate })
                if !paid.isEmpty {
                    Text("PAYMENT HISTORY")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Spacing.m)
                        .padding(.top, Spacing.l)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(paid.enumerated()), id: \.element.id) { index, emi in
                            emiRow(emi, isFirstUpcoming: false)
                            if index < paid.count - 1 {
                                Divider().padding(.leading, Spacing.m)
                            }
                        }
                    }
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
                    .padding(.horizontal, Spacing.m)
                }
            }
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.lmsBackground.ignoresSafeArea())
        .navigationTitle("Full Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func emiRow(_ emi: EMI, isFirstUpcoming: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Formatting.currency(emi.totalAmount))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text("Due: \(Formatting.date(emi.dueDate))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if emi.status == .paid {
                Text("Paid")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
            } else if emi.status == .overdue {
                Button("Pay") {
                    onPayEMI(emi)
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.lmsDanger)
                .clipShape(Capsule())
            } else if isFirstUpcoming {
                Button("Pay") {
                    onPayEMI(emi)
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .clipShape(Capsule())
            } else {
                Text("Upcoming")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, Spacing.m)
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

// MARK: - Foreclosure Sheet View
struct ForeclosureSheet: View {
    let loan: Loan
    let loanService: any LoanService
    var onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var details: ForeclosureDetails? = nil
    @State private var isLoading = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var success = false

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Calculating Payoff Amount...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    ContentUnavailableView("Calculation Failed", systemImage: "exclamationmark.triangle", description: Text(error))
                } else if success {
                    successContent
                } else if let details = details {
                    payoffDetailsContent(details: details)
                }
            }
            .background(Color.lmsBackground.ignoresSafeArea())
            .navigationTitle("Prepayment & Foreclose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(success ? "Done" : "Cancel") {
                        if success { onComplete() }
                        dismiss()
                    }
                }
            }
            .task {
                await calculatePayoff()
            }
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
                Text("Loan Foreclosed Successfully")
                    .font(.title2.weight(.semibold))
                Text("Your \(loan.loanType.rawValue.capitalized) Loan outstanding balance is now ₹0.00 and status is settled.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.l)
            }
            Spacer()
            PrimaryButton("Done") {
                onComplete()
                dismiss()
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.m)
        }
    }

    private func payoffDetailsContent(details: ForeclosureDetails) -> some View {
        VStack(spacing: Spacing.l) {
            VStack(spacing: Spacing.xs) {
                Text("Total Payoff Amount")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(Formatting.currency(details.totalPayoffAmount))
                    .font(.system(size: 38, weight: .bold))
            }
            .padding(.top, Spacing.l)

            VStack(spacing: 0) {
                breakdownRow("Current Outstanding Principal", Formatting.currency(details.outstandingBalance))
                Divider().padding(.leading, Spacing.m)
                breakdownRow("Early Foreclosure Penalty (2%)", Formatting.currency(details.penaltyAmount))
                Divider().padding(.leading, Spacing.m)
                breakdownRow("GST on Penalty (18%)", Formatting.currency(details.gstAmount))
            }
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .padding(.horizontal, Spacing.m)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Important Information", systemImage: "info.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
                Text("Foreclosing your loan early will settle your entire outstanding liability and close the contract. Prepayment charges are calculated at 2.0% of the principal outstanding, plus standard GST (18%) on the penalty fee.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.m)
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .padding(.horizontal, Spacing.m)

            Spacer()

            PrimaryButton("Confirm Foreclosure & Close Loan", isLoading: isProcessing) {
                Task { await performForeclosure(details: details) }
            }
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

    private func calculatePayoff() async {
        isLoading = true
        errorMessage = nil
        do {
            details = try await loanService.calculateForeclosure(loanID: loan.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func performForeclosure(details: ForeclosureDetails) async {
        isProcessing = true
        errorMessage = nil
        do {
            _ = try await loanService.forecloseLoan(loanID: loan.id, totalPayoff: details.totalPayoffAmount)
            withAnimation {
                success = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
}
