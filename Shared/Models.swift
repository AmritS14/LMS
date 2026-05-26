import Foundation

// MARK: - User (identity common to every role)

enum UserRole: String, Codable, Sendable, CaseIterable {
    case borrower
    case loanOfficer
    case manager
    case admin

    var displayName: String {
        switch self {
        case .borrower: return "Borrower"
        case .loanOfficer: return "Loan Officer"
        case .manager: return "Manager"
        case .admin: return "Admin"
        }
    }
}

struct User: Identifiable, Codable, Sendable, Hashable {
    var id: UUID = UUID()
    var fullName: String
    var email: String
    var phone: String
    var role: UserRole
    var isActive: Bool = true
    var createdAt: Date = .now

    var uniqueID: String {
        "USR-\(id.uuidString.prefix(8).uppercased())"
    }
}

// MARK: - Borrower-only profile (KYC, credit, personal details)

enum KYCStatus: String, Codable, Sendable {
    case pending, submitted, verified, rejected
}

enum EmploymentType: String, Codable, Sendable, CaseIterable {
    case salaried, selfEmployed, business, retired, unemployed
}

struct PostalAddress: Codable, Sendable, Hashable {
    var line1: String
    var line2: String?
    var city: String
    var state: String
    var pinCode: Int
    var country: String
}

struct BorrowerProfile: Identifiable, Codable, Sendable, Hashable {
    var id: UUID            // matches User.id
    var dateOfBirth: Date
    var address: PostalAddress?
    var panNumber: String?
    var aadhaarLast4: String?
    var employmentType: EmploymentType?
    var monthlyIncome: Decimal?
    var kycStatus: KYCStatus = .pending
    var creditScore: Int?
}

// MARK: - Staff-only profile (Officer, Manager, Admin)

struct StaffProfile: Identifiable, Codable, Sendable, Hashable {
    var id: UUID            // matches User.id
    var employeeID: String
    var branchID: UUID?
    var department: String?
    var reportsToID: UUID?
    var permissions: Set<Permission> = []
}

enum Permission: String, Codable, Sendable, CaseIterable, Identifiable {
    case viewUsers = "View Users"
    case editUsers = "Edit Users"
    case viewAudit = "View Audit"
    case manageSettings = "Manage Settings"

    var id: String { rawValue }
}

// MARK: - Loan Application

enum LoanType: String, Codable, Sendable, CaseIterable, Identifiable {
    case personal, home, vehicle, education, business
    var id: String { rawValue }
}

struct LoanProduct: Identifiable, Codable, Sendable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String?
    var minimumAmount: Decimal
    var maximumAmount: Decimal
    var minimumTenureMonths: Int
    var maximumTenureMonths: Int
    var minimumInterestRate: Double
    var maximumInterestRate: Double
    var isActive: Bool = true

    /// Best-guess LoanType derived from the product name
    var loanType: LoanType {
        let lower = name.lowercased()
        if lower.contains("home") { return .home }
        if lower.contains("vehicle") || lower.contains("auto") { return .vehicle }
        if lower.contains("education") { return .education }
        if lower.contains("business") { return .business }
        return .personal
    }

    /// Icon for the product
    var icon: String {
        switch loanType {
        case .home: return "house.fill"
        case .personal: return "person.fill"
        case .vehicle: return "car.fill"
        case .business: return "briefcase.fill"
        case .education: return "book.closed.fill"
        }
    }

    /// Midpoint interest rate for display
    var displayRate: Double {
        (minimumInterestRate + maximumInterestRate) / 2.0
    }
}

enum ApplicationStatus: String, Codable, Sendable {
    case draft
    case submitted
    case underReview
    case escalated
    case additionalInfoRequired
    case recommended
    case approved
    case rejected
    case disbursed
    case closed
}

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

struct LoanApplication: Identifiable, Codable, Sendable, Hashable {
    var id: UUID = UUID()
    var borrowerID: UUID
    var assignedOfficerID: UUID?
    var loanType: LoanType
    var requestedAmount: Decimal
    var tenureMonths: Int
    var interestRate: Double
    var status: ApplicationStatus = .draft
    var documentIDs: [UUID] = []
    var createdAt: Date = .now
    var updatedAt: Date = .now
}

struct ApplicationEvent: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var applicationID: UUID
    var actorID: UUID?
    var eventType: String
    var remark: String?
    var fromStatus: String?
    var toStatus: String?
    var createdAt: Date = .now
}

// MARK: - Loan & EMI

enum EMIStatus: String, Codable, Sendable {
    case upcoming, paid, overdue
}

struct EMI: Identifiable, Codable, Sendable, Hashable {
    var id: UUID = UUID()
    var installmentNumber: Int
    var dueDate: Date
    var principalComponent: Decimal
    var interestComponent: Decimal
    var totalAmount: Decimal
    var status: EMIStatus = .upcoming
    var paidAt: Date?
}

enum LoanStatus: String, Codable, Sendable {
    case active, settled, defaulted
}

struct Loan: Identifiable, Codable, Sendable, Hashable {
    var id: UUID = UUID()
    var applicationID: UUID
    var borrowerID: UUID
    var loanType: LoanType = .personal
    var principal: Decimal
    var interestRate: Double
    var tenureMonths: Int
    var disbursementDate: Date
    var outstandingBalance: Decimal
    var emiSchedule: [EMI] = []
    var status: LoanStatus = .active
}

// MARK: - Documents

enum DocumentKind: String, Codable, Sendable, CaseIterable {
    case identityProof
    case addressProof
    case incomeProof
    case bankStatement
    case collateral
    case other
}

enum DocumentVerificationStatus: String, Codable, Sendable {
    case pending, verified, rejected
}

struct LoanDocument: Identifiable, Codable, Sendable, Hashable {
    var id: UUID = UUID()
    var ownerID: UUID
    var kind: DocumentKind
    var fileName: String
    var mimeType: String
    var remoteURL: URL?
    var status: DocumentVerificationStatus = .pending
    var uploadedAt: Date = .now
}

// MARK: - Messaging

struct ChatMessage: Identifiable, Codable, Sendable, Hashable {
    var id: UUID = UUID()
    var threadID: UUID
    var senderID: UUID
    var body: String
    var sentAt: Date = .now
    var readAt: Date?
}

struct MessageThread: Identifiable, Codable, Sendable, Hashable {
    var id: UUID = UUID()
    var participantIDs: [UUID]
    var applicationID: UUID?
    var lastMessagePreview: String?
    var updatedAt: Date = .now
}

// MARK: - Audit

struct AuditEntry: Identifiable, Codable, Sendable, Hashable {
    var id: UUID = UUID()
    var actorID: UUID
    var actorRole: UserRole
    var action: String
    var entityType: String
    var entityID: UUID
    var metadata: [String: String] = [:]
    var timestamp: Date = .now
}

// MARK: - Reporting

enum ReportKind: String, Sendable {
    case daily, weekly, monthly, npa, collectionEfficiency
}

enum ReportFormat: String, Sendable {
    case pdf, csv
}

struct PortfolioSummary: Codable, Sendable, Hashable {
    var totalDisbursed: Decimal
    var outstandingPrincipal: Decimal
    var collectionEfficiency: Double
    var npaRatio: Double
    var activeLoans: Int
}

// MARK: - Notifications

enum NotificationTopic: String, Codable, Sendable {
    case emiDue, emiOverdue, applicationStatus, disbursement, message, system
}

struct PushNotification: Identifiable, Codable, Sendable, Hashable {
    var id: UUID = UUID()
    var topic: NotificationTopic
    var title: String
    var body: String
    var deepLink: URL?
    var receivedAt: Date = .now
}
