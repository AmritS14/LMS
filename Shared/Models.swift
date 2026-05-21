import Foundation

// MARK: - User (identity common to every role)

enum UserRole: String, Codable, Sendable, CaseIterable {
    case borrower
    case loanOfficer
    case manager
    case admin
}

struct User: Identifiable, Codable, Sendable, Hashable {
    var id: UUID = UUID()
    var fullName: String
    var email: String
    var phone: String
    var role: UserRole
    var createdAt: Date = .now
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
}

// MARK: - Loan Application

enum LoanType: String, Codable, Sendable, CaseIterable, Identifiable {
    case personal, home, vehicle, education, business
    var id: String { rawValue }
}

enum ApplicationStatus: String, Codable, Sendable {
    case draft
    case submitted
    case underReview
    case additionalInfoRequired
    case recommended
    case approved
    case rejected
    case disbursed
    case closed
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
