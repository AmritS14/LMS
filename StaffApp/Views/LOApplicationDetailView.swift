import SwiftUI

// MARK: - Application Detail View

struct LOApplicationDetailView: View {
    let application: LoanApplication

    @State private var selectedTab = 0
    @State private var showSuccess = false
    @State private var showClarification = false
    @State private var showSanctionLetter = false
    @State private var showFieldVisitScheduler = false
    @State private var showRejectSheet = false
    @State private var documents: [LoanDocument] = []

    private var borrower: User? { MockData.borrowerUser(for: application.borrowerID) }
    private var profile: BorrowerProfile? { MockData.borrowerProfile(for: application.borrowerID) }
    private var isFraudFlagged: Bool { MockData.fraudFlagged(application) }
    private var appIDShort: String { "#\(application.id.uuidString.prefix(8).uppercased())" }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            HStack(spacing: Spacing.m) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.lmsNavyBlue, .lmsPrimary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 64, height: 64)
                    Text((borrower?.fullName.prefix(1) ?? "?"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(borrower?.fullName ?? "—")
                            .font(.lmsTitle2)
                        if isFraudFlagged {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundStyle(Color.lmsDanger)
                        }
                    }
                    Text(appIDShort)
                        .font(.lmsMono)
                        .foregroundStyle(.secondary)
                    StatusBadge(application.status.displayName, tone: statusTone)
                }

                Spacer()

                // Credit Score Gauge
                if let score = profile?.creditScore {
                    VStack(spacing: 2) {
                        Gauge(value: Double(score), in: 300...900) {
                            EmptyView()
                        } currentValueLabel: {
                            Text("\(score)")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .gaugeStyle(.accessoryCircularCapacity)
                        .tint(gaugeColor(score: score))
                        .frame(width: 56, height: 56)

                        Text(scoreLabel(score: score))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(gaugeColor(score: score))
                    }
                }
            }
            .padding(Spacing.m)
            .background(Color.lmsNavyBlue.opacity(0.06))

            // Fraud Alert inline
            if isFraudFlagged {
                HStack(spacing: Spacing.s) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.white)
                    Text("Fraud Risk: Income statement flagged as potentially tampered. Verify before proceeding.")
                        .font(.lmsCaption)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.s)
                .background(Color.lmsDanger)
            }

            // MARK: Tab Bar
            HStack(spacing: 0) {
                ForEach(Array(["Overview", "Documents", "Action"].enumerated()), id: \.offset) { idx, label in
                    DetailTabButton(title: label, index: idx, selectedIndex: $selectedTab)
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.s)

            Divider()

            // MARK: Content
            TabView(selection: $selectedTab) {
                OverviewTab(application: application, profile: profile, borrower: borrower)
                    .tag(0)

                DocumentsTab(documents: documents, showClarification: $showClarification)
                    .tag(1)

                ActionTab(
                    application: application,
                    showSuccess: $showSuccess,
                    showSanctionLetter: $showSanctionLetter,
                    showFieldVisitScheduler: $showFieldVisitScheduler,
                    showRejectSheet: $showRejectSheet
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Application Detail")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let docs = try? await MockData.sharedDocumentService.list(ownerID: application.borrowerID) {
                documents = docs
            }
        }
        .fullScreenCover(isPresented: $showSuccess) {
            LOSuccessConfirmationView(appID: appIDShort)
        }
        .sheet(isPresented: $showClarification) {
            LOClarificationRequestView(application: application, documents: documents)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showSanctionLetter) {
            SanctionLetterView(application: application, borrower: borrower)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showFieldVisitScheduler) {
            FieldVisitSchedulerView(application: application, borrower: borrower)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showRejectSheet) {
            RejectApplicationSheet(application: application)
                .presentationDetents([.medium])
        }
    }

    private var statusTone: StatusBadge.Tone {
        switch application.status {
        case .submitted: return .info
        case .underReview: return .warning
        case .additionalInfoRequired: return .danger
        case .recommended, .approved: return .success
        case .rejected: return .danger
        default: return .neutral
        }
    }

    private func gaugeColor(score: Int) -> Color {
        score >= 750 ? Color.lmsSuccess : score >= 650 ? Color.lmsWarning : Color.lmsDanger
    }

    private func scoreLabel(score: Int) -> String {
        score >= 750 ? "Excellent" : score >= 700 ? "Good" : score >= 650 ? "Fair" : "Poor"
    }
}

// MARK: - Custom Tab Button

struct DetailTabButton: View {
    let title: String
    let index: Int
    @Binding var selectedIndex: Int

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedIndex = index
            }
        } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(.lmsHeadline)
                    .foregroundStyle(selectedIndex == index ? Color.lmsNavyBlue : Color.secondary)
                    .animation(.easeInOut, value: selectedIndex)

                Rectangle()
                    .fill(selectedIndex == index ? Color.lmsNavyBlue : Color.clear)
                    .frame(height: 3)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    let application: LoanApplication
    let profile: BorrowerProfile?
    let borrower: User?

    private var monthlyIncome: Decimal { profile?.monthlyIncome ?? 0 }
    private var dtiRatio: Double {
        guard monthlyIncome > 0 else { return 0 }
        let emi = EMICalculator.calculate(
            principal: application.requestedAmount,
            annualInterestRate: application.interestRate,
            tenureMonths: application.tenureMonths
        ).monthlyInstallment
        return ((emi as NSDecimalNumber).doubleValue / (monthlyIncome as NSDecimalNumber).doubleValue) * 100
    }

    private var dtiWarning: Bool { dtiRatio > 40 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {

                // Financial summary grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.m) {
                    FinancialGridItem(label: "Requested Amount", value: Formatting.currency(application.requestedAmount))
                    FinancialGridItem(label: "Tenure", value: "\(application.tenureMonths) months")
                    FinancialGridItem(label: "Interest Rate", value: "\(application.interestRate)% p.a.")
                    FinancialGridItem(label: "Monthly EMI", value: Formatting.currency(emiMonthly))
                    FinancialGridItem(label: "Monthly Income", value: Formatting.currency(monthlyIncome))
                    FinancialGridItem(label: "DTI Ratio", value: String(format: "%.1f%%", dtiRatio), isWarning: dtiWarning)
                }
                .padding(.horizontal, Spacing.m)

                // Borrower info
                SectionCard(title: "Borrower Details") {
                    LabeledContent("Employment", value: profile?.employmentType?.rawValue.capitalized ?? "—")
                    LabeledContent("KYC Status", value: profile?.kycStatus.rawValue.capitalized ?? "—")
                    LabeledContent("PAN", value: profile?.panNumber ?? "—")
                    LabeledContent("Phone", value: borrower?.phone ?? "—")
                    LabeledContent("Email", value: borrower?.email ?? "—")
                }
                .padding(.horizontal, Spacing.m)

                // Risk panel
                SectionCard(title: "Risk Assessment") {
                    LabeledContent("Credit Score", value: profile.map { "\($0.creditScore ?? 0)" } ?? "—")
                    LabeledContent("Risk Level", value: riskLevel)
                    LabeledContent("LTV Ratio", value: "75%")
                    LabeledContent("Identity Match", value: "Verified")
                }
                .padding(.horizontal, Spacing.m)

                // Loan details
                SectionCard(title: "Loan Details") {
                    LabeledContent("Type", value: application.loanType.rawValue.capitalized)
                    LabeledContent("Purpose", value: application.loanType.purpose)
                    LabeledContent("Applied On", value: Formatting.date(application.createdAt))
                    LabeledContent("Last Updated", value: Formatting.date(application.updatedAt))
                }
                .padding(.horizontal, Spacing.m)

                Spacer(minLength: Spacing.xxl)
            }
            .padding(.vertical, Spacing.m)
        }
    }

    private var emiMonthly: Decimal {
        EMICalculator.calculate(
            principal: application.requestedAmount,
            annualInterestRate: application.interestRate,
            tenureMonths: application.tenureMonths
        ).monthlyInstallment
    }

    private var riskLevel: String {
        guard let score = profile?.creditScore else { return "—" }
        if dtiWarning { return "High (DTI > 40%)" }
        return score >= 700 ? "Low" : score >= 600 ? "Medium" : "High"
    }
}

struct FinancialGridItem: View {
    let label: String
    let value: String
    var isWarning: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.lmsCaption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.lmsHeadline)
                .foregroundStyle(isWarning ? Color.lmsWarning : Color.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .strokeBorder(isWarning ? Color.lmsWarning.opacity(0.4) : Color.secondary.opacity(0.15))
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(isWarning ? Color.lmsWarning.opacity(0.06) : Color(.systemBackground))
                )
        )
    }
}

// MARK: - Documents Tab

struct DocumentsTab: View {
    let documents: [LoanDocument]
    @Binding var showClarification: Bool
    @State private var selectedDoc: LoanDocument?

    var body: some View {
        VStack(spacing: 0) {
            List(documents) { doc in
                Button {
                    selectedDoc = doc
                } label: {
                    DocumentRow(document: doc)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: Spacing.m, bottom: 4, trailing: Spacing.m))
            }
            .listStyle(.plain)

            // Action area
            VStack(spacing: Spacing.s) {
                Divider()
                PrimaryButton("Request Clarifications") {
                    showClarification = true
                }
                .padding(.horizontal, Spacing.m)
                .padding(.bottom, Spacing.m)
            }
        }
        .sheet(item: $selectedDoc) { doc in
            LODocumentReviewSheet(document: doc)
                .presentationDetents([.medium, .large])
        }
    }
}

struct DocumentRow: View {
    let document: LoanDocument

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.fileName)
                    .font(.lmsHeadline)
                    .lineLimit(1)
                Text(document.kind.displayName)
                    .font(.lmsCaption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            StatusBadge(document.status.displayName, tone: statusTone)
        }
        .padding(Spacing.m)
        .background(.background, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }

    private var statusTone: StatusBadge.Tone {
        switch document.status {
        case .verified: return .success
        case .rejected: return .danger
        case .pending: return .warning
        }
    }

    private var iconColor: Color {
        switch document.status {
        case .verified: return Color.lmsSuccess
        case .rejected: return Color.lmsDanger
        case .pending: return Color.lmsWarning
        }
    }

    private var iconName: String {
        switch document.status {
        case .verified: return "doc.badge.checkmark"
        case .rejected: return "doc.badge.minus"
        case .pending: return "doc.badge.clock"
        }
    }
}

// MARK: - Action Tab

struct ActionTab: View {
    let application: LoanApplication
    @Binding var showSuccess: Bool
    @Binding var showSanctionLetter: Bool
    @Binding var showFieldVisitScheduler: Bool
    @Binding var showRejectSheet: Bool
    @State private var remarks = ""

    private var canRecommend: Bool {
        !MockData.fraudFlagged(application) && (application.status == .underReview || application.status == .submitted)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {

                // Automated checks card
                SectionCard(title: "Automated Checks") {
                    CheckRow(label: "Identity Match", value: "Verified", passed: true)
                    CheckRow(label: "Duplicate Documents", value: MockData.fraudFlagged(application) ? "Detected ⚠️" : "None", passed: !MockData.fraudFlagged(application))
                    CheckRow(label: "Blacklist Check", value: "Clear", passed: true)
                    CheckRow(label: "PAN Verification", value: "Verified", passed: true)
                }

                // Remarks
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("Officer Remarks")
                        .font(.lmsHeadline)
                    TextEditor(text: $remarks)
                        .frame(minHeight: 120)
                        .padding(Spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .strokeBorder(Color.secondary.opacity(0.3))
                        )
                        .overlay(alignment: .topLeading) {
                            if remarks.isEmpty {
                                Text("Add your analysis remarks here…")
                                    .font(.lmsBody)
                                    .foregroundStyle(.tertiary)
                                    .padding(12)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                // Actions
                VStack(spacing: Spacing.m) {

                    // Primary: Forward to manager
                    PrimaryButton(canRecommend ? "Forward to Manager" : "Forward Unavailable") {
                        showSuccess = true
                    }
                    .disabled(!canRecommend || remarks.trimmingCharacters(in: .whitespaces).isEmpty)

                    if !canRecommend && MockData.fraudFlagged(application) {
                        Label("Fraud flag must be resolved before forwarding.", systemImage: "exclamationmark.triangle.fill")
                            .font(.lmsCaption)
                            .foregroundStyle(Color.lmsDanger)
                    }

                    // Sanction Letter
                    ActionButton(
                        title: "Generate Sanction Letter",
                        icon: "doc.richtext",
                        color: .lmsSuccess
                    ) { showSanctionLetter = true }

                    // Field Visit
                    ActionButton(
                        title: "Schedule Field Visit",
                        icon: "mappin.and.ellipse",
                        color: .lmsPrimary
                    ) { showFieldVisitScheduler = true }

                    // Reject
                    ActionButton(
                        title: "Reject Application",
                        icon: "xmark.circle",
                        color: .lmsDanger,
                        isDestructive: true
                    ) { showRejectSheet = true }
                }

                Spacer(minLength: Spacing.xxl)
            }
            .padding(Spacing.m)
        }
    }
}

struct CheckRow: View {
    let label: String
    let value: String
    let passed: Bool

    var body: some View {
        HStack {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(passed ? Color.lmsSuccess : Color.lmsDanger)
            Text(label).font(.lmsBody)
            Spacer()
            Text(value)
                .font(.lmsSubheadline)
                .foregroundStyle(passed ? Color.secondary : Color.lmsDanger)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title).font(.lmsHeadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .strokeBorder(color.opacity(0.6), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(color.opacity(0.06))
                    )
            )
            .foregroundStyle(color)
        }
    }
}

// MARK: - Sanction Letter View

struct SanctionLetterView: View {
    let application: LoanApplication
    let borrower: User?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    // Bank Header
                    HStack {
                        Image(systemName: "building.columns.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.lmsNavyBlue)
                        VStack(alignment: .leading) {
                            Text("LMS BANK LTD.").font(.lmsTitle2)
                            Text("Retail Lending Division").font(.lmsCaption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    Divider()

                    Text("LOAN SANCTION LETTER")
                        .font(.lmsHeadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Group {
                        LabeledContent("Date", value: Formatting.date(.now))
                        LabeledContent("To", value: borrower?.fullName ?? "—")
                        LabeledContent("Application ID", value: "#\(application.id.uuidString.prefix(8).uppercased())")
                        LabeledContent("Loan Type", value: application.loanType.rawValue.capitalized)
                        LabeledContent("Sanctioned Amount", value: Formatting.currency(application.requestedAmount))
                        LabeledContent("Interest Rate", value: "\(application.interestRate)% p.a. (Reducing Balance)")
                        LabeledContent("Tenure", value: "\(application.tenureMonths) months")
                        LabeledContent("Monthly EMI", value: Formatting.currency(
                            EMICalculator.calculate(
                                principal: application.requestedAmount,
                                annualInterestRate: application.interestRate,
                                tenureMonths: application.tenureMonths
                            ).monthlyInstallment
                        ))
                    }

                    Divider()

                    Text("This letter confirms the sanction of the above loan subject to execution of loan agreement documents and fulfillment of all conditions. The bank reserves the right to withdraw this sanction in case of any material misrepresentation.")
                        .font(.lmsCaption)
                        .foregroundStyle(.secondary)

                    PrimaryButton("Share Letter") {
                        // In production: trigger ShareLink with PDF rendering
                        dismiss()
                    }
                }
                .padding(Spacing.l)
            }
            .navigationTitle("Sanction Letter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Field Visit Scheduler

struct FieldVisitSchedulerView: View {
    let application: LoanApplication
    let borrower: User?
    @Environment(\.dismiss) private var dismiss
    @State private var visitDate = Date()
    @State private var purpose = ""
    @State private var notes = ""
    @State private var scheduled = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Borrower") {
                    LabeledContent("Name", value: borrower?.fullName ?? "—")
                    LabeledContent("Application", value: "#\(application.id.uuidString.prefix(8).uppercased())")
                }
                Section("Visit Details") {
                    DatePicker("Visit Date & Time", selection: $visitDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    TextField("Purpose (e.g. Property Verification)", text: $purpose)
                    TextField("Notes / Special Instructions", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Schedule Field Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schedule") {
                        scheduled = true
                        dismiss()
                    }
                    .disabled(purpose.isEmpty)
                }
            }
        }
    }
}

// MARK: - Reject Application Sheet

struct RejectApplicationSheet: View {
    let application: LoanApplication
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.l) {
                SectionCard(title: "Rejection Reason") {
                    TextEditor(text: $reason)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if reason.isEmpty {
                                Text("State the reason for rejection…")
                                    .font(.lmsBody)
                                    .foregroundStyle(.tertiary)
                                    .padding(4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Confirm Rejection")
                        .font(.lmsHeadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.lmsDanger, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                .disabled(reason.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding()
            }
            .padding()
            .navigationTitle("Reject Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

// MARK: - Extensions

extension LoanType {
    var purpose: String {
        switch self {
        case .personal: return "Personal Use"
        case .home: return "Home Purchase / Construction"
        case .vehicle: return "Vehicle Purchase"
        case .education: return "Education Expenses"
        case .business: return "Business Expansion"
        }
    }
}

extension DocumentKind {
    var displayName: String {
        switch self {
        case .identityProof: return "Identity Proof"
        case .addressProof: return "Address Proof"
        case .incomeProof: return "Income Proof"
        case .bankStatement: return "Bank Statement"
        case .collateral: return "Collateral Document"
        case .other: return "Other"
        }
    }
}

extension DocumentVerificationStatus {
    var displayName: String {
        switch self {
        case .pending: return "Needs Review"
        case .verified: return "Verified"
        case .rejected: return "Flagged"
        }
    }
}

#Preview {
    NavigationStack {
        LOApplicationDetailView(application: MockData.appJane)
    }
}
