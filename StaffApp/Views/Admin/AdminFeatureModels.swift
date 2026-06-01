import Foundation
import Observation
import SwiftUI

enum NotificationChannel: String, Codable, Sendable, CaseIterable, Identifiable {
    case email = "Email"
    case sms = "SMS"
    case inApp = "In App"

    var id: String { rawValue }
}

enum TriggerEvent: String, Codable, Sendable, CaseIterable, Identifiable {
    case loanApproved = "Loan Approved"
    case loanRejected = "Loan Rejected"
    case paymentReceived = "Payment Received"
    case emiDue = "EMI Due"
    case kycVerified = "KYC Verified"
    case kycRejected = "KYC Rejected"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .loanApproved: return "checkmark.seal.fill"
        case .loanRejected: return "xmark.seal.fill"
        case .paymentReceived: return "indianrupeesign.circle.fill"
        case .emiDue: return "calendar.badge.exclamationmark"
        case .kycVerified: return "person.crop.circle.badge.checkmark"
        case .kycRejected: return "person.crop.circle.badge.xmark"
        }
    }

    var tintColor: String {
        switch self {
        case .loanApproved, .paymentReceived, .kycVerified: return "green"
        case .loanRejected, .kycRejected: return "red"
        case .emiDue: return "orange"
        }
    }
}

struct NotificationTemplate: Identifiable, Hashable, Codable, Sendable {
    var id: UUID = UUID()
    var title: String
    var triggerEvent: TriggerEvent
    var bodyText: String
    var channels: Set<NotificationChannel>

    static let sampleTemplates: [NotificationTemplate] = [
        NotificationTemplate(
            title: "Loan Approved",
            triggerEvent: .loanApproved,
            bodyText: "Dear {{borrower_name}}, your loan has been approved for {{loan_amount}}.",
            channels: [.email, .inApp]
        ),
        NotificationTemplate(
            title: "Loan Rejected",
            triggerEvent: .loanRejected,
            bodyText: "Dear {{borrower_name}}, your application could not be approved at this time.",
            channels: [.email, .sms]
        ),
        NotificationTemplate(
            title: "EMI Due Reminder",
            triggerEvent: .emiDue,
            bodyText: "Hi {{borrower_name}}, your EMI of {{emi_amount}} is due on {{due_date}}.",
            channels: [.email, .inApp]
        ),
        NotificationTemplate(
            title: "Payment Received",
            triggerEvent: .paymentReceived,
            bodyText: "We received {{payment_amount}} towards loan {{loan_id}}. Outstanding balance: {{remaining_balance}}.",
            channels: [.email, .sms, .inApp]
        ),
        NotificationTemplate(
            title: "KYC Verified",
            triggerEvent: .kycVerified,
            bodyText: "Your KYC has been verified successfully. You can continue with your application.",
            channels: [.email, .inApp]
        )
    ]
}

enum LoanCategory: String, Codable, Sendable, CaseIterable, Identifiable {
    case personal = "Personal"
    case home = "Home"
    case vehicle = "Vehicle"
    case education = "Education"
    case business = "Business"

    var id: String { rawValue }
}

enum TenureUnit: String, Codable, Sendable, CaseIterable, Identifiable {
    case months = "Months"
    case years = "Years"

    var id: String { rawValue }
}

struct LoanProduct: Identifiable, Hashable, Codable, Sendable {
    var id: UUID = UUID()
    var name: String
    var minAmount: Double
    var maxAmount: Double
    var interestRate: Double
    var maxTenure: Int
    var tenureUnit: TenureUnit

    static let sampleProducts: [LoanCategory: [LoanProduct]] = [
        .personal: [
            LoanProduct(name: "Flexible Personal Loan", minAmount: 50_000, maxAmount: 1_500_000, interestRate: 11.25, maxTenure: 60, tenureUnit: .months)
        ],
        .home: [
            LoanProduct(name: "Standard Home Loan", minAmount: 500_000, maxAmount: 15_000_000, interestRate: 8.45, maxTenure: 20, tenureUnit: .years)
        ],
        .vehicle: [
            LoanProduct(name: "New Car Loan", minAmount: 300_000, maxAmount: 3_000_000, interestRate: 9.10, maxTenure: 84, tenureUnit: .months)
        ],
        .education: [
            LoanProduct(name: "Higher Education Loan", minAmount: 100_000, maxAmount: 2_500_000, interestRate: 10.50, maxTenure: 84, tenureUnit: .months)
        ],
        .business: [
            LoanProduct(name: "SME Expansion Loan", minAmount: 250_000, maxAmount: 10_000_000, interestRate: 12.00, maxTenure: 10, tenureUnit: .years)
        ]
    ]
}

struct RecentApplication: Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String
    var loanType: LoanType
    var amount: String
    var status: ApplicationStatus
    var date: String
}

struct DashboardStats: Hashable, Sendable {
    var totalAmount: String
    var totalUser: Int
    var activeLoans: Int
    var applications: Int
}

struct DashboardSnapshot: Hashable, Sendable {
    var stats: DashboardStats
    var recentApplications: [RecentApplication]
}

enum AdminSeedData {
    static let adminID = UUID(uuidString: "90000000-0000-0000-0000-000000000001")!
    static let managerID = UUID(uuidString: "90000000-0000-0000-0000-000000000002")!
    static let officerID = UUID(uuidString: "90000000-0000-0000-0000-000000000003")!

    static let users: [User] = [
        User(id: adminID, fullName: "Sarah Jenkins", email: "sarah.jenkins@lms.com", phone: "+91 98765 43210", role: .admin),
        User(id: managerID, fullName: "Aditi Rao", email: "aditi.rao@lms.com", phone: "+91 99887 65432", role: .manager),
        User(id: officerID, fullName: "Sarah Mehta", email: "sarah.mehta@lms.com", phone: "+91 99887 76543", role: .loanOfficer),
        User(id: MockOfficerData.seedBorrowers[0].user.id, fullName: MockOfficerData.seedBorrowers[0].user.fullName, email: MockOfficerData.seedBorrowers[0].user.email, phone: MockOfficerData.seedBorrowers[0].user.phone, role: .borrower),
        User(id: MockOfficerData.seedBorrowers[1].user.id, fullName: MockOfficerData.seedBorrowers[1].user.fullName, email: MockOfficerData.seedBorrowers[1].user.email, phone: MockOfficerData.seedBorrowers[1].user.phone, role: .borrower),
        User(id: MockOfficerData.seedBorrowers[2].user.id, fullName: MockOfficerData.seedBorrowers[2].user.fullName, email: MockOfficerData.seedBorrowers[2].user.email, phone: MockOfficerData.seedBorrowers[2].user.phone, role: .borrower),
        User(id: MockOfficerData.seedBorrowers[3].user.id, fullName: MockOfficerData.seedBorrowers[3].user.fullName, email: MockOfficerData.seedBorrowers[3].user.email, phone: MockOfficerData.seedBorrowers[3].user.phone, role: .borrower)
    ]

    static let staffProfiles: [UUID: StaffProfile] = [
        adminID: StaffProfile(
            id: adminID,
            employeeID: "AD-0001",
            branchID: nil,
            department: "Administration",
            reportsToID: nil,
            permissions: [.viewUsers, .editUsers, .viewAudit, .manageSettings]
        ),
        managerID: StaffProfile(
            id: managerID,
            employeeID: "MG-1187",
            branchID: nil,
            department: "Branch Management",
            reportsToID: adminID,
            permissions: [.viewUsers, .viewAudit]
        ),
        officerID: StaffProfile(
            id: officerID,
            employeeID: "LO-2041",
            branchID: nil,
            department: "Loan Origination",
            reportsToID: managerID,
            permissions: [.viewUsers]
        )
    ]

    static let borrowerOfficerAssignments: [UUID: UUID] = [
        MockOfficerData.seedBorrowers[0].user.id: officerID,
        MockOfficerData.seedBorrowers[1].user.id: officerID,
        MockOfficerData.seedBorrowers[2].user.id: officerID,
        MockOfficerData.seedBorrowers[3].user.id: officerID
    ]

    static let loanHistory: [UUID: [Loan]] = {
        var result: [UUID: [Loan]] = [:]
        let outstandingFactor = Decimal(string: "0.72")!
        let principalComponentFactor = Decimal(string: "0.65")!
        let interestComponentFactor = Decimal(string: "0.35")!

        for application in MockOfficerData.assignedApplications() {
            let emiAmount = application.requestedAmount / Decimal(application.tenureMonths)
            let loan = Loan(
                applicationID: application.id,
                borrowerID: application.borrowerID,
                loanType: application.loanType,
                principal: application.requestedAmount,
                interestRate: application.interestRate,
                tenureMonths: application.tenureMonths,
                disbursementDate: application.createdAt,
                outstandingBalance: application.requestedAmount * outstandingFactor,
                emiSchedule: [
                    EMI(installmentNumber: 1, dueDate: application.createdAt.addingTimeInterval(60 * 60 * 24 * 30), principalComponent: emiAmount * principalComponentFactor, interestComponent: emiAmount * interestComponentFactor, totalAmount: emiAmount, status: .paid, paidAt: application.createdAt.addingTimeInterval(60 * 60 * 24 * 25)),
                    EMI(installmentNumber: 2, dueDate: application.createdAt.addingTimeInterval(60 * 60 * 24 * 60), principalComponent: emiAmount * principalComponentFactor, interestComponent: emiAmount * interestComponentFactor, totalAmount: emiAmount, status: .upcoming, paidAt: nil)
                ],
                status: .active
            )
            result[application.borrowerID, default: []].append(loan)
        }
        return result
    }()

    static let dashboardSnapshot = DashboardSnapshot(
        stats: DashboardStats(
            totalAmount: Formatting.currency(12_850_000),
            totalUser: users.count,
            activeLoans: 18,
            applications: MockOfficerData.assignedApplications().count + 7
        ),
        recentApplications: MockOfficerData.assignedApplications().prefix(4).enumerated().map { index, application in
            let borrower = MockOfficerData.seedBorrowers[index].user
            return RecentApplication(
                name: borrower.fullName,
                loanType: application.loanType,
                amount: Formatting.currency(application.requestedAmount),
                status: application.status,
                date: Formatting.date(application.updatedAt)
            )
        }
    )

    static let auditEntries: [AuditEntry] = [
        AuditEntry(actorID: adminID, actorRole: .admin, action: "Updated role", entityType: "User", entityID: officerID, metadata: ["role": "Loan Officer"], timestamp: .now.addingTimeInterval(-3600)),
        AuditEntry(actorID: managerID, actorRole: .manager, action: "Reviewed application", entityType: "LoanApplication", entityID: MockOfficerData.assignedApplications()[0].id, metadata: ["result": "Recommended"], timestamp: .now.addingTimeInterval(-7200)),
        AuditEntry(actorID: officerID, actorRole: .loanOfficer, action: "Verified document", entityType: "LoanDocument", entityID: UUID(), metadata: ["document": "PAN Card"], timestamp: .now.addingTimeInterval(-14_000))
    ]
}

@MainActor
@Observable
final class DashboardViewModel {
    var snapshot: DashboardSnapshot = AdminSeedData.dashboardSnapshot

    func refreshDashboard() async {
        snapshot = AdminSeedData.dashboardSnapshot
    }
}

@MainActor
@Observable
final class UserManagementViewModel {
    enum Filter: Equatable {
        case all
        case role(UserRole)
    }

    var users: [User] = AdminSeedData.users
    var staffProfiles: [UUID: StaffProfile] = AdminSeedData.staffProfiles
    var currentFilter: Filter = .all
    var searchText: String = ""
    var showSuccessAlert: Bool = false
    var successMessage: String = ""

    private var loanHistory: [UUID: [Loan]] = AdminSeedData.loanHistory
    private var borrowerAssignments: [UUID: UUID] = AdminSeedData.borrowerOfficerAssignments
    let auditEntries: [AuditEntry] = AdminSeedData.auditEntries

    var filteredUsers: [User] {
        users.filter { user in
            let matchesFilter: Bool = {
                switch currentFilter {
                case .all:
                    return true
                case .role(let role):
                    return user.role == role
                }
            }()

            guard matchesFilter else { return false }

            guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return true
            }

            let query = searchText.lowercased()
            return user.fullName.lowercased().contains(query)
                || user.email.lowercased().contains(query)
                || user.phone.lowercased().contains(query)
                || user.uniqueID.lowercased().contains(query)
                || user.role.displayName.lowercased().contains(query)
        }
    }

    func updateRole(for userID: UUID, to role: UserRole) async {
        guard let index = users.firstIndex(where: { $0.id == userID }) else { return }
        users[index].role = role
        if role == .admin || role == .manager || role == .loanOfficer {
            if staffProfiles[userID] == nil {
                staffProfiles[userID] = StaffProfile(
                    id: userID,
                    employeeID: "ST-\(userID.uuidString.prefix(6).uppercased())",
                    branchID: nil,
                    department: nil,
                    reportsToID: nil,
                    permissions: []
                )
            }
        }
        showSuccessAlert = true
        successMessage = "Role updated for \(users[index].fullName)."
    }

    func toggleUserStatus(for userID: UUID) async {
        guard let index = users.firstIndex(where: { $0.id == userID }) else { return }
        users[index].isActive.toggle()
        showSuccessAlert = true
        successMessage = users[index].isActive ? "User reactivated." : "User deactivated."
    }

    func deleteUser(for userID: UUID) async {
        users.removeAll { $0.id == userID }
        staffProfiles.removeValue(forKey: userID)
        borrowerAssignments = borrowerAssignments.filter { $0.key != userID && $0.value != userID }
        loanHistory.removeValue(forKey: userID)
        showSuccessAlert = true
        successMessage = "User removed."
    }

    func updatePermissions(for userID: UUID, to permissions: Set<Permission>) async {
        guard var profile = staffProfiles[userID] else { return }
        profile.permissions = permissions
        staffProfiles[userID] = profile
        showSuccessAlert = true
        successMessage = "Permissions updated."
    }

    func getAssignedOfficer(for borrowerID: UUID) -> User? {
        guard let officerID = borrowerAssignments[borrowerID] else { return nil }
        return users.first { $0.id == officerID }
    }

    func getSupervisingManager(for staffID: UUID) -> User? {
        guard let reportsToID = staffProfiles[staffID]?.reportsToID else { return nil }
        return users.first { $0.id == reportsToID }
    }

    func getLoanHistory(for borrowerID: UUID) -> [Loan] {
        loanHistory[borrowerID] ?? []
    }

    func getBorrowers(for officerID: UUID) -> [User] {
        users.filter { $0.role == .borrower && borrowerAssignments[$0.id] == officerID }
    }

    func getLoanOfficers(for managerID: UUID) -> [User] {
        users.filter { $0.role == .loanOfficer && staffProfiles[$0.id]?.reportsToID == managerID }
    }
}

@MainActor
@Observable
final class TemplateViewModel {
    var templates: [NotificationTemplate] = NotificationTemplate.sampleTemplates
    var selectedTemplate: NotificationTemplate?
    var searchText: String = ""
    var editingTitle: String = ""
    var editingChannels: Set<NotificationChannel> = []
    var editingBodyText: String = ""
    var showSaveAlert: Bool = false
    var validationError: String?
    var hasUnsavedChanges: Bool = false

    var filteredTemplates: [NotificationTemplate] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return templates
        }

        let query = searchText.lowercased()
        return templates.filter {
            $0.title.lowercased().contains(query)
                || $0.triggerEvent.rawValue.lowercased().contains(query)
                || $0.bodyText.lowercased().contains(query)
        }
    }

    var previewBodyText: String {
        let sampleValues = [
            "{{borrower_name}}": "Naman Gupta",
            "{{loan_id}}": "APP-1024",
            "{{loan_amount}}": "₹3,00,000",
            "{{emi_amount}}": "₹8,452",
            "{{due_date}}": "25 May 2026",
            "{{payment_amount}}": "₹8,452",
            "{{remaining_balance}}": "₹2,12,000",
            "{{days_overdue}}": "3",
            "{{late_fee}}": "₹150",
            "{{document_list}}": "PAN Card, Aadhaar, Bank Statement"
        ]

        return sampleValues.reduce(editingBodyText) { partialResult, replacement in
            partialResult.replacingOccurrences(of: replacement.key, with: replacement.value)
        }
    }

    @discardableResult
    func selectTemplate(_ template: NotificationTemplate) -> Bool {
        selectedTemplate = template
        editingTitle = template.title
        editingChannels = template.channels
        editingBodyText = template.bodyText
        hasUnsavedChanges = false
        validationError = nil
        return true
    }

    func markDirty() {
        hasUnsavedChanges = true
    }

    func createTemplate(for trigger: TriggerEvent, title: String, bodyText: String, channels: Set<NotificationChannel>) {
        let template = NotificationTemplate(title: title, triggerEvent: trigger, bodyText: bodyText, channels: channels)
        templates.append(template)
        selectTemplate(template)
        showSaveAlert = true
    }

    func updateTemplate() async {
        guard var selectedTemplate else { return }
        selectedTemplate.title = editingTitle
        selectedTemplate.bodyText = editingBodyText
        selectedTemplate.channels = editingChannels

        if let index = templates.firstIndex(where: { $0.id == selectedTemplate.id }) {
            templates[index] = selectedTemplate
        }

        self.selectedTemplate = selectedTemplate
        hasUnsavedChanges = false
        validationError = nil
        showSaveAlert = true
    }

    func deleteTemplates(at offsets: IndexSet) {
        templates.remove(atOffsets: offsets)
    }
}

@MainActor
@Observable
final class LoanConfigViewModel {
    var productsByCategory: [LoanCategory: [LoanProduct]] = LoanProduct.sampleProducts
    var showSaveAlert: Bool = false

    var activeCategories: [LoanCategory] {
        LoanCategory.allCases.filter { !(productsByCategory[$0] ?? []).isEmpty }
    }

    func binding(for productID: UUID) -> Binding<LoanProduct>? {
        for category in LoanCategory.allCases {
            guard let index = productsByCategory[category]?.firstIndex(where: { $0.id == productID }) else {
                continue
            }

            return Binding(
                get: { self.productsByCategory[category]![index] },
                set: { newValue in
                    self.productsByCategory[category]![index] = newValue
                    self.markDirty()
                }
            )
        }

        return nil
    }

    func deleteLoans(category: LoanCategory, at offsets: IndexSet) {
        productsByCategory[category]?.remove(atOffsets: offsets)
        markDirty()
    }

    func markDirty() {
        showSaveAlert = true
    }
}