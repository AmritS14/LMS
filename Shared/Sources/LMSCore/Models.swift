import Foundation

// MARK: - User

public enum UserRole: String, Codable, Sendable, CaseIterable {
    case borrower
    case loanOfficer
    case manager
    case admin
}

public enum KYCStatus: String, Codable, Sendable {
    case pending, submitted, verified, rejected
}

public struct User: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var fullName: String
    public var email: String
    public var phone: String
    public var role: UserRole
    public var kycStatus: KYCStatus
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        fullName: String,
        email: String,
        phone: String,
        role: UserRole,
        kycStatus: KYCStatus = .pending,
        createdAt: Date = .now
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.role = role
        self.kycStatus = kycStatus
        self.createdAt = createdAt
    }
}

// MARK: - Loan Application

public enum LoanType: String, Codable, Sendable, CaseIterable, Identifiable {
    case personal, home, vehicle, education, business
    public var id: String { rawValue }
}

public enum ApplicationStatus: String, Codable, Sendable {
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

public struct LoanApplication: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var borrowerID: UUID
    public var assignedOfficerID: UUID?
    public var loanType: LoanType
    public var requestedAmount: Decimal
    public var tenureMonths: Int
    public var interestRate: Double
    public var status: ApplicationStatus
    public var documentIDs: [UUID]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        borrowerID: UUID,
        assignedOfficerID: UUID? = nil,
        loanType: LoanType,
        requestedAmount: Decimal,
        tenureMonths: Int,
        interestRate: Double,
        status: ApplicationStatus = .draft,
        documentIDs: [UUID] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.borrowerID = borrowerID
        self.assignedOfficerID = assignedOfficerID
        self.loanType = loanType
        self.requestedAmount = requestedAmount
        self.tenureMonths = tenureMonths
        self.interestRate = interestRate
        self.status = status
        self.documentIDs = documentIDs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Loan & EMI

public enum EMIStatus: String, Codable, Sendable {
    case upcoming, paid, overdue
}

public struct EMI: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var installmentNumber: Int
    public var dueDate: Date
    public var principalComponent: Decimal
    public var interestComponent: Decimal
    public var totalAmount: Decimal
    public var status: EMIStatus
    public var paidAt: Date?

    public init(
        id: UUID = UUID(),
        installmentNumber: Int,
        dueDate: Date,
        principalComponent: Decimal,
        interestComponent: Decimal,
        totalAmount: Decimal,
        status: EMIStatus = .upcoming,
        paidAt: Date? = nil
    ) {
        self.id = id
        self.installmentNumber = installmentNumber
        self.dueDate = dueDate
        self.principalComponent = principalComponent
        self.interestComponent = interestComponent
        self.totalAmount = totalAmount
        self.status = status
        self.paidAt = paidAt
    }
}

public struct Loan: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var applicationID: UUID
    public var borrowerID: UUID
    public var principal: Decimal
    public var interestRate: Double
    public var tenureMonths: Int
    public var disbursementDate: Date
    public var outstandingBalance: Decimal
    public var emiSchedule: [EMI]

    public init(
        id: UUID = UUID(),
        applicationID: UUID,
        borrowerID: UUID,
        principal: Decimal,
        interestRate: Double,
        tenureMonths: Int,
        disbursementDate: Date,
        outstandingBalance: Decimal,
        emiSchedule: [EMI] = []
    ) {
        self.id = id
        self.applicationID = applicationID
        self.borrowerID = borrowerID
        self.principal = principal
        self.interestRate = interestRate
        self.tenureMonths = tenureMonths
        self.disbursementDate = disbursementDate
        self.outstandingBalance = outstandingBalance
        self.emiSchedule = emiSchedule
    }
}

// MARK: - Documents

public enum DocumentKind: String, Codable, Sendable, CaseIterable {
    case identityProof
    case addressProof
    case incomeProof
    case bankStatement
    case collateral
    case other
}

public enum DocumentVerificationStatus: String, Codable, Sendable {
    case pending, verified, rejected
}

public struct LoanDocument: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var ownerID: UUID
    public var kind: DocumentKind
    public var fileName: String
    public var mimeType: String
    public var remoteURL: URL?
    public var status: DocumentVerificationStatus
    public var uploadedAt: Date

    public init(
        id: UUID = UUID(),
        ownerID: UUID,
        kind: DocumentKind,
        fileName: String,
        mimeType: String,
        remoteURL: URL? = nil,
        status: DocumentVerificationStatus = .pending,
        uploadedAt: Date = .now
    ) {
        self.id = id
        self.ownerID = ownerID
        self.kind = kind
        self.fileName = fileName
        self.mimeType = mimeType
        self.remoteURL = remoteURL
        self.status = status
        self.uploadedAt = uploadedAt
    }
}

// MARK: - Messaging

public struct ChatMessage: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var threadID: UUID
    public var senderID: UUID
    public var body: String
    public var sentAt: Date
    public var readAt: Date?

    public init(
        id: UUID = UUID(),
        threadID: UUID,
        senderID: UUID,
        body: String,
        sentAt: Date = .now,
        readAt: Date? = nil
    ) {
        self.id = id
        self.threadID = threadID
        self.senderID = senderID
        self.body = body
        self.sentAt = sentAt
        self.readAt = readAt
    }
}

public struct MessageThread: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var participantIDs: [UUID]
    public var applicationID: UUID?
    public var lastMessagePreview: String?
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        participantIDs: [UUID],
        applicationID: UUID? = nil,
        lastMessagePreview: String? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.participantIDs = participantIDs
        self.applicationID = applicationID
        self.lastMessagePreview = lastMessagePreview
        self.updatedAt = updatedAt
    }
}

// MARK: - Audit

public struct AuditEntry: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var actorID: UUID
    public var actorRole: UserRole
    public var action: String
    public var entityType: String
    public var entityID: UUID
    public var metadata: [String: String]
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        actorID: UUID,
        actorRole: UserRole,
        action: String,
        entityType: String,
        entityID: UUID,
        metadata: [String: String] = [:],
        timestamp: Date = .now
    ) {
        self.id = id
        self.actorID = actorID
        self.actorRole = actorRole
        self.action = action
        self.entityType = entityType
        self.entityID = entityID
        self.metadata = metadata
        self.timestamp = timestamp
    }
}

// MARK: - Reporting value types

public enum ReportKind: String, Sendable {
    case daily, weekly, monthly, npa, collectionEfficiency
}

public enum ReportFormat: String, Sendable {
    case pdf, csv
}

public struct PortfolioSummary: Codable, Sendable, Hashable {
    public var totalDisbursed: Decimal
    public var outstandingPrincipal: Decimal
    public var collectionEfficiency: Double
    public var npaRatio: Double
    public var activeLoans: Int

    public init(
        totalDisbursed: Decimal,
        outstandingPrincipal: Decimal,
        collectionEfficiency: Double,
        npaRatio: Double,
        activeLoans: Int
    ) {
        self.totalDisbursed = totalDisbursed
        self.outstandingPrincipal = outstandingPrincipal
        self.collectionEfficiency = collectionEfficiency
        self.npaRatio = npaRatio
        self.activeLoans = activeLoans
    }
}

// MARK: - Notifications

public enum NotificationTopic: String, Codable, Sendable {
    case emiDue, emiOverdue, applicationStatus, disbursement, message, system
}

public struct PushNotification: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var topic: NotificationTopic
    public var title: String
    public var body: String
    public var deepLink: URL?
    public var receivedAt: Date

    public init(
        id: UUID = UUID(),
        topic: NotificationTopic,
        title: String,
        body: String,
        deepLink: URL? = nil,
        receivedAt: Date = .now
    ) {
        self.id = id
        self.topic = topic
        self.title = title
        self.body = body
        self.deepLink = deepLink
        self.receivedAt = receivedAt
    }
}
