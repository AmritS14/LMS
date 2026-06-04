import Foundation
import Observation
import SwiftUI
import Supabase

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

struct AdminLoanProduct: Identifiable, Hashable, Codable, Sendable {
    var id: UUID = UUID()
    var name: String
    var minAmount: Double
    var maxAmount: Double
    var interestRate: Double
    var maxTenure: Int
    var tenureUnit: TenureUnit
    var isActive: Bool = true

    static let sampleProducts: [LoanCategory: [AdminLoanProduct]] = [
        .personal: [
            AdminLoanProduct(name: "Flexible Personal Loan", minAmount: 50_000, maxAmount: 1_500_000, interestRate: 11.25, maxTenure: 60, tenureUnit: .months)
        ],
        .home: [
            AdminLoanProduct(name: "Standard Home Loan", minAmount: 500_000, maxAmount: 15_000_000, interestRate: 8.45, maxTenure: 20, tenureUnit: .years)
        ],
        .vehicle: [
            AdminLoanProduct(name: "New Car Loan", minAmount: 300_000, maxAmount: 3_000_000, interestRate: 9.10, maxTenure: 84, tenureUnit: .months)
        ],
        .education: [
            AdminLoanProduct(name: "Higher Education Loan", minAmount: 100_000, maxAmount: 2_500_000, interestRate: 10.50, maxTenure: 84, tenureUnit: .months)
        ],
        .business: [
            AdminLoanProduct(name: "SME Expansion Loan", minAmount: 250_000, maxAmount: 10_000_000, interestRate: 12.00, maxTenure: 10, tenureUnit: .years)
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


}

private func mapAppStatus(_ raw: String) -> ApplicationStatus {
    switch raw.lowercased() {
    case "submitted": return .submitted
    case "assigned": return .submitted
    case "under_review": return .underReview
    case "document_pending": return .additionalInfoRequired
    case "manager_review", "pending_manager_approval": return .escalated
    case "approved": return .approved
    case "rejected": return .rejected
    case "disbursed": return .disbursed
    case "closed": return .closed
    default: return .draft
    }
}

struct DBEnrichedApplication: Decodable {
    struct NestedUser: Decodable { let id: UUID; let email: String?; let full_name: String? }
    struct NestedProduct: Decodable { let id: UUID; let name: String? }
    let id: UUID
    let borrower_id: UUID
    let assigned_officer_id: UUID?
    let loan_product_id: UUID
    let requested_amount: Decimal
    let tenure_months: Int
    let interest_rate: Double
    let status: String
    let created_at: Date
    let updated_at: Date
    let users: NestedUser?
    let loan_products: NestedProduct?
}

@MainActor
@Observable
final class DashboardViewModel {
    var snapshot: DashboardSnapshot = DashboardSnapshot(
        stats: DashboardStats(totalAmount: "—", totalUser: 0, activeLoans: 0, applications: 0),
        recentApplications: []
    )
    var recentAuditLogs: [AuditEntry] = []
    var rawTotalAmount: Decimal = 0
    var isLoading: Bool = false
    var error: String? = nil

    private var environment: AppEnvironment?
    private var realtimeTask: Task<Void, Never>? = nil
    private var productCache: [UUID: LoanType] = [:]

    func configure(environment: AppEnvironment?) {
        self.environment = environment
    }

    private func ensureProductCache() async throws {
        guard let environment else { return }
        if productCache.isEmpty {
            let products = try await environment.loans.fetchLoanProducts()
            for p in products {
                productCache[p.id] = p.loanType
            }
        }
    }

    func loadDashboard() async {
        isLoading = true
        error = nil

        do {
            try await refreshDashboard()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func refreshDashboard() async throws {
        guard let environment else { return }
        let client = SupabaseManager.shared.client

        try await ensureProductCache()

        async let usersRes = client.from("users").select("id").execute()
        async let loansRes = client.from("loans").select("principal, status").execute()
        async let appsRes = client.from("loan_applications").select("id").execute()

        // Relationship query for recent applications
        async let recentAppsRes = client.from("loan_applications")
            .select("id, borrower_id, assigned_officer_id, loan_product_id, requested_amount, tenure_months, interest_rate, status, created_at, updated_at, users:users!loan_applications_borrower_id_fkey(id, email, full_name), loan_products(id, name)")
            .order("created_at", ascending: false)
            .limit(10)
            .execute()

        let (uData, lData, aData, rData) = try await (usersRes, loansRes, appsRes, recentAppsRes)

        struct DBUserSummary: Decodable { let id: UUID }
        struct DBLoanSummary: Decodable { let principal: Decimal; let status: String }
        struct DBAppSummary: Decodable { let id: UUID }

        let dbUsers = try SupabaseManager.shared.decoder.decode([DBUserSummary].self, from: uData.data)
        let dbLoans = try SupabaseManager.shared.decoder.decode([DBLoanSummary].self, from: lData.data)
        let dbApps = try SupabaseManager.shared.decoder.decode([DBAppSummary].self, from: aData.data)
        let dbRecentApps = try SupabaseManager.shared.decoder.decode([DBEnrichedApplication].self, from: rData.data)

        let totalDisbursed = dbLoans.reduce(0) { $0 + $1.principal }
        let activeLoansCount = dbLoans.filter { $0.status.lowercased() == "active" }.count

        self.rawTotalAmount = totalDisbursed

        // Map to domain RecentApplication
        let recent = dbRecentApps.map { db -> RecentApplication in
            let name = db.users?.full_name ?? "Unknown Borrower"
            let loanType = productCache[db.loan_product_id] ?? .personal
            let amountStr = Formatting.currency(db.requested_amount)
            let status = mapAppStatus(db.status)
            let dateStr = Formatting.date(db.updated_at)

            return RecentApplication(
                id: db.id,
                name: name.isEmpty ? "Unknown Borrower" : name,
                loanType: loanType,
                amount: amountStr,
                status: status,
                date: dateStr
            )
        }

        self.snapshot = DashboardSnapshot(
            stats: DashboardStats(
                totalAmount: Formatting.currency(totalDisbursed),
                totalUser: dbUsers.count,
                activeLoans: activeLoansCount,
                applications: dbApps.count
            ),
            recentApplications: recent
        )

        let admin = environment.admin
        do {
            let logs = try await admin.fetchAuditLogs()
            self.recentAuditLogs = Array(logs.prefix(10))
        } catch {
            print("Failed to fetch dashboard audit logs: \(error)")
        }
    }

    func subscribeToRealtimeChanges() {
        guard environment != nil else { return }
        realtimeTask?.cancel()
        realtimeTask = Task {
            let client = SupabaseManager.shared.client
            let channel = client.channel("admin-dashboard-changes")
            let changes = channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "loan_applications"
            )
            do {
                try await channel.subscribeWithError()
                for await _ in changes {
                    try? await self.refreshDashboard()
                }
            } catch {
                print("Realtime subscription error: \(error)")
            }
        }
    }

    func unsubscribeFromRealtime() {
        realtimeTask?.cancel()
        realtimeTask = nil
    }
}

@MainActor
@Observable
final class AdminApplicationDetailViewModel {
    var applicationID: UUID
    var application: LoanApplication? = nil
    var borrower: User? = nil
    var loanOfficer: User? = nil
    var manager: User? = nil
    var events: [ApplicationEvent] = []

    var isLoading: Bool = false
    var error: String? = nil

    private var environment: AppEnvironment?
    private var realtimeTask: Task<Void, Never>? = nil

    init(applicationID: UUID) {
        self.applicationID = applicationID
    }

    func configure(environment: AppEnvironment?) {
        self.environment = environment
    }

    func loadDetails() async {
        isLoading = true
        error = nil

        guard let env = environment else {
            self.error = "Not connected to backend."
            isLoading = false
            return
        }

        do {
            let app = try await env.loans.fetchApplicationDetails(applicationID: applicationID)
            self.application = app

            let fetchedEvents = try await env.loans.fetchApplicationEvents(applicationID: applicationID)
            self.events = fetchedEvents

            self.borrower = try await fetchUser(id: app.borrowerID)

            if let officerID = app.assignedOfficerID {
                self.loanOfficer = try await fetchUser(id: officerID)
            } else {
                self.loanOfficer = nil
            }

            self.manager = nil
            let managerEventTypes: Set<String> = ["approved", "rejected", "sent_to_manager"]
            if let managerEvent = fetchedEvents.first(where: { managerEventTypes.contains($0.eventType.lowercased()) }),
               let actorID = managerEvent.actorID {
                if let user = try? await fetchUser(id: actorID) {
                    if user.role == .manager || user.role == .admin {
                        self.manager = user
                    }
                }
            }

            if self.manager == nil, let officerID = app.assignedOfficerID {
                let profiles = try await env.admin.listStaffProfiles()
                if let officerProfile = profiles.first(where: { $0.id == officerID }),
                   let managerID = officerProfile.reportsToID {
                    self.manager = try? await fetchUser(id: managerID)
                }
            }

        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func fetchUser(id: UUID) async throws -> User {
        let response = try await SupabaseManager.shared.client
            .from("users")
            .select("id, full_name, email, phone, role, is_active, created_at")
            .eq("id", value: id)
            .single()
            .execute()

        struct DBUser: Decodable {
            let id: UUID
            let full_name: String?
            let email: String?
            let phone: String?
            let role: String?
            let is_active: Bool?
            let created_at: Date?
        }

        let db = try SupabaseManager.shared.decoder.decode(DBUser.self, from: response.data)

        func mapRole(_ raw: String?) -> UserRole {
            switch (raw ?? "").lowercased() {
            case "loan_officer", "loanofficer": return .loanOfficer
            case "manager": return .manager
            case "admin": return .admin
            default: return .borrower
            }
        }

        return User(
            id: db.id,
            fullName: (db.full_name?.isEmpty == false ? db.full_name! : "—"),
            email: db.email ?? "",
            phone: db.phone ?? "",
            role: mapRole(db.role),
            isActive: db.is_active ?? true,
            createdAt: db.created_at ?? .now
        )
    }

#if DEBUG
    private func loadMockDetails() {
        let mockApps = MockOfficerData.assignedApplications()
        if let mockApp = mockApps.first(where: { $0.id == applicationID }) ?? mockApps.first {
            self.application = mockApp
            self.borrower = User(id: mockApp.borrowerID, fullName: "Priya Sharma", email: "priya@lms.com", phone: "+91 99999 88888", role: .borrower)
            if let loID = mockApp.assignedOfficerID {
                self.loanOfficer = User(id: loID, fullName: "Sarah Mehta", email: "sarah.mehta@lms.com", phone: "+91 99887 76543", role: .loanOfficer)
            }
            self.manager = User(id: UUID(), fullName: "Aditi Rao", email: "aditi.rao@lms.com", phone: "+91 99887 65432", role: .manager)
            self.events = [
                ApplicationEvent(applicationID: applicationID, actorID: mockApp.borrowerID, eventType: "submitted", remark: "Application submitted", fromStatus: nil, toStatus: "submitted", createdAt: mockApp.createdAt),
                ApplicationEvent(applicationID: applicationID, actorID: mockApp.assignedOfficerID, eventType: "start-review", remark: "Review started", fromStatus: "submitted", toStatus: "under_review", createdAt: mockApp.createdAt.addingTimeInterval(3600))
            ]
        }
    }
#endif

    func subscribeToRealtimeChanges() {
        guard environment != nil else { return }
        realtimeTask?.cancel()
        realtimeTask = Task {
            let client = SupabaseManager.shared.client
            let channel = client.channel("admin-app-details-\(applicationID.uuidString)")
            let changes = channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "loan_applications",
                filter: .eq("id", value: applicationID.uuidString)
            )
            do {
                try await channel.subscribeWithError()
                for await _ in changes {
                    await self.loadDetails()
                }
            } catch {
                print("Realtime subscription error: \(error)")
            }
        }
    }

    func unsubscribeFromRealtime() {
        realtimeTask?.cancel()
        realtimeTask = nil
    }
}

@MainActor
@Observable
final class UserManagementViewModel {
    enum Filter: Equatable, Hashable {
        case all
        case role(UserRole)
    }

    var users: [User] = []
    var staffProfiles: [UUID: StaffProfile] = [:]
    var currentFilter: Filter = .all
    var searchText: String = ""
    var showSuccessAlert: Bool = false
    var successMessage: String = ""
    var isLoading: Bool = false
    var loadError: String?
    var usersPendingReset: Set<UUID> = []

    private var environment: AppEnvironment?

    func configure(environment: AppEnvironment?) {
        self.environment = environment
    }

    /// Replaces the seeded mock users with the real directory from the backend.
    func load() async {
        guard let environment else { return }
        isLoading = true
        loadError = nil
        do {
            async let usersReq = environment.admin.listUsers(ids: nil)
            async let profilesReq = environment.admin.listStaffProfiles()
            async let auditReq = environment.admin.fetchAuditLogs()
            let fetchedUsers = try await usersReq
            let fetchedProfiles = try await profilesReq
            let fetchedAudit = try await auditReq
            users = fetchedUsers
            staffProfiles = Dictionary(uniqueKeysWithValues: fetchedProfiles.map { ($0.id, $0) })
            auditEntries = fetchedAudit
        } catch {
            loadError = error.localizedDescription
            print("[UserManagementViewModel] load error: \(error)")
        }
        isLoading = false
    }

    /// Creates a new staff user via the backend, then reloads the directory.
    func createStaff(email: String, fullName: String, role: UserRole, employeeID: String, temporaryPassword: String) async throws {
        guard role != .admin else {
            throw NSError(domain: "Admin", code: 400, userInfo: [NSLocalizedDescriptionKey: "Creating Admin accounts is not allowed."])
        }
        guard let environment else {
            throw NSError(domain: "Admin", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not connected to backend."])
        }
        _ = try await environment.admin.createStaff(
            email: email,
            fullName: fullName,
            role: role,
            employeeID: employeeID,
            temporaryPassword: temporaryPassword
        )
        await load()
    }

    private var loanHistory: [UUID: [Loan]] = [:]
    private var borrowerAssignments: [UUID: UUID] = [:]
    var auditEntries: [AuditEntry] = []

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
        
        do {
            if let env = environment {
                try await env.admin.updateUserRole(userID: userID, role: role)
                await load() // Reload to ensure sync
            } else {
                // Fallback for previews if environment is not set
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
            }
            
            showSuccessAlert = true
            successMessage = "Role updated for \(users[index].fullName)."
        } catch {
            loadError = "Failed to update role: \(error.localizedDescription)"
        }
    }

    func toggleUserStatus(for userID: UUID) async {
        guard let index = users.firstIndex(where: { $0.id == userID }) else { return }
        
        // Optimistic UI update
        let newStatus = !users[index].isActive
        users[index].isActive = newStatus
        
        do {
            if let env = environment {
                try await env.admin.updateUserStatus(userID: userID, isActive: newStatus)
            }
            successMessage = newStatus ? "User reactivated." : "User deactivated."
            showSuccessAlert = true
        } catch {
            // Revert UI on failure
            users[index].isActive = !newStatus
            print("Failed to update user status: \(error)")
        }
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
    var templates: [NotificationTemplate] = []
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
    var productsByCategory: [LoanCategory: [AdminLoanProduct]] = [:]
    var showSaveAlert: Bool = false
    var isSaving: Bool = false
    var isLoading: Bool = false

    private var environment: AppEnvironment?

    func configure(environment: AppEnvironment?) {
        self.environment = environment
    }

    func load() async {
        guard let environment else { return }
        isLoading = true
        defer { isLoading = false }
        guard let products = try? await environment.loans.fetchLoanProducts() else { return }

        var grouped: [LoanCategory: [AdminLoanProduct]] = [:]
        for p in products {
            let admin = AdminLoanProduct(
                id: p.id,
                name: p.name,
                minAmount: NSDecimalNumber(decimal: p.minimumAmount).doubleValue,
                maxAmount: NSDecimalNumber(decimal: p.maximumAmount).doubleValue,
                interestRate: p.displayRate,
                maxTenure: p.maximumTenureMonths,
                tenureUnit: .months,
                isActive: p.isActive
            )
            // Prefer description-stored category (set on create/update) over name heuristic
            let category: LoanCategory
            if let desc = p.description, let cat = LoanCategory(rawValue: desc) {
                category = cat
            } else {
                category = Self.category(for: p.loanType)
            }
            grouped[category, default: []].append(admin)
        }
        productsByCategory = grouped
    }

    func addProduct(_ product: AdminLoanProduct, category: LoanCategory) async throws {
        guard let environment else {
            throw NSError(domain: "Admin", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not connected to backend."])
        }
        let maxMonths = product.tenureUnit == .years ? product.maxTenure * 12 : product.maxTenure
        let minMonths = min(maxMonths, product.tenureUnit == .years ? 12 : 6)

        let domain = LoanProduct(
            name: product.name,
            description: category.rawValue,
            minimumAmount: Decimal(product.minAmount),
            maximumAmount: Decimal(product.maxAmount),
            minimumTenureMonths: minMonths,
            maximumTenureMonths: maxMonths,
            minimumInterestRate: product.interestRate,
            maximumInterestRate: product.interestRate,
            isActive: true
        )

        isSaving = true
        defer { isSaving = false }
        let created = try await environment.loans.createLoanProduct(domain)

        let adminProduct = AdminLoanProduct(
            id: created.id,
            name: created.name,
            minAmount: NSDecimalNumber(decimal: created.minimumAmount).doubleValue,
            maxAmount: NSDecimalNumber(decimal: created.maximumAmount).doubleValue,
            interestRate: created.displayRate,
            maxTenure: created.maximumTenureMonths,
            tenureUnit: .months
        )
        productsByCategory[category, default: []].append(adminProduct)
        showSaveAlert = true
    }

    private static func category(for type: LoanType) -> LoanCategory {
        switch type {
        case .personal: return .personal
        case .home: return .home
        case .vehicle: return .vehicle
        case .education: return .education
        case .business: return .business
        }
    }

    var activeCategories: [LoanCategory] {
        LoanCategory.allCases.filter { !(productsByCategory[$0] ?? []).isEmpty }
    }

    func binding(for productID: UUID) -> Binding<AdminLoanProduct>? {
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
        guard let environment, let products = productsByCategory[category] else { return }
        
        Task {
            for index in offsets {
                let product = products[index]
                do {
                    try await environment.loans.deleteLoanProduct(id: product.id)
                } catch {
                    print("Failed to delete loan product: \(error)")
                }
            }
            await MainActor.run {
                productsByCategory[category]?.remove(atOffsets: offsets)
                showSaveAlert = true
            }
        }
    }

    func updateProduct(_ product: AdminLoanProduct, category: LoanCategory) async throws {
        let maxMonths = product.tenureUnit == .years ? product.maxTenure * 12 : product.maxTenure
        let minMonths = min(maxMonths, product.tenureUnit == .years ? 12 : 6)

        let domain = LoanProduct(
            id: product.id,
            name: product.name,
            description: category.rawValue,
            minimumAmount: Decimal(product.minAmount),
            maximumAmount: Decimal(product.maxAmount),
            minimumTenureMonths: minMonths,
            maximumTenureMonths: maxMonths,
            minimumInterestRate: product.interestRate,
            maximumInterestRate: product.interestRate,
            isActive: product.isActive
        )
        
        if let environment {
            isSaving = true
            defer { isSaving = false }
            _ = try await environment.loans.updateLoanProduct(domain)
            showSaveAlert = true
        }
    }

    func markDirty() {
        // Not used as we now save immediately
    }
}
