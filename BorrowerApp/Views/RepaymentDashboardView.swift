import SwiftUI

struct RepaymentDashboardView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    var loan: Loan?
    @State private var viewModel = RepaymentViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.lmsDanger)
                        .padding(.top, 40)
                } else if let activeLoan = viewModel.activeLoan {
                    
                    // Next Payment Card
                    if activeLoan.status == .active {
                        nextPaymentCard(for: activeLoan)
                    }
                    
                    // Loan Details Card
                    loanDetailsSection(for: activeLoan)
                    
                } else {
                    ContentUnavailableView(
                        "No Loan Data",
                        systemImage: "doc.text",
                        description: Text("Loan information is not available.")
                    )
                }
            }
            .padding(.vertical, Spacing.m)
        }
        .background(Color.lmsBackground.ignoresSafeArea())
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
                    Task { await viewModel.payEMI(emi) }
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
        .padding(.horizontal, Spacing.m)
    }

    // MARK: - Loan Details Section
    private func loanDetailsSection(for activeLoan: Loan) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("LOAN DETAILS")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.m)
            
            VStack(spacing: 0) {
                detailRow(title: "Principal", value: Formatting.currency(activeLoan.principal))
                detailRow(title: "Disbursed on", value: Formatting.date(activeLoan.disbursementDate))
                detailRow(title: "Status", value: activeLoan.status.rawValue.capitalized)
                
                let remaining = viewModel.emiSchedule.filter { $0.status != .paid }.count
                detailRow(title: "Remaining EMIs", value: "\(remaining)")
                
                Divider()
                    .padding(.vertical, Spacing.m)
                
                NavigationLink(destination: FullScheduleView(emiSchedule: viewModel.emiSchedule, viewModel: viewModel)) {
                    HStack {
                        Text("View Full Schedule")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(Spacing.m)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
            .padding(.horizontal, Spacing.m)
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, Spacing.m)
    }
}

// MARK: - Full Schedule View
struct FullScheduleView: View {
    let emiSchedule: [EMI]
    let viewModel: RepaymentViewModel
    
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
            } else if isFirstUpcoming {
                Button("Pay") {
                    Task { await viewModel.payEMI(emi) }
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
