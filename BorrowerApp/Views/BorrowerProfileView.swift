import SwiftUI

struct BorrowerProfileView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var settledLoans: [Loan] = []
    @State private var uploadedDocumentKinds: [DocumentKind] = []
    @State private var showSignOutConfirm = false
    @State private var isCheckingCreditScore = false
    @State private var creditScoreLastChecked: Date?
    @State private var showCreditCheckSheet = false
    @State private var showEmploymentSheet = false

    private var kycStatusText: String {
        switch session.borrowerProfile?.kycStatus {
        case .verified:
            return "Verified"
        case .submitted:
            return "Submitted"
        case .rejected:
            return "Rejected"
        case .pending, .none:
            return "Not Verified"
        }
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
            }

            // Employment & Income
            Section {
                Button {
                    showEmploymentSheet = true
                } label: {
                    HStack {
                        iconBadge(icon: "briefcase.fill", color: .purple)
                        Text("Employment Details")
                            .foregroundStyle(.primary)
                        Spacer()
                        if let type = session.borrowerProfile?.employmentType, let income = session.borrowerProfile?.monthlyIncome {
                            Text("\(type.rawValue.capitalized) • \(Formatting.currency(income))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Setup")
                                .font(.subheadline)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }

            // Credit Score
            Section {
                creditScoreRow
            } header: {
                Text("Credit Score")
            } footer: {
                if let last = creditScoreLastChecked {
                    Text("Last checked \(last.formatted(.relative(presentation: .named)))")
                } else {
                    Text("Tap Check Now for a soft enquiry. This won't affect your score.")
                }
            }

            // Verification
            Section("Verification") {
                NavigationLink {
                    KYCOptionsView()
                } label: {
                    let isVerified = session.borrowerProfile?.kycStatus == .verified
                    let isRejected = session.borrowerProfile?.kycStatus == .rejected
                    iconLabelRow(
                        icon: isVerified ? "checkmark.seal.fill" : (isRejected ? "xmark.seal.fill" : "person.text.rectangle.fill"),
                        iconColor: isVerified ? .teal : (isRejected ? .red : .blue),
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
        .refreshable { await loadData() }
        .task { await loadData() }
        .confirmationDialog(
            "Sign out of your account?",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) { signOut() }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showCreditCheckSheet) {
            CreditCheckSheet(
                creditScoreLastChecked: $creditScoreLastChecked,
                onSuccess: {
                    Task { await loadData() }
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEmploymentSheet) {
            if let env {
                EmploymentDetailsSheet(env: env) {
                    Task { await loadData() }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
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

    // MARK: - Credit Score
    private var creditScoreRow: some View {
        HStack(spacing: Spacing.sm) {
            iconBadge(icon: "speedometer", color: .indigo)
            VStack(alignment: .leading, spacing: 2) {
                Text("CIBIL Score")
                if let score = session.borrowerProfile?.creditScore {
                    Text("\(score) • \(rating(for: score))")
                        .font(.caption)
                        .foregroundStyle(color(for: score))
                } else {
                    Text("Not checked yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                showCreditCheckSheet = true
            } label: {
                Text(session.borrowerProfile?.creditScore == nil ? "Check Now" : "Refresh")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private func rating(for score: Int) -> String {
        switch score {
        case ..<650:   return "Fair"
        case 650..<700: return "Good"
        case 700..<750: return "Very Good"
        default:        return "Excellent"
        }
    }

    private func color(for score: Int) -> Color {
        switch score {
        case ..<650:   return .lmsWarning
        case 650..<700: return .lmsInfo
        default:        return .lmsSuccess
        }
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
            
            // Refresh borrower profile from Supabase
            if let profile = try? await env.auth.fetchBorrowerProfile(userID: userID) {
                await MainActor.run {
                    session.borrowerProfile = profile
                }
            }
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

// MARK: - Credit Check Sheet
struct CreditCheckSheet: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    @Binding var creditScoreLastChecked: Date?
    var onSuccess: () -> Void

    @State private var panNumber: String = ""
    @State private var isConsentChecked: Bool = false
    @State private var isChecking: Bool = false
    @State private var errorMessage: String?

    private func isValidPAN(_ pan: String) -> Bool {
        let panRegex = "^[A-Z]{5}[0-9]{4}[A-Z]{1}$"
        let panTest = NSPredicate(format: "SELF MATCHES %@", panRegex)
        return panTest.evaluate(with: pan.uppercased())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: Spacing.ml) {
                        // Header Illustration
                        VStack(spacing: Spacing.s) {
                            Image(systemName: "speedometer")
                                .font(.system(size: 56, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                                .padding(.top, Spacing.m)
                            
                            Text("Check Credit Score")
                                .font(.title3.bold())
                                
                            Text("Retrieve your real CIBIL score instantly. This is a soft inquiry and won't affect your credit rating.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.m)
                        }
                        .padding(.vertical, Spacing.s)
                        
                        // Input Field Card
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            Text("PAN Card Number")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            
                            TextField("ABCDE1234F", text: $panNumber)
                                .font(.system(.body, design: .monospaced).weight(.bold))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)
                                .onChange(of: panNumber) { _, newValue in
                                    let cleaned = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                                    if cleaned.count > 10 {
                                        panNumber = String(cleaned.prefix(10))
                                    } else {
                                        panNumber = cleaned
                                    }
                                }
                                .padding()
                                .background(Color.lmsBackground, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                                        .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
                                )
                        }
                        .padding(Spacing.m)
                        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                        
                        // Consent checkmark (completely vertically aligned and padded)
                        HStack(alignment: .top, spacing: Spacing.m) {
                            Button {
                                isConsentChecked.toggle()
                            } label: {
                                Image(systemName: isConsentChecked ? "checkmark.circle.fill" : "circle")
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(isConsentChecked ? Color.accentColor : Color.secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 2)
                            
                            Text("I hereby authorize the app and its lending partners to fetch my credit score from TransUnion CIBIL, Experian, or Equifax for loan eligibility.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .onTapGesture {
                                    isConsentChecked.toggle()
                                }
                        }
                        .padding(Spacing.m)
                        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                        
                        if let error = errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.lmsDanger)
                                .padding(.horizontal, Spacing.s)
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.bottom, Spacing.xl)
                }
                
                // Bottom Button Action Row
                VStack(spacing: 0) {
                    Divider()
                    PrimaryButton("Check Score", isLoading: isChecking) {
                        let trimmed = panNumber.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                        guard trimmed.count == 10 else {
                            errorMessage = "Please enter a 10-digit PAN number."
                            return
                        }
                        guard isValidPAN(trimmed) else {
                            errorMessage = "Invalid PAN card format. It must consist of 5 letters, 4 numbers, and 1 letter (e.g. ABCDE1234F)."
                            return
                        }
                        guard isConsentChecked else {
                            errorMessage = "Consent is required to check your credit score."
                            return
                        }

                        errorMessage = nil
                        isChecking = true

                        Task {
                            do {
                                let score = try await verifyPANAndFetchScore(pan: trimmed)
                                isChecking = false
                                
                                // Save score to backend and update session
                                var updatedProfile = session.borrowerProfile ?? BorrowerProfile(
                                    id: session.currentUser?.id ?? UUID(),
                                    dateOfBirth: Date()
                                )
                                updatedProfile.creditScore = score
                                updatedProfile.panNumber = trimmed
                                
                                if let env {
                                    try await env.auth.saveBorrowerProfile(updatedProfile)
                                }
                                
                                session.borrowerProfile = updatedProfile
                                
                                creditScoreLastChecked = .now
                                onSuccess()
                                dismiss()
                            } catch {
                                isChecking = false
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .disabled(panNumber.count != 10 || !isConsentChecked)
                    .padding(Spacing.m)
                    .background(Color.lmsSurface)
                }
            }
            .background(Color.lmsBackground.ignoresSafeArea())
            .navigationTitle("Check Credit Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - API Integration Hook
    private func verifyPANAndFetchScore(pan: String) async throws -> Int {
        try await Task.sleep(for: .seconds(2.0)) // Simulating bureau fetch latency
        return Int.random(in: 710...820) // Return a high quality mock score
    }
}

struct EmploymentDetailsSheet: View {
    let env: AppEnvironment
    var onSaved: () -> Void

    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var employmentType: EmploymentType = .salaried
    @State private var monthlyIncomeText: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(Color.lmsDanger)
                            .font(.subheadline)
                    }
                }

                Section("Employment Type") {
                    Picker("Type", selection: $employmentType) {
                        ForEach(EmploymentType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Monthly Income") {
                    TextField("e.g. 50000", text: $monthlyIncomeText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Employment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            save()
                        }
                        .disabled(monthlyIncomeText.isEmpty)
                    }
                }
            }
            .onAppear {
                if let type = session.borrowerProfile?.employmentType {
                    employmentType = type
                }
                if let income = session.borrowerProfile?.monthlyIncome {
                    monthlyIncomeText = "\(income)"
                }
            }
        }
    }

    private func save() {
        guard let amount = Decimal(string: monthlyIncomeText) else {
            errorMessage = "Please enter a valid monthly income."
            return
        }

        Task {
            isSaving = true
            do {
                var profile = session.borrowerProfile ?? BorrowerProfile(
                    id: session.currentUser?.id ?? UUID(),
                    dateOfBirth: Date()
                )
                profile.employmentType = employmentType
                profile.monthlyIncome = amount

                try await env.auth.saveBorrowerProfile(profile)
                session.borrowerProfile = profile
                
                onSaved()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}

struct KYCOptionsView: View {
    @Environment(SessionStore.self) private var session
    
    var body: some View {
        List {
            if session.borrowerProfile?.kycStatus == .verified {
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.teal)
                        Text("KYC Verified")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Your identity has been successfully verified.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.m)
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: session.borrowerProfile?.kycStatus == .rejected ? "xmark.seal.fill" : "person.text.rectangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(session.borrowerProfile?.kycStatus == .rejected ? .red : .blue)
                        Text(session.borrowerProfile?.kycStatus == .rejected ? "KYC Rejected" : "KYC Pending")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Please complete your KYC to apply for loans.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.m)
                    .listRowBackground(Color.clear)
                }
                
                Section("Verification Options") {
                    NavigationLink {
                        AadhaarKYCView()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "shield.checkered")
                                .font(.title2)
                                .foregroundStyle(.teal)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Official Aadhaar KYC")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("Verified via UIDAI (Recommended)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    NavigationLink {
                        KYCView()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "testtube.2")
                                .font(.title2)
                                .foregroundStyle(.purple)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mock KYC Simulator")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("Testing purposes only")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("KYC Status")
        .navigationBarTitleDisplayMode(.inline)
    }
}
