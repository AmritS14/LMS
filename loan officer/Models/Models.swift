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
}

// MARK: - KYC Status

enum KYCStatus: String, CaseIterable, Codable {
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

enum LoanStatus: String, CaseIterable, Codable {
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

        case .systemUpdate:
            return "gearshape.fill"
        }
    }
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
    var status: LoanStatus
    var officerName: String
}

// MARK: - Validation Issue

struct ValidationIssue: Identifiable, Hashable {
    let id = UUID()
    var message: String
    var isBlocker: Bool
}

// MARK: - Loan Application

struct LoanApplication: Identifiable, Hashable {

    let id = UUID()

    var borrowerName: String
    var borrowerInitials: String

    var creditScore: Int
    var loanAmount: Double

    var riskLevel: RiskLevel
    var kycStatus: KYCStatus

    var fraudFlag: Bool
    var status: LoanStatus

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
    
    var documents: [LoanDocument]
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

// MARK: - Loan Document

struct LoanDocument: Identifiable, Hashable {
    let id = UUID()

    var name: String
    var type: String
    var status: DocumentStatus
    var uploadDate: Date?
    var ocrVerified: Bool
    var icon: String
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

struct ChatMessage: Identifiable {
    let id = UUID()

    var text: String
    var sender: MessageSender
    var timestamp: Date
    var isRead: Bool

    var attachmentName: String?
    var attachmentIcon: String?
}

// MARK: - Borrower Conversation

struct BorrowerConversation: Identifiable {
    let id = UUID()

    var borrowerName: String
    var borrowerInitials: String

    var lastMessage: String
    var lastMessageTime: Date

    var unreadCount: Int

    var messages: [ChatMessage]

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
    case recoveryManagement
    case notifications
    case documents
    case profile
}


// MARK: - Sample Data

struct SampleData {

    static let officerProfile = LoanOfficerProfile(
        name: "Rajesh Kumar",
        designation: "Senior Loan Officer",
        branch: "Mumbai Central",
        employeeId: "EMP-2847",
        avatarInitials: "RK",
        pendingTasks: 23,
        totalApproved: 342,
        approvalRate: 78.5
    )

    static let kpiData: [KPIData] = [
        KPIData(title: "Pending\nApplications", value: 47, trend: 12.3, trendUp: true, icon: "doc.text.fill", color: .orange, chartData: [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.75]),
        KPIData(title: "Approved\nLoans", value: 132, trend: 8.7, trendUp: true, icon: "checkmark.circle.fill", color: .green, chartData: [0.4, 0.5, 0.55, 0.6, 0.65, 0.7, 0.8]),
        KPIData(title: "Escalated\nCases", value: 8, trend: -3.2, trendUp: false, icon: "arrow.up.circle.fill", color: .purple, chartData: [0.6, 0.7, 0.5, 0.4, 0.45, 0.35, 0.3]),
//        KPIData(title: "Fraud\nAlerts", value: 5, trend: 25.0, trendUp: true, icon: "exclamationmark.shield.fill", color: .red, chartData: [0.2, 0.3, 0.25, 0.4, 0.5, 0.6, 0.7]),
        KPIData(title: "Overdue\nBorrowers", value: 19, trend: -5.1, trendUp: false, icon: "person.crop.circle.badge.exclamationmark.fill", color: Color(red: 0.8, green: 0.4, blue: 0), chartData: [0.7, 0.65, 0.6, 0.55, 0.5, 0.45, 0.4]),
//        KPIData(title: "Field\nVisits", value: 12, trend: 15.0, trendUp: true, icon: "mappin.circle.fill", color: .teal, chartData: [0.3, 0.4, 0.5, 0.45, 0.6, 0.7, 0.75])
    ]

    static let quickActions: [QuickAction] = [
        QuickAction(title: "Review\nApplications", icon: "doc.text.magnifyingglass", color: .blue, gradient: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.1, green: 0.3, blue: 0.9)], pendingCount: 47, destination: .loanReview),
        QuickAction(title: "Recovery\nManagement", icon: "arrow.uturn.backward.circle.fill", color: .orange, gradient: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.9, green: 0.4, blue: 0.1)], pendingCount: 19, destination: .recovery),
//        QuickAction(title: "Field\nVerification", icon: "mappin.and.ellipse", color: .teal, gradient: [Color(red: 0.2, green: 0.7, blue: 0.7), Color(red: 0.1, green: 0.55, blue: 0.6)], pendingCount: 12, destination: .fieldVerification),
//        QuickAction(title: "Fraud\nAlerts", icon: "exclamationmark.shield.fill", color: .red, gradient: [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 0.85, green: 0.15, blue: 0.15)], pendingCount: 5, destination: .fraudAlerts),
        QuickAction(title: "Borrower\nMessages", icon: "bubble.left.and.bubble.right.fill", color: .indigo, gradient: [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.25, green: 0.2, blue: 0.8)], pendingCount: 8, destination: .messages),
//        QuickAction(title: "Notification\nCenter", icon: "bell.badge.fill", color: .purple, gradient: [Color(red: 0.7, green: 0.3, blue: 0.9), Color(red: 0.55, green: 0.2, blue: 0.8)], pendingCount: 15, destination: .notifications),
//        QuickAction(title: "Digital\nDocuments", icon: "doc.richtext.fill", color: .cyan, gradient: [Color(red: 0.2, green: 0.75, blue: 0.9), Color(red: 0.1, green: 0.6, blue: 0.8)], pendingCount: 6, destination: .documents)
    ]

    static let recentApplications: [LoanApplication] = [
        LoanApplication(
            borrowerName: "Priya Sharma",
            borrowerInitials: "PS",
            creditScore: 782,
            loanAmount: 2500000,
            riskLevel: .low,
            kycStatus: .verified,
            fraudFlag: false,
            status: .underReview,
            applicationDate: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
            loanType: "Home Loan",
            tenure: 240,
            interestRate: 8.5,
            employmentType: "Salaried",
            employer: "Infosys Ltd.",
            monthlyIncome: 185000,
            existingLiabilities: 15000,
            eligibilityScore: 88,
            emiAmount: 21700,
            phoneNumber: "+91 98765 43210",
            email: "priya.sharma@email.com",
            address: "402, Serenity Heights, Andheri West, Mumbai 400053",
            purpose: "Purchase of 2BHK apartment",
            documents: [
                LoanDocument(name: "Aadhaar Card", type: "Identity", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()), ocrVerified: true, icon: "person.text.rectangle.fill"),
                LoanDocument(name: "PAN Card", type: "Identity", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()), ocrVerified: true, icon: "creditcard.fill"),
                LoanDocument(name: "Salary Slips (3 months)", type: "Income", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()), ocrVerified: true, icon: "doc.text.fill"),
                LoanDocument(name: "Bank Statement", type: "Financial", status: .pending, uploadDate: nil, ocrVerified: false, icon: "building.columns.fill"),
                LoanDocument(name: "Property Documents", type: "Collateral", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()), ocrVerified: false, icon: "house.fill"),
                LoanDocument(name: "Employment Letter", type: "Employment", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()), ocrVerified: false, icon: "envelope.open.fill")
            ],
            timeline: [
                TimelineEvent(title: "Under Review", description: "Assigned to Senior Loan Officer Rajesh Kumar.", timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, status: .underReview, officerName: "System"),
                TimelineEvent(title: "Document Requested", description: "6 months Primary Bank Statement requested by officer.", timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())! - 300, status: .underReview, officerName: "Rajesh Kumar"),
                TimelineEvent(title: "KYC Completed", description: "System verified Aadhaar and PAN successfully.", timestamp: Calendar.current.date(byAdding: .hour, value: -3, to: Date())! + 600, status: .pending, officerName: "System"),
                TimelineEvent(title: "Application Submitted", description: "Loan application submitted online by borrower.", timestamp: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!, status: .pending, officerName: "Priya Sharma")
            ]
        ),
        LoanApplication(
            borrowerName: "Amit Patel",
            borrowerInitials: "AP",
            creditScore: 654,
            loanAmount: 500000,
            riskLevel: .medium,
            kycStatus: .partial,
            fraudFlag: false,
            status: .pending,
            applicationDate: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!,
            loanType: "Personal Loan",
            tenure: 36,
            interestRate: 12.5,
            employmentType: "Self-Employed",
            employer: "Patel Enterprises",
            monthlyIncome: 95000,
            existingLiabilities: 28000,
            eligibilityScore: 62,
            emiAmount: 16750,
            phoneNumber: "+91 87654 32109",
            email: "amit.patel@email.com",
            address: "15, MG Road, Pune 411001",
            purpose: "Business expansion",
            documents: [
                LoanDocument(name: "Aadhaar Card", type: "Identity", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -4, to: Date()), ocrVerified: true, icon: "person.text.rectangle.fill"),
                LoanDocument(name: "PAN Card", type: "Identity", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -4, to: Date()), ocrVerified: true, icon: "creditcard.fill"),
                LoanDocument(name: "Business Registration", type: "Business", status: .missing, uploadDate: nil, ocrVerified: false, icon: "doc.text.fill"),
                LoanDocument(name: "Bank Statement", type: "Financial", status: .pending, uploadDate: nil, ocrVerified: false, icon: "building.columns.fill")
            ],
            timeline: [
                TimelineEvent(title: "KYC Incomplete", description: "Verification completed with warnings. Secondary business proof missing.", timestamp: Calendar.current.date(byAdding: .hour, value: -7, to: Date())!, status: .pending, officerName: "System"),
                TimelineEvent(title: "Application Submitted", description: "Loan application submitted online by borrower.", timestamp: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!, status: .pending, officerName: "Amit Patel")
            ]
        ),
        LoanApplication(
            borrowerName: "Sneha Reddy",
            borrowerInitials: "SR",
            creditScore: 410,
            loanAmount: 1800000,
            riskLevel: .critical,
            kycStatus: .rejected,
            fraudFlag: true,
            status: .escalated,
            applicationDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            loanType: "Vehicle Loan",
            tenure: 60,
            interestRate: 14.0,
            employmentType: "Contract",
            employer: "Freelance",
            monthlyIncome: 45000,
            existingLiabilities: 32000,
            eligibilityScore: 28,
            emiAmount: 41900,
            phoneNumber: "+91 76543 21098",
            email: "sneha.reddy@email.com",
            address: "8-2-120, Banjara Hills, Hyderabad 500034",
            purpose: "Purchase of luxury vehicle",
            documents: [
                LoanDocument(name: "Aadhaar Card", type: "Identity", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()), ocrVerified: true, icon: "person.text.rectangle.fill"),
                LoanDocument(name: "PAN Card", type: "Identity", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()), ocrVerified: true, icon: "creditcard.fill"),
                LoanDocument(name: "Address Proof", type: "Address", status: .tampered, uploadDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()), ocrVerified: false, icon: "mappin.circle.fill"),
                LoanDocument(name: "Income Proof", type: "Income", status: .missing, uploadDate: nil, ocrVerified: false, icon: "doc.text.fill")
            ],
            timeline: [
                TimelineEvent(title: "Escalated", description: "Application escalated due to critical fraud flags and poor credit.", timestamp: Calendar.current.date(byAdding: .hour, value: -22, to: Date())!, status: .escalated, officerName: "Rajesh Kumar"),
                TimelineEvent(title: "Security Alert Raised", description: "Digital check flagged address proof as potentially tampered/edited.", timestamp: Calendar.current.date(byAdding: .hour, value: -23, to: Date())!, status: .underReview, officerName: "System"),
                TimelineEvent(title: "Application Submitted", description: "Loan application submitted online by borrower.", timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, status: .pending, officerName: "Sneha Reddy")
            ]
        ),
        LoanApplication(
            borrowerName: "Vikram Singh",
            borrowerInitials: "VS",
            creditScore: 721,
            loanAmount: 3500000,
            riskLevel: .low,
            kycStatus: .verified,
            fraudFlag: false,
            status: .approved,
            applicationDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            loanType: "Home Loan",
            tenure: 300,
            interestRate: 8.25,
            employmentType: "Salaried",
            employer: "TCS",
            monthlyIncome: 220000,
            existingLiabilities: 0,
            eligibilityScore: 92,
            emiAmount: 28400,
            phoneNumber: "+91 65432 10987",
            email: "vikram.singh@email.com",
            address: "C-12, Vasant Vihar, New Delhi 110057",
            purpose: "Purchase of 3BHK apartment",
            documents: [
                LoanDocument(name: "Aadhaar Card", type: "Identity", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()), ocrVerified: true, icon: "person.text.rectangle.fill"),
                LoanDocument(name: "PAN Card", type: "Identity", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()), ocrVerified: true, icon: "creditcard.fill"),
                LoanDocument(name: "Bank Statement", type: "Financial", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()), ocrVerified: true, icon: "building.columns.fill"),
                LoanDocument(name: "Property Documents", type: "Collateral", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()), ocrVerified: true, icon: "house.fill"),
                LoanDocument(name: "Employment Letter", type: "Employment", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()), ocrVerified: true, icon: "envelope.open.fill")
            ],
            timeline: [
                TimelineEvent(title: "Approved", description: "Final manager approval complete. Sanction letter generated.", timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, status: .approved, officerName: "System"),
                TimelineEvent(title: "Recommendation Submitted", description: "Approved & recommended to manager by Rajesh Kumar. Remarks: Strong borrower history, good salary and clear collateral details.", timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())! - 3600, status: .underReview, officerName: "Rajesh Kumar"),
                TimelineEvent(title: "KYC Completed", description: "KYC checks successfully completed and verified.", timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date())! + 1800, status: .pending, officerName: "System"),
                TimelineEvent(title: "Application Submitted", description: "Loan application submitted online by borrower.", timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, status: .pending, officerName: "Vikram Singh")
            ]
        ),
        LoanApplication(
            borrowerName: "Meera Nair",
            borrowerInitials: "MN",
            creditScore: 598,
            loanAmount: 800000,
            riskLevel: .high,
            kycStatus: .pending,
            fraudFlag: false,
            status: .pending,
            applicationDate: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!,
            loanType: "Education Loan",
            tenure: 84,
            interestRate: 10.5,
            employmentType: "Student",
            employer: "N/A",
            monthlyIncome: 0,
            existingLiabilities: 0,
            eligibilityScore: 45,
            emiAmount: 13300,
            phoneNumber: "+91 54321 09876",
            email: "meera.nair@email.com",
            address: "22, Brigade Road, Bangalore 560001",
            purpose: "MBA at IIM Ahmedabad",
            documents: [
                LoanDocument(name: "Aadhaar Card", type: "Identity", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()), ocrVerified: true, icon: "person.text.rectangle.fill"),
                LoanDocument(name: "PAN Card", type: "Identity", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()), ocrVerified: true, icon: "creditcard.fill"),
                LoanDocument(name: "Admission Letter", type: "Education", status: .verified, uploadDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()), ocrVerified: true, icon: "doc.text.fill"),
                LoanDocument(name: "Co-borrower PAN", type: "Identity", status: .pending, uploadDate: nil, ocrVerified: false, icon: "creditcard.fill")
            ],
            timeline: [
                TimelineEvent(title: "Assigned", description: "Assigned to Rajesh Kumar for education verification review.", timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, status: .pending, officerName: "System"),
                TimelineEvent(title: "Application Submitted", description: "Loan application submitted online by borrower.", timestamp: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!, status: .pending, officerName: "Meera Nair")
            ]
        )
    ]

    static let sampleDocuments: [LoanDocument] = [
        LoanDocument(name: "Aadhaar Card", type: "Identity", status: .verified, uploadDate: Date(), ocrVerified: true, icon: "person.text.rectangle.fill"),
        LoanDocument(name: "PAN Card", type: "Identity", status: .verified, uploadDate: Date(), ocrVerified: true, icon: "creditcard.fill"),
        LoanDocument(name: "Salary Slips (3 months)", type: "Income", status: .verified, uploadDate: Date(), ocrVerified: true, icon: "doc.text.fill"),
        LoanDocument(name: "Bank Statement", type: "Financial", status: .pending, uploadDate: nil, ocrVerified: false, icon: "building.columns.fill"),
        LoanDocument(name: "Property Documents", type: "Collateral", status: .missing, uploadDate: nil, ocrVerified: false, icon: "house.fill"),
        LoanDocument(name: "Employment Letter", type: "Employment", status: .verified, uploadDate: Date(), ocrVerified: false, icon: "envelope.open.fill"),
        LoanDocument(name: "Address Proof", type: "Address", status: .tampered, uploadDate: Date(), ocrVerified: true, icon: "mappin.circle.fill"),
        LoanDocument(name: "ITR (2 years)", type: "Tax", status: .duplicate, uploadDate: Date(), ocrVerified: false, icon: "doc.on.doc.fill")
    ]

    static let sampleCollateral = CollateralInfo(
        propertyType: "Residential Apartment",
        address: "402, Serenity Heights, Andheri West, Mumbai 400053",
        currentValuation: 4200000,
        lastValuationDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
        coverageRatio: 1.68,
        revaluationHistory: [
            (date: Calendar.current.date(byAdding: .year, value: -2, to: Date())!, value: 3500000),
            (date: Calendar.current.date(byAdding: .year, value: -1, to: Date())!, value: 3800000),
            (date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!, value: 4200000)
        ]
    )

    static let overdueBorrowers: [OverdueBorrower] = [
        OverdueBorrower(borrowerName: "Rahul Verma", borrowerInitials: "RV", loanId: "LN-2024-0847", dpdDays: 45, outstandingEMI: 34500, totalOutstanding: 892000, priority: .urgent, lastContactDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()), phoneNumber: "+91 98765 11111", collectionEfficiency: 42.0, contactAttempts: 7),
        OverdueBorrower(borrowerName: "Anita Deshmukh", borrowerInitials: "AD", loanId: "LN-2024-1023", dpdDays: 30, outstandingEMI: 21800, totalOutstanding: 456000, priority: .high, lastContactDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()), phoneNumber: "+91 87654 22222", collectionEfficiency: 58.0, contactAttempts: 4),
        OverdueBorrower(borrowerName: "Suresh Gupta", borrowerInitials: "SG", loanId: "LN-2024-0562", dpdDays: 15, outstandingEMI: 15600, totalOutstanding: 234000, priority: .normal, lastContactDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()), phoneNumber: "+91 76543 33333", collectionEfficiency: 72.0, contactAttempts: 2),
        OverdueBorrower(borrowerName: "Kavita Joshi", borrowerInitials: "KJ", loanId: "LN-2024-0991", dpdDays: 60, outstandingEMI: 45200, totalOutstanding: 1230000, priority: .urgent, lastContactDate: Calendar.current.date(byAdding: .day, value: -10, to: Date()), phoneNumber: "+91 65432 44444", collectionEfficiency: 28.0, contactAttempts: 12),
        OverdueBorrower(borrowerName: "Deepak Malhotra", borrowerInitials: "DM", loanId: "LN-2024-1105", dpdDays: 7, outstandingEMI: 18900, totalOutstanding: 567000, priority: .low, lastContactDate: nil, phoneNumber: "+91 54321 55555", collectionEfficiency: 85.0, contactAttempts: 0)
    ]

//    static let fieldVisits: [FieldVisit] = [
//        FieldVisit(borrowerName: "Priya Sharma", address: "402, Serenity Heights, Andheri West", scheduledDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date())!, status: .scheduled, assignedOfficer: "Rajesh Kumar", purpose: "Property Verification", checklistCompleted: 0, checklistTotal: 8, latitude: 19.1364, longitude: 72.8296),
//        FieldVisit(borrowerName: "Amit Patel", address: "15, MG Road, Pune", scheduledDate: Date(), status: .inProgress, assignedOfficer: "Rajesh Kumar", purpose: "Business Verification", checklistCompleted: 5, checklistTotal: 10, latitude: 18.5204, longitude: 73.8567),
//        FieldVisit(borrowerName: "Vikram Singh", address: "C-12, Vasant Vihar, Delhi", scheduledDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, status: .completed, assignedOfficer: "Sanjay Mehta", purpose: "Address Verification", checklistCompleted: 8, checklistTotal: 8, latitude: 28.5574, longitude: 77.1589),
//        FieldVisit(borrowerName: "Meera Nair", address: "22, Brigade Road, Bangalore", scheduledDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, status: .scheduled, assignedOfficer: "Rajesh Kumar", purpose: "Income Verification", checklistCompleted: 0, checklistTotal: 6, latitude: 12.9716, longitude: 77.5946)
//    ]

    static let notifications: [AppNotification] = [
        AppNotification(title: "Fraud Alert: Sneha Reddy", message: "Tampered address proof detected. Immediate review required.", type: .fraudAlert, timestamp: Calendar.current.date(byAdding: .minute, value: -15, to: Date())!, isRead: false, priority: 1),
        AppNotification(title: "Loan Approved: Vikram Singh", message: "Home loan of ₹35,00,000 has been approved by the manager.", type: .pendingApproval, timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!, isRead: false, priority: 2),
        AppNotification(title: "New Assignment: Meera Nair", message: "Education loan application assigned for review.", type: .assignedApplication, timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, isRead: false, priority: 3),
        AppNotification(title: "Overdue: Kavita Joshi", message: "60 days past due. Escalation required.", type: .overdueReminder, timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!, isRead: true, priority: 1),
        AppNotification(title: "Escalation: Amit Patel", message: "KYC verification incomplete. Manager review needed.", type: .escalation, timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!, isRead: true, priority: 2),
        AppNotification(title: "Document Request: Priya Sharma", message: "Bank statement resubmission requested.", type: .documentRequest, timestamp: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!, isRead: true, priority: 3),
        AppNotification(title: "System Maintenance", message: "Scheduled maintenance on May 25, 2:00 AM - 4:00 AM.", type: .systemUpdate, timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, isRead: true, priority: 4)
    ]

    static let conversations: [BorrowerConversation] = [
        BorrowerConversation(
            borrowerName: "Priya Sharma",
            borrowerInitials: "PS",
            lastMessage: "Thank you! I'll upload the bank statement today.",
            lastMessageTime: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
            unreadCount: 2,
            messages: [
                ChatMessage(text: "Hello Priya, this is regarding your home loan application. We need your latest bank statement.", sender: .officer, timestamp: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!, isRead: true),
                ChatMessage(text: "Hi! Yes, I'll arrange that. Which months do you need?", sender: .borrower, timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, isRead: true),
                ChatMessage(text: "Please provide the last 6 months' statements from your primary salary account.", sender: .officer, timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!, isRead: true),
                ChatMessage(text: "Sure, I'll upload them by end of day.", sender: .borrower, timestamp: Calendar.current.date(byAdding: .minute, value: -45, to: Date())!, isRead: true),
                ChatMessage(text: "Thank you! I'll upload the bank statement today.", sender: .borrower, timestamp: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!, isRead: false)
            ],
            isOnline: true
        ),
        BorrowerConversation(
            borrowerName: "Amit Patel",
            borrowerInitials: "AP",
            lastMessage: "When can I expect the approval?",
            lastMessageTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            unreadCount: 1,
            messages: [
                ChatMessage(text: "Mr. Patel, your KYC is partially complete. Please submit your GST registration certificate.", sender: .officer, timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, isRead: true),
                ChatMessage(text: "I've sent the GST certificate to your email.", sender: .borrower, timestamp: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!, isRead: true),
                ChatMessage(text: "When can I expect the approval?", sender: .borrower, timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, isRead: false)
            ],
            isOnline: false
        ),
        BorrowerConversation(
            borrowerName: "Vikram Singh",
            borrowerInitials: "VS",
            lastMessage: "Congratulations! Your home loan has been approved.",
            lastMessageTime: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!,
            unreadCount: 0,
            messages: [
                ChatMessage(text: "Congratulations! Your home loan has been approved. The sanction letter will be generated shortly.", sender: .officer, timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!, isRead: true),
                ChatMessage(text: "That's wonderful news! Thank you so much for your help.", sender: .borrower, timestamp: Calendar.current.date(byAdding: .minute, value: -50, to: Date())!, isRead: true)
            ],
            isOnline: true
        )
    ]

    static let activityFeed: [ActivityItem] = [
        ActivityItem(title: "New application assigned", subtitle: "Meera Nair — Education Loan ₹8,00,000", type: .newApplication, timestamp: Calendar.current.date(byAdding: .minute, value: -12, to: Date())!),
        ActivityItem(title: "Fraud detected", subtitle: "Sneha Reddy — Tampered address proof", type: .fraudDetected, timestamp: Calendar.current.date(byAdding: .minute, value: -25, to: Date())!),
        ActivityItem(title: "Loan approved", subtitle: "Vikram Singh — Home Loan ₹35,00,000", type: .approved, timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!),
        ActivityItem(title: "Pending approval", subtitle: "Priya Sharma — Home Loan ₹25,00,000", type: .pendingApproval, timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!),
        ActivityItem(title: "Overdue reminder", subtitle: "Kavita Joshi — 60 DPD, ₹45,200 EMI", type: .overdueReminder, timestamp: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!),
        ActivityItem(title: "Document uploaded", subtitle: "Amit Patel — GST Registration Certificate", type: .documentUploaded, timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!),
        ActivityItem(title: "Escalation raised", subtitle: "Amit Patel — Incomplete KYC verification", type: .escalation, timestamp: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!)
    ]

    static let digitalDocuments: [DigitalDocument] = [
        DigitalDocument(title: "Loan Sanction Letter", type: "PDF", icon: "doc.text.fill", fileSize: "245 KB", generatedDate: Date(), isSigned: true, borrowerAcknowledged: true),
        DigitalDocument(title: "EMI Schedule", type: "PDF", icon: "tablecells.fill", fileSize: "128 KB", generatedDate: Date(), isSigned: false, borrowerAcknowledged: false),
        DigitalDocument(title: "Property Valuation Report", type: "PDF", icon: "house.fill", fileSize: "1.2 MB", generatedDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, isSigned: true, borrowerAcknowledged: false),
        DigitalDocument(title: "KYC Verification Report", type: "PDF", icon: "person.text.rectangle.fill", fileSize: "89 KB", generatedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, isSigned: false, borrowerAcknowledged: false),
        DigitalDocument(title: "Insurance Policy", type: "PDF", icon: "shield.fill", fileSize: "567 KB", generatedDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, isSigned: true, borrowerAcknowledged: true)
    ]
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
