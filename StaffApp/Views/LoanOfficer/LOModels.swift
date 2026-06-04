import Foundation
import SwiftUI

// MARK: - Risk Level

enum RiskLevel: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var color: Color {
        switch self {
        case .low:
            return .green

        case .medium:
            return .orange

        case .high:
            return .red

        case .critical:
            return Color(
                red: 0.75,
                green: 0.05,
                blue: 0.05
            )
        }
    }

    var icon: String {
        switch self {
        case .low:
            return "checkmark.shield.fill"

        case .medium:
            return "exclamationmark.triangle.fill"

        case .high:
            return "xmark.shield.fill"

        case .critical:
            return "flame.fill"
        }
    }

    var tone: StatusBadge.Tone {
        switch self {
        case .low:
            return .success
        case .medium:
            return .warning
        case .high, .critical:
            return .danger
        }
    }
}

// MARK: - KYC Status

enum LOKYCStatus: String, CaseIterable, Codable {
    case verified = "Verified"
    case pending = "Pending"
    case rejected = "Rejected"
    case partial = "Partial"

    var color: Color {
        switch self {
        case .verified:
            return .green

        case .pending:
            return .orange

        case .rejected:
            return .red

        case .partial:
            return .yellow
        }
    }

    var icon: String {
        switch self {
        case .verified:
            return "checkmark.seal.fill"

        case .pending:
            return "clock.fill"

        case .rejected:
            return "xmark.seal.fill"

        case .partial:
            return "exclamationmark.circle.fill"
        }
    }
}

// MARK: - Loan Status

enum LOLoanStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
    case underReview = "Under Review"
    case escalated = "Escalated"
    case disbursed = "Disbursed"

    var color: Color {
        switch self {
        case .pending:
            return .orange

        case .approved:
            return .green

        case .rejected:
            return .red

        case .underReview:
            return .blue

        case .escalated:
            return .purple

        case .disbursed:
            return Color(
                red: 0.1,
                green: 0.65,
                blue: 0.4
            )
        }
    }

    var icon: String {
        switch self {
        case .pending:
            return "clock.fill"

        case .approved:
            return "checkmark.circle.fill"

        case .rejected:
            return "xmark.circle.fill"

        case .underReview:
            return "eye.fill"

        case .escalated:
            return "arrow.up.circle.fill"

        case .disbursed:
            return "banknote.fill"
        }
    }
}

// MARK: - Document Status

enum DocumentStatus: String, Codable {
    case verified = "Verified"
    case pending = "Pending"
    case missing = "Missing"
    case tampered = "Tampered"
    case duplicate = "Duplicate"
    case needsReview = "Needs Review"
    case rejected = "Rejected"

    var color: Color {
        switch self {
        case .verified:
            return .green

        case .pending:
            return .orange

        case .missing:
            return .red

        case .tampered:
            return Color(
                red: 0.75,
                green: 0,
                blue: 0
            )

        case .duplicate:
            return .purple

        case .needsReview:
            return .orange

        case .rejected:
            return .red
        }
    }

    var icon: String {
        switch self {
        case .verified:
            return "checkmark.circle.fill"

        case .pending:
            return "clock.fill"

        case .missing:
            return "exclamationmark.triangle.fill"

        case .tampered:
            return "xmark.octagon.fill"

        case .duplicate:
            return "doc.on.doc.fill"

        case .needsReview:
            return "questionmark.circle.fill"

        case .rejected:
            return "xmark.circle.fill"
        }
    }
}

// MARK: - Recovery Priority

enum RecoveryPriority: String, CaseIterable, Codable {
    case urgent = "Urgent"
    case high = "High"
    case normal = "Normal"
    case low = "Low"

    var color: Color {
        switch self {
        case .urgent:
            return .red

        case .high:
            return .orange

        case .normal:
            return .blue

        case .low:
            return .green
        }
    }

    var icon: String {
        switch self {
        case .urgent:
            return "exclamationmark.3"

        case .high:
            return "exclamationmark.2"

        case .normal:
            return "minus.circle.fill"

        case .low:
            return "arrow.down.circle.fill"
        }
    }
}

// MARK: - Visit Status

enum VisitStatus: String, Codable {
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case rescheduled = "Rescheduled"

    var color: Color {
        switch self {
        case .scheduled:
            return .blue

        case .inProgress:
            return .orange

        case .completed:
            return .green

        case .cancelled:
            return .red

        case .rescheduled:
            return .purple
        }
    }

    var icon: String {
        switch self {
        case .scheduled:
            return "calendar.badge.clock"

        case .inProgress:
            return "figure.walk"

        case .completed:
            return "checkmark.circle.fill"

        case .cancelled:
            return "xmark.circle.fill"

        case .rescheduled:
            return "arrow.clockwise"
        }
    }
}

// MARK: - Notification Type

enum NotificationType: String, Codable {
    case fraudAlert = "Fraud Alert"
    case pendingApproval = "Pending Approval"
    case assignedApplication = "Assigned Application"
    case overdueReminder = "Overdue Reminder"
    case escalation = "Escalation"
    case documentRequest = "Document Request"
    case system = "System"
    case systemUpdate = "System Update"

    var color: Color {
        switch self {
        case .fraudAlert:
            return .red

        case .pendingApproval:
            return .orange

        case .assignedApplication:
            return .blue

        case .overdueReminder:
            return .purple

        case .escalation:
            return Color(
                red: 0.8,
                green: 0.2,
                blue: 0
            )

        case .documentRequest:
            return .teal

        case .system:
            return .gray

        case .systemUpdate:
            return .gray
        }
    }

    var icon: String {
        switch self {
        case .fraudAlert:
            return "exclamationmark.shield.fill"

        case .pendingApproval:
            return "clock.badge.exclamationmark.fill"

        case .assignedApplication:
            return "person.badge.plus"

        case .overdueReminder:
            return "bell.badge.fill"

        case .escalation:
            return "arrow.up.message.fill"

        case .documentRequest:
            return "doc.badge.plus"

        case .system:
            return "gearshape.fill"

        case .systemUpdate:
            return "gearshape.fill"
        }
    }

    var tint: Color { color }
}

// MARK: - Message Type

enum MessageSender: String, Codable {
    case officer = "Officer"
    case borrower = "Borrower"
    case system = "System"
}

// MARK: - Activity Type

enum ActivityType: String, Codable {
    case newApplication = "New Application"
    case fraudDetected = "Fraud Detected"
    case pendingApproval = "Pending Approval"
    case overdueReminder = "Overdue Reminder"
    case escalation = "Escalation"
    case approved = "Approved"
    case documentUploaded = "Document Uploaded"

    var color: Color {
        switch self {
        case .newApplication:
            return .blue

        case .fraudDetected:
            return .red

        case .pendingApproval:
            return .orange

        case .overdueReminder:
            return .purple

        case .escalation:
            return Color(
                red: 0.8,
                green: 0.2,
                blue: 0
            )

        case .approved:
            return .green

        case .documentUploaded:
            return .teal
        }
    }

    var icon: String {
        switch self {
        case .newApplication:
            return "doc.badge.plus"

        case .fraudDetected:
            return "exclamationmark.shield.fill"

        case .pendingApproval:
            return "clock.badge.exclamationmark.fill"

        case .overdueReminder:
            return "bell.badge.fill"

        case .escalation:
            return "arrow.up.message.fill"

        case .approved:
            return "checkmark.circle.fill"

        case .documentUploaded:
            return "arrow.up.doc.fill"
        }
    }
}

// MARK: - Loan Officer Profile

struct LoanOfficerProfile: Identifiable {
    let id = UUID()

    var name: String
    var designation: String
    var branch: String
    var employeeId: String
    var avatarInitials: String
    var pendingTasks: Int
    var totalApproved: Int
    var approvalRate: Double
}

// MARK: - KPI Data

struct KPIData: Identifiable {
    let id = UUID()

    var title: String
    var value: Int
    var trend: Double
    var trendUp: Bool
    var icon: String
    var color: Color
    var chartData: [CGFloat]
}

// MARK: - Timeline Event

struct TimelineEvent: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var description: String
    var timestamp: Date
    var status: LOLoanStatus
    var officerName: String
}

// MARK: - Validation Issue

struct ValidationIssue: Identifiable, Hashable {
    let id = UUID()
    var message: String
    var isBlocker: Bool
}

// MARK: - Loan Application

struct LOLoanApplication: Identifiable, Hashable {

    let id = UUID()
    var sourceApplicationID: UUID? = nil
    var borrowerID: UUID? = nil

    var borrowerName: String
    var borrowerInitials: String

    var creditScore: Int
    var loanAmount: Double

    var riskLevel: RiskLevel
    var kycStatus: LOKYCStatus

    var fraudFlag: Bool
    var status: LOLoanStatus

    var applicationDate: Date

    var loanType: String
    var tenure: Int

    var interestRate: Double

    // IMPORTANT FIX
    // Changed from String -> String only
    // So existing UI continues working

    var employmentType: String

    var employer: String

    var monthlyIncome: Double
    var existingLiabilities: Double

    var eligibilityScore: Int
    var emiAmount: Double

    var phoneNumber: String
    var email: String
    var address: String

    var purpose: String
    
    var documents: [LOLoanDocument]
    var timeline: [TimelineEvent]
    
    // MARK: - Validation Checks
    var validationIssues: [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // 1. Credit Score
        if creditScore < 600 {
            issues.append(ValidationIssue(message: "Credit score is critically low (\(creditScore))", isBlocker: true))
        } else if creditScore < 680 {
            issues.append(ValidationIssue(message: "Credit score is moderate (\(creditScore)), requires caution", isBlocker: false))
        }
        
        // 2. KYC Status
        if kycStatus != .verified {
            issues.append(ValidationIssue(message: "KYC verification is incomplete (Current: \(kycStatus.rawValue))", isBlocker: true))
        }
        
        // 3. Fraud Flag
        if fraudFlag {
            issues.append(ValidationIssue(message: "Security Alert: Potential fraud flagged for this borrower", isBlocker: true))
        }
        
        // 4. Monthly Income
        if monthlyIncome <= 0 && loanType != "Education Loan" {
            issues.append(ValidationIssue(message: "Reported monthly income is zero or missing", isBlocker: true))
        }
        
        // 5. Document verification
        for doc in documents {
            switch doc.status {
            case .missing:
                issues.append(ValidationIssue(message: "Missing required document: \(doc.name)", isBlocker: true))
            case .tampered:
                issues.append(ValidationIssue(message: "Security Alert: Tampered document detected (\(doc.name))", isBlocker: true))
            case .duplicate:
                issues.append(ValidationIssue(message: "Duplicate document detected: \(doc.name)", isBlocker: false))
            case .pending:
                issues.append(ValidationIssue(message: "Pending verification: \(doc.name)", isBlocker: true))
            case .needsReview:
                issues.append(ValidationIssue(message: "Needs manual review: \(doc.name)", isBlocker: true))
            case .rejected:
                issues.append(ValidationIssue(message: "Rejected document: \(doc.name)", isBlocker: true))
            case .verified:
                break
            }
        }
        
        return issues
    }
    
    var canProceedToApproval: Bool {
        return !validationIssues.contains(where: { $0.isBlocker })
    }
}

extension LOLoanStatus {
    var sharedStatus: ApplicationStatus {
        switch self {
        case .pending:
            return .submitted
        case .approved:
            return .recommended
        case .rejected:
            return .rejected
        case .underReview:
            return .underReview
        case .escalated:
            return .escalated
        case .disbursed:
            return .approved
        }
    }
}

extension ApplicationStatus {
    var officerStatus: LOLoanStatus {
        switch self {
        case .draft, .submitted:
            return .pending
        case .underReview:
            return .underReview
        case .escalated:
            return .escalated
        case .additionalInfoRequired:
            return .underReview
        case .recommended, .approved, .disbursed:
            return .approved
        case .rejected:
            return .rejected
        case .closed:
            return .disbursed
        }
    }
}

// MARK: - Loan Document

struct LOLoanDocument: Identifiable, Hashable {
    let id = UUID()
    var sourceDocumentID: UUID? = nil

    var name: String
    var type: String
    var status: DocumentStatus
    var uploadDate: Date?
    var ocrVerified: Bool
    var icon: String

    var reviewNotes: String? = nil
    var rejectionReason: String? = nil
}

// MARK: - Collateral

struct CollateralInfo: Identifiable {
    let id = UUID()

    var propertyType: String
    var address: String
    var currentValuation: Double
    var lastValuationDate: Date
    var coverageRatio: Double
    var revaluationHistory: [(date: Date, value: Double)]
}

// MARK: - Overdue Borrower

struct OverdueBorrower: Identifiable {
    let id = UUID()

    var borrowerName: String
    var borrowerInitials: String
    var loanId: String

    var dpdDays: Int

    var outstandingEMI: Double
    var totalOutstanding: Double

    var priority: RecoveryPriority

    var lastContactDate: Date?

    var phoneNumber: String

    var collectionEfficiency: Double

    var contactAttempts: Int
}

// MARK: - Field Visit

struct FieldVisit: Identifiable {
    let id = UUID()

    var borrowerName: String
    var address: String

    var scheduledDate: Date

    var status: VisitStatus

    var assignedOfficer: String
    var purpose: String

    var checklistCompleted: Int
    var checklistTotal: Int

    var latitude: Double
    var longitude: Double
}

// MARK: - Notification

struct AppNotification: Identifiable {
    let id = UUID()

    var title: String
    var message: String

    var type: NotificationType

    var timestamp: Date

    var isRead: Bool

    var priority: Int
}

// MARK: - Chat Message

struct LOChatMessage: Identifiable, Hashable, Equatable {
    let id = UUID()

    var text: String
    var sender: MessageSender
    var timestamp: Date
    var isRead: Bool

    var attachmentName: String?
    var attachmentIcon: String?
}

// MARK: - Borrower Conversation

struct BorrowerConversation: Identifiable, Hashable, Equatable {
    var id: UUID
    var applicationID: UUID?

    var borrowerName: String
    var borrowerInitials: String

    var lastMessage: String
    var lastMessageTime: Date

    var unreadCount: Int

    var messages: [LOChatMessage]

    var isOnline: Bool
}

// MARK: - Activity

struct ActivityItem: Identifiable {
    let id = UUID()

    var title: String
    var subtitle: String

    var type: ActivityType

    var timestamp: Date
}

// MARK: - Digital Document

struct DigitalDocument: Identifiable {
    let id = UUID()

    var title: String
    var type: String
    var icon: String
    var fileSize: String
    var generatedDate: Date
    var isSigned: Bool
    var borrowerAcknowledged: Bool
}

// MARK: - Quick Action

struct QuickAction: Identifiable {
    let id = UUID()

    var title: String
    var icon: String

    var color: Color
    var gradient: [Color]

    var pendingCount: Int

    var destination: AppDestination
}

// MARK: - App Destination

enum AppDestination: Hashable {
    case loanReview
    case recovery
    case fraudAlerts
    case messages
    case communications
    case allapplications
    case notifications
    case documents
    case profile
    case chat(BorrowerConversation)
}

// MARK: - Formatters

struct AppFormatters {
    static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "₹"
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "en_IN")
        return f
    }()

    static func formatCurrency(_ value: Double) -> String {
        if value >= 10000000 {
            return String(format: "₹%.1f Cr", value / 10000000)
        } else if value >= 100000 {
            return String(format: "₹%.1f L", value / 100000)
        } else {
            return currencyFormatter.string(from: NSNumber(value: value)) ?? "₹\(Int(value))"
        }
    }

    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    static func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        if interval < 604800 { return "\(Int(interval / 86400))d ago" }
        return formatDate(date)
    }
}
