import SwiftUI

// MARK: - Risk Level (derived from credit score + DTI)

enum RiskLevel: String, CaseIterable, Codable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var tone: StatusBadge.Tone {
        switch self {
        case .low: .success
        case .medium: .warning
        case .high: .warning
        case .critical: .danger
        }
    }

    var icon: String {
        switch self {
        case .low: "checkmark.shield.fill"
        case .medium: "exclamationmark.triangle.fill"
        case .high: "exclamationmark.triangle.fill"
        case .critical: "xmark.octagon.fill"
        }
    }

    var gradient: [Color] {
        switch self {
        case .low: [.lmsSuccess, .lmsSuccess.opacity(0.7)]
        case .medium: [.lmsWarning, .lmsWarning.opacity(0.7)]
        case .high: [.lmsWarning, .lmsDanger]
        case .critical: [.lmsDanger, .lmsDanger.opacity(0.7)]
        }
    }

    var progress: Double {
        switch self {
        case .low: 0.25
        case .medium: 0.5
        case .high: 0.75
        case .critical: 1.0
        }
    }
}

// MARK: - Officer Application View Model

// A denormalized join of LoanApplication + borrower User + BorrowerProfile
// with extra officer-only data (employer, fraud flag, etc.). Built by the
// store; views never construct one directly.
struct OfficerApplication: Identifiable, Hashable {
    let application: LoanApplication
    let borrower: User
    let profile: BorrowerProfile?
    let employer: String
    let existingLiabilities: Decimal
    let purpose: String
    let fraudFlag: Bool

    var id: UUID { application.id }
    var borrowerName: String { borrower.fullName }
    var borrowerInitials: String { Self.initials(from: borrower.fullName) }
    var loanAmount: Decimal { application.requestedAmount }
    var creditScore: Int { profile?.creditScore ?? 0 }
    var monthlyIncome: Decimal { profile?.monthlyIncome ?? 0 }
    var tenure: Int { application.tenureMonths }
    var interestRate: Double { application.interestRate }
    var loanType: LoanType { application.loanType }
    var loanTypeLabel: String { application.loanType.rawValue.capitalized }
    var status: ApplicationStatus { application.status }
    var kycStatus: KYCStatus { profile?.kycStatus ?? .pending }
    var applicationDate: Date { application.createdAt }
    var phoneNumber: String { borrower.phone }
    var email: String { borrower.email }
    var employmentType: String {
        profile?.employmentType?.rawValue.capitalized ?? "—"
    }

    var emiAmount: Decimal {
        EMICalculator.calculate(
            principal: application.requestedAmount,
            annualInterestRate: application.interestRate,
            tenureMonths: application.tenureMonths
        ).monthlyInstallment
    }

    var totalPayable: Decimal { emiAmount * Decimal(tenure) }
    var totalInterest: Decimal { totalPayable - loanAmount }

    // Risk derived from credit score and DTI ratio.
    var riskLevel: RiskLevel {
        if fraudFlag || creditScore < 550 { return .critical }
        if creditScore < 650 { return .high }
        if creditScore < 750 || debtToIncomeRatio > 0.5 { return .medium }
        return .low
    }

    var debtToIncomeRatio: Double {
        guard monthlyIncome > 0 else { return 0 }
        let income = NSDecimalNumber(decimal: monthlyIncome).doubleValue
        let liabilities = NSDecimalNumber(decimal: existingLiabilities).doubleValue
        let emi = NSDecimalNumber(decimal: emiAmount).doubleValue
        return (liabilities + emi) / income
    }

    // 0-100 score: high credit + low DTI + verified KYC = high score.
    var eligibilityScore: Int {
        var score = 0
        score += min(50, max(0, (creditScore - 500) / 8))
        score += Int((1.0 - min(debtToIncomeRatio, 1.0)) * 30)
        if kycStatus == .verified { score += 15 }
        if !fraudFlag { score += 5 }
        return min(100, max(0, score))
    }

    private static func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last  = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}

// MARK: - Application Status Display

extension ApplicationStatus {
    var displayLabel: String {
        switch self {
        case .draft: "Draft"
        case .submitted: "Submitted"
        case .underReview: "Under Review"
        case .escalated: "Escalated"
        case .additionalInfoRequired: "Info Needed"
        case .recommended: "Recommended"
        case .approved: "Approved"
        case .rejected: "Rejected"
        case .disbursed: "Disbursed"
        case .closed: "Closed"
        }
    }

    var tone: StatusBadge.Tone {
        switch self {
        case .draft: .neutral
        case .submitted, .underReview: .info
        case .escalated, .additionalInfoRequired: .warning
        case .recommended, .approved, .disbursed: .success
        case .rejected: .danger
        case .closed: .neutral
        }
    }

    var icon: String {
        switch self {
        case .draft: "doc.text"
        case .submitted: "tray.and.arrow.up"
        case .underReview: "magnifyingglass"
        case .escalated: "arrow.up.right.circle.fill"
        case .additionalInfoRequired: "exclamationmark.bubble"
        case .recommended: "hand.thumbsup"
        case .approved: "checkmark.seal.fill"
        case .rejected: "xmark.octagon.fill"
        case .disbursed: "banknote.fill"
        case .closed: "lock.fill"
        }
    }
}

extension KYCStatus {
    var displayLabel: String { rawValue.capitalized }
    var tone: StatusBadge.Tone {
        switch self {
        case .pending: .warning
        case .submitted: .info
        case .verified: .success
        case .rejected: .danger
        }
    }
    var icon: String {
        switch self {
        case .pending: "clock"
        case .submitted: "paperplane"
        case .verified: "checkmark.seal.fill"
        case .rejected: "xmark.seal.fill"
        }
    }
}

// MARK: - Officer KPI

struct OfficerKPI: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let tint: Color
}

// MARK: - Officer Profile / Branch

struct OfficerProfileSummary: Hashable {
    let name: String
    let employeeID: String
    let branch: String
    var avatarInitials: String {
        name.split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
            .uppercased()
    }
}

// MARK: - Notifications (officer feed)

enum OfficerNotificationType: String, CaseIterable, Codable, Sendable {
    case fraudAlert = "Fraud Alert"
    case pendingApproval = "Pending Approval"
    case assignedApplication = "New Assignment"
    case overdueReminder = "Overdue EMI"
    case escalation = "Escalation"
    case system = "System"

    var tone: StatusBadge.Tone {
        switch self {
        case .fraudAlert: .danger
        case .pendingApproval: .warning
        case .assignedApplication: .info
        case .overdueReminder: .warning
        case .escalation: .danger
        case .system: .neutral
        }
    }

    var icon: String {
        switch self {
        case .fraudAlert: "exclamationmark.shield.fill"
        case .pendingApproval: "tray.and.arrow.down.fill"
        case .assignedApplication: "person.fill.badge.plus"
        case .overdueReminder: "clock.badge.exclamationmark.fill"
        case .escalation: "arrow.up.right.circle.fill"
        case .system: "bell.fill"
        }
    }

    var tint: Color {
        switch self {
        case .fraudAlert, .escalation: .lmsDanger
        case .pendingApproval, .overdueReminder: .lmsWarning
        case .assignedApplication, .system: .lmsInfo
        }
    }
}

struct OfficerNotification: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var message: String
    var timestamp: Date
    var type: OfficerNotificationType
    var priority: Int            // 1 = urgent, 2 = normal
    var isRead: Bool
}

// MARK: - Conversations (officer side of messaging)

enum MessageSender: Hashable { case officer, borrower }

struct ConversationMessage: Identifiable, Hashable {
    let id: UUID
    let sender: MessageSender
    let text: String
    let sentAt: Date
}

struct OfficerConversation: Identifiable, Hashable {
    let id: UUID                    // MessageThread.id
    let borrowerID: UUID
    let borrowerName: String
    let isOnline: Bool
    var messages: [ConversationMessage]
    var unreadCount: Int

    var lastMessage: String { messages.last?.text ?? "" }
    var lastMessageTime: Date { messages.last?.sentAt ?? .distantPast }
    var borrowerInitials: String {
        borrowerName.split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
            .uppercased()
    }
}

// MARK: - Document inspection (Loan Review)

enum DocReviewStatus: String, Codable, Sendable {
    case pending = "Pending"
    case verified = "Verified"
    case tampered = "Tampered"
    case duplicate = "Duplicate"
    case missing = "Missing"

    var tone: StatusBadge.Tone {
        switch self {
        case .pending: .warning
        case .verified: .success
        case .tampered, .missing: .danger
        case .duplicate: .info
        }
    }

    var icon: String {
        switch self {
        case .pending: "clock"
        case .verified: "checkmark.seal.fill"
        case .tampered: "exclamationmark.octagon.fill"
        case .duplicate: "doc.on.doc.fill"
        case .missing: "questionmark.square.dashed"
        }
    }
}

struct ReviewDocument: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var type: String
    var icon: String
    var status: DocReviewStatus
    var ocrVerified: Bool
    var uploadDate: Date?
}

// MARK: - Generated Documents (Sanction letters, reports, policies)

struct GeneratedDocument: Identifiable, Hashable {
    enum Category: String, CaseIterable {
        case sanctionLetter = "Sanction Letters"
        case report = "Reports"
        case policy = "Policies"

        var icon: String {
            switch self {
            case .sanctionLetter: "doc.richtext.fill"
            case .report: "chart.bar.doc.horizontal.fill"
            case .policy: "book.closed.fill"
            }
        }
    }

    let id = UUID()
    var title: String
    var category: Category
    var fileSize: String
    var generatedDate: Date
    var isSigned: Bool
    var borrowerAcknowledged: Bool
}

// MARK: - Collateral

struct CollateralValuation: Hashable {
    let date: Date
    let value: Decimal
}

struct LoanCollateral: Hashable {
    var propertyType: String
    var address: String
    var currentValuation: Decimal
    var lastValuationDate: Date
    var revaluationHistory: [CollateralValuation]
    // Ratio of collateral value to loan amount.
    var coverageRatio: Double
}

// MARK: - Recovery

enum RecoveryPriority: String, CaseIterable, Codable, Sendable {
    case urgent = "Urgent"
    case high = "High"
    case normal = "Normal"
    case low = "Low"

    var tone: StatusBadge.Tone {
        switch self {
        case .urgent: .danger
        case .high: .warning
        case .normal: .info
        case .low: .success
        }
    }

    var gradient: [Color] {
        switch self {
        case .urgent: [.lmsDanger, .lmsDanger.opacity(0.7)]
        case .high: [.lmsWarning, .lmsDanger]
        case .normal: [.lmsInfo, .lmsAccent]
        case .low: [.lmsSuccess, .lmsSuccess.opacity(0.7)]
        }
    }
}

struct OverdueBorrower: Identifiable, Hashable {
    let id: UUID
    let borrowerName: String
    let loanID: String
    let phoneNumber: String
    var dpdDays: Int
    var outstandingEMI: Decimal
    var totalOutstanding: Decimal
    var priority: RecoveryPriority
    var collectionEfficiency: Double  // 0-100
    var contacted: Bool

    var borrowerInitials: String {
        borrowerName.split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
            .uppercased()
    }
}

// MARK: - Navigation routes

enum OfficerRoute: Hashable {
    case allApplications
    case review(UUID)
    case communications
    case conversation(UUID)
    case notifications
    case recovery
    case recoveryDetail
    case documents
}

// MARK: - Currency formatter shared across officer screens

enum OfficerFormat {
    static func currency(_ amount: Decimal) -> String {
        Formatting.currency(amount)
    }

    static func currency(_ amount: Double) -> String {
        Formatting.currency(Decimal(amount))
    }

    static func date(_ date: Date) -> String {
        Formatting.date(date)
    }

    static func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}
