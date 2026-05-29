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

    var id: UUID { base.id }

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
    var applicationID: UUID? = nil

    var timeText: String { OfficerFormat.timeAgo(date) }
}

// MARK: - Navigation routes

// Centralized manager destinations, resolved once in `ManagerNavigationStack`
// so individual screens stay free of navigationDestination boilerplate.
enum ManagerRoute: Hashable {
    case applications
    case applicationsFiltered(ManagerApplicationsView.Filter)
    case review(UUID)
    case notifications
    case officerPerformance
    case officerDetail(String)          // officer name as identifier
    case auditLogs
    case loanPolicies
    case riskAlerts
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

// MARK: - Portfolio models

struct PortfolioSummaryData: Hashable {
    var totalLoans: Int
    var totalDisbursement: Decimal
    var collectionEfficiency: Double   // 0–1
    var npaRatio: Double               // 0–1
    var activeLoans: Int
    var overdueLoans: Int
    var recoveryRate: Double           // 0–1
    var paidEMIPercent: Double         // 0–1
}

struct LoanCategoryBreakdown: Identifiable, Hashable {
    let id = UUID()
    var loanType: LoanType
    var count: Int
    var amount: Decimal
    var percentage: Double             // 0–1

    var amountText: String { Formatting.currency(amount) }
}

struct BranchPerformanceItem: Identifiable, Hashable {
    let id = UUID()
    var branchName: String
    var approvalRate: Double
    var avgDecisionTime: String
    var totalApplications: Int
    var npaRatio: Double
}

// MARK: - Officer performance

struct OfficerPerformanceData: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var initials: String
    var applicationsProcessed: Int
    var approvalRate: Double           // 0–1
    var avgDecisionTime: String
    var recoveryRate: Double           // 0–1
    var recentDecisions: [OfficerDecisionRecord]
}

struct OfficerDecisionRecord: Identifiable, Hashable {
    let id = UUID()
    var applicantName: String
    var amount: String
    var action: ApplicationActionType
    var date: Date

    var timeText: String { OfficerFormat.timeAgo(date) }
}

// MARK: - Audit logs

struct ManagerAuditLogEntry: Identifiable, Hashable {
    let id = UUID()
    var loanReferenceCode: String
    var action: String
    var managerName: String
    var timestamp: Date
    var status: AuditStatus

    var dateText: String { Formatting.date(timestamp) }
    var timeText: String { timestamp.formatted(date: .omitted, time: .shortened) }
}

enum AuditStatus: String, CaseIterable, Hashable {
    case completed = "Completed"
    case pending = "Pending"
    case failed = "Failed"

    var tone: StatusBadge.Tone {
        switch self {
        case .completed: .success
        case .pending: .warning
        case .failed: .danger
        }
    }
}

// MARK: - Reports

struct ReportItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var type: ReportKind
    var format: ReportFormat
    var size: String
    var generatedAt: Date
    var status: ReportStatus

    var dateText: String { OfficerFormat.timeAgo(generatedAt) }

    var formatIcon: String {
        switch format {
        case .csv: "tablecells"
        case .pdf: "doc.richtext"
        }
    }

    var formatColor: Color {
        switch format {
        case .csv: .lmsSuccess
        case .pdf: .lmsDanger
        }
    }
}

enum ReportStatus: String, Hashable {
    case generating = "Generating"
    case completed = "Completed"
    case failed = "Failed"

    var tone: StatusBadge.Tone {
        switch self {
        case .generating: .info
        case .completed: .success
        case .failed: .danger
        }
    }

    var icon: String {
        switch self {
        case .generating: "arrow.trianglehead.2.clockwise"
        case .completed: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Risk alerts

struct RiskAlert: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var message: String
    var severity: RiskAlertSeverity
    var loanReferenceCode: String
    var timestamp: Date
    var isRead: Bool

    var timeText: String { OfficerFormat.timeAgo(timestamp) }
}

enum RiskAlertSeverity: String, CaseIterable, Hashable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"

    var tone: StatusBadge.Tone {
        switch self {
        case .critical: .danger
        case .high: .warning
        case .medium: .info
        }
    }

    var icon: String {
        switch self {
        case .critical: "exclamationmark.octagon.fill"
        case .high: "exclamationmark.triangle.fill"
        case .medium: "info.circle.fill"
        }
    }
}

// MARK: - Loan policies

struct LoanPolicyConfig: Identifiable, Hashable {
    let id = UUID()
    var loanType: LoanType
    var interestRateMin: Double
    var interestRateMax: Double
    var maxTenureMonths: Int
    var maxAmount: Decimal
    var minCreditScore: Int
    var maxDTIRatio: Double
    var isActive: Bool

    var interestRangeText: String {
        "\(String(format: "%.1f", interestRateMin))% – \(String(format: "%.1f", interestRateMax))%"
    }
    var maxAmountText: String { Formatting.currency(maxAmount) }
    var maxTenureText: String {
        let years = maxTenureMonths / 12
        return years > 0 ? "\(years) Years" : "\(maxTenureMonths) Months"
    }
}

// MARK: - Detailed Report Entities

struct OverdueCustomer: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let daysLate: Int
    let pendingAmount: Decimal
}

struct DailyReportData: Hashable {
    let loansApproved: Int
    let totalAmount: Decimal
    let activeLoans: Int
    let emiCollected: Decimal
    let pendingCollections: Decimal
    let newCustomers: Int
    let missedPayments: Int
}

struct WeeklyReportData: Hashable {
    let weeklyLoanGrowth: Double // percentage
    let totalRepaymentCollected: Decimal
    let numberOfDefaults: Int
    let recoveryPerformance: Double // percentage
    let topPayingCustomers: Int
}

struct LoanTypeAnalytics: Identifiable, Hashable {
    let id = UUID()
    let type: String
    let percentage: Double
    let color: Color
}

struct MonthlyReportData: Hashable {
    let monthlyRevenue: Decimal
    let totalDistributed: Decimal
    let loanRecoveryRate: Double
    let totalProfit: Decimal
    let interestEarned: Decimal
    let penaltyCollected: Decimal
    let processingFees: Decimal
    let bestPerformingCategory: String
    let loanTypeAnalytics: [LoanTypeAnalytics]
}
