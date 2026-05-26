import SwiftUI

// MARK: - Officer recommendation (manager-facing summary of the officer's call)

// The loan officer's recommendation, surfaced to the manager as a badge on
// the application card and review screen. Derived from the application's
// risk profile so it stays consistent with `RiskLevel`.
enum OfficerRecommendation: String, Hashable, CaseIterable {
    case high
    case medium
    case low

    var badgeText: String {
        switch self {
        case .high: "HIGH REC"
        case .medium: "MED REC"
        case .low: "LOW REC"
        }
    }

    var tone: StatusBadge.Tone {
        switch self {
        case .high: .success
        case .medium: .warning
        case .low: .danger
        }
    }

    static func from(risk: RiskLevel) -> OfficerRecommendation {
        switch risk {
        case .low: .high
        case .medium: .medium
        case .high, .critical: .low
        }
    }
}

// MARK: - Manager Application view model

// A denormalized join layered on top of `OfficerApplication` (which already
// carries borrower + profile + risk/EMI/eligibility) plus the manager-only
// context: who originated it and what they recommended. Built by the store;
// views never construct one directly.
struct ManagerApplication: Identifiable, Hashable {
    let base: OfficerApplication
    let officerName: String
    let recommendation: OfficerRecommendation
    let evaluationNote: String
    // The application's real uploaded documents, hydrated by the store from
    // the backend. Defaults to empty so previews / mock builders still compile.
    var documents: [LoanDocument] = []

    var id: UUID { base.id }

    // MARK: Document summary (derived from the real vault)
    var verifiedDocumentCount: Int { documents.filter { $0.status == .verified }.count }
    var totalDocumentCount: Int { documents.count }
    var allDocumentsVerified: Bool {
        !documents.isEmpty && documents.allSatisfy { $0.status == .verified }
    }

    // Forwarded borrower / loan facts
    var borrowerName: String { base.borrowerName }
    var borrowerInitials: String { base.borrowerInitials }
    var loanType: LoanType { base.loanType }
    var loanTypeLabel: String { base.loanTypeLabel }
    var status: ApplicationStatus { base.status }
    var riskLevel: RiskLevel { base.riskLevel }
    var creditScore: Int { base.creditScore }
    var eligibilityScore: Int { base.eligibilityScore }
    var debtToIncomeRatio: Double { base.debtToIncomeRatio }
    var purpose: String { base.purpose }
    var tenureMonths: Int { base.tenure }

    // Display-formatted values
    var amountText: String { Formatting.currency(Decimal(base.loanAmount)) }
    var annualIncomeText: String { Formatting.currency(Decimal(base.monthlyIncome * 12)) }
    var emiText: String { Formatting.currency(Decimal(base.emiAmount)) }
    var referenceCode: String {
        "LN-" + base.id.uuidString.replacingOccurrences(of: "-", with: "").prefix(6).uppercased()
    }
    var subtitle: String { "\(referenceCode) • \(loanTypeLabel) Loan" }
    var tenureText: String {
        let years = tenureMonths / 12
        let months = tenureMonths % 12
        switch (years, months) {
        case (0, _): return "\(months) Months"
        case (_, 0): return years == 1 ? "1 Year" : "\(years) Years"
        default: return "\(years)y \(months)m"
        }
    }
}

// MARK: - Decision actions (approve / reject / send back)

// The terminal actions a manager can take on an application. Drives the
// review action bar, decision sheets, and the success screen copy.
enum ApplicationActionType: Hashable, Identifiable {
    case approve, reject, sendBack

    var id: Self { self }

    var themeColor: Color {
        switch self {
        case .approve: .lmsSuccess
        case .reject: .lmsDanger
        case .sendBack: .lmsWarning
        }
    }

    // Glyph for the success screen hero.
    var icon: String {
        switch self {
        case .approve: "checkmark"
        case .reject: "xmark"
        case .sendBack: "arrow.uturn.backward"
        }
    }

    // Glyph for recent-action rows on the dashboard.
    var rowIcon: String {
        switch self {
        case .approve: "checkmark.circle.fill"
        case .reject: "xmark.circle.fill"
        case .sendBack: "arrow.uturn.backward.circle.fill"
        }
    }

    var verb: String {
        switch self {
        case .approve: "Approved"
        case .reject: "Rejected"
        case .sendBack: "Returned"
        }
    }

    var resultStatus: ApplicationStatus {
        switch self {
        case .approve: .approved
        case .reject: .rejected
        case .sendBack: .additionalInfoRequired
        }
    }

    func successTitle() -> String {
        switch self {
        case .approve: "Application Approved"
        case .reject: "Application Rejected"
        case .sendBack: "Application Sent Back"
        }
    }

    func successSubtitle(applicant: String, reference: String, officer: String) -> String {
        switch self {
        case .approve: "\(applicant) (\(reference)) has been notified. Dashboard metrics updated."
        case .reject: "\(applicant) (\(reference)) has been notified of the rejection."
        case .sendBack: "Application returned to \(officer) for corrections."
        }
    }
}

// MARK: - Recent action feed item (dashboard)

struct ManagerRecentAction: Identifiable, Hashable {
    let id = UUID()
    let kind: ApplicationActionType
    let name: String
    let amount: String
    let date: Date

    var timeText: String { OfficerFormat.timeAgo(date) }
}

// MARK: - Navigation routes

// Centralized manager destinations, resolved once in `ManagerNavigationStack`
// so individual screens stay free of navigationDestination boilerplate.
enum ManagerRoute: Hashable {
    case applications
    case review(UUID)
    case notifications
}

// MARK: - Shared button press feedback

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}
