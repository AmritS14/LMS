import SwiftUI

struct BorrowerProfileView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var settledLoans: [Loan] = []
    @State private var uploadedDocumentKinds: [DocumentKind] = []
    @State private var showSignOutConfirm = false

    private var kycStatusText: String {
        if session.borrowerProfile?.kycStatus == .verified { return "Verified" }
        let required: [(DocumentKind, String)] = [
            (.identityProof, "ID Proof"),
            (.addressProof,  "Address"),
            (.incomeProof,   "Income"),
            (.bankStatement, "Bank Statement")
        ]
        let missing = required.filter { !uploadedDocumentKinds.contains($0.0) }.map { $0.1 }
        if missing.isEmpty { return "Pending Approval" }
        if missing.count == 1 { return "\(missing[0]) missing" }
        return "\(missing.count) documents missing"
    }

    var body: some View {
        List {
            // Profile header
            Section {
                profileHeader
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: Spacing.l, leading: 0, bottom: Spacing.s, trailing: 0))
            }

            // Account
            Section("Account") {
                infoRow(icon: "envelope.fill", iconColor: .blue, title: "Email",
                        value: session.currentUser?.email ?? "—")
                infoRow(icon: "phone.fill", iconColor: .green, title: "Phone",
                        value: session.currentUser?.phone ?? "—")
                infoRow(icon: "speedometer", iconColor: .indigo, title: "Credit Score",
                        value: session.borrowerProfile?.creditScore.map(String.init) ?? "—")
            }

            // Verification
            Section("Verification") {
                NavigationLink {
                    KYCView()
                } label: {
                    let isVerified = session.borrowerProfile?.kycStatus == .verified
                    iconLabelRow(
                        icon: isVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                        iconColor: isVerified ? .teal : .orange,
                        title: "KYC Status",
                        detail: kycStatusText
                    )
                }
            }

            // Loans
            if !settledLoans.isEmpty {
                Section("Loan History") {
                    ForEach(settledLoans.prefix(3)) { loan in
                        NavigationLink {
                            RepaymentDashboardView(loan: loan)
                        } label: {
                            settledLoanRow(loan)
                        }
                    }
                    if settledLoans.count > 3 {
                        NavigationLink("See All \(settledLoans.count) Loans") {
                            LoanHistoryListView(loans: settledLoans)
                        }
                    }
                }
            }

            // Sign Out
            Section {
                Button(role: .destructive) {
                    showSignOutConfirm = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .task { await loadData() }
        .confirmationDialog(
            "Sign out of your account?",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) { signOut() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Header
    private var profileHeader: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 88, height: 88)
                Text(session.currentUser?.fullName.prefix(1).uppercased() ?? "U")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(.tint)
            }

            VStack(spacing: 2) {
                Text(session.currentUser?.fullName ?? "User")
                    .font(.title2.weight(.semibold))
                Text(session.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Row components
    private func infoRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack(spacing: Spacing.sm) {
            iconBadge(icon: icon, color: iconColor)
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func iconLabelRow(icon: String, iconColor: Color, title: String, detail: String) -> some View {
        HStack(spacing: Spacing.sm) {
            iconBadge(icon: icon, color: iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func iconBadge(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private func settledLoanRow(_ loan: Loan) -> some View {
        HStack(spacing: Spacing.sm) {
            iconBadge(icon: "checkmark", color: .lmsSuccess)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(loan.loanType.rawValue.capitalized) Loan")
                    .font(.subheadline.weight(.medium))
                Text(Formatting.currency(loan.principal))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusBadge("Settled", tone: .success)
        }
    }

    // MARK: - Actions
    private func loadData() async {
        guard let env, let userID = session.currentUser?.id else { return }
        do {
            let loans = try await env.loans.fetchActiveLoans(borrowerID: userID)
            settledLoans = loans.filter { $0.status == .settled }
            let docs = try await env.documents.list(ownerID: userID)
            uploadedDocumentKinds = docs.map { $0.kind }
        } catch {
            // ignore; UI shows defaults
        }
    }

    private func signOut() {
        Task {
            try? await env?.auth.signOut()
            session.currentUser = nil
            session.borrowerProfile = nil
        }
    }
}

// MARK: - Loan History List
struct LoanHistoryListView: View {
    let loans: [Loan]

    var body: some View {
        List {
            ForEach(loans) { loan in
                NavigationLink {
                    RepaymentDashboardView(loan: loan)
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.lmsSuccess, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(loan.loanType.rawValue.capitalized) Loan")
                                .font(.subheadline.weight(.medium))
                            Text(Formatting.currency(loan.principal))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                        StatusBadge("Settled", tone: .success)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Loan History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        BorrowerProfileView()
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
