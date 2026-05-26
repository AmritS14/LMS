import Foundation
import Supabase

/// Supabase implementation of LoanService
actor SupabaseLoanService: LoanService {
    private let client: SupabaseClient
    private let apiBase = "https://arshitsinghal-lms-backend.hf.space"

    init(client: SupabaseClient) {
        self.client = client
    }
    
    // MARK: - DB Models (snake_case to match Postgres columns)
    
    private struct DBLoanProduct: Decodable {
        let id: UUID
        let name: String
        let description: String?
        let minimum_amount: Decimal
        let maximum_amount: Decimal
        let minimum_tenure_months: Int
        let maximum_tenure_months: Int
        let minimum_interest_rate: Double
        let maximum_interest_rate: Double
        let is_active: Bool
    }
    
    private struct DBLoanApplication: Decodable {
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
    }
    
    private struct DBLoan: Decodable {
        let id: UUID
        let application_id: UUID
        let borrower_id: UUID
        let principal: Decimal
        let interest_rate: Double
        let tenure_months: Int
        let disbursement_date: Date
        let outstanding_balance: Decimal
        let status: String
    }
    
    private struct DBEMI: Decodable {
        let id: UUID
        let loan_id: UUID
        let installment_number: Int
        let due_date: Date
        let principal_component: Decimal
        let interest_component: Decimal
        let total_amount: Decimal
        let status: String
        let paid_at: Date?
    }
    
    
    // MARK: - Mappers
    
    private func mapAppStatus(_ raw: String) -> ApplicationStatus {
        switch raw.lowercased() {
        case "submitted": return .submitted
        case "assigned": return .submitted // assigned is still pending from borrower perspective
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
    
    private func mapLoanStatus(_ raw: String) -> LoanStatus {
        switch raw.lowercased() {
        case "settled", "closed": return .settled
        case "defaulted": return .defaulted
        default: return .active
        }
    }
    
    private func mapEMIStatus(_ raw: String) -> EMIStatus {
        switch raw.lowercased() {
        case "paid": return .paid
        case "overdue": return .overdue
        default: return .upcoming
        }
    }
    
    private func toDomainProduct(_ db: DBLoanProduct) -> LoanProduct {
        LoanProduct(
            id: db.id,
            name: db.name,
            description: db.description,
            minimumAmount: db.minimum_amount,
            maximumAmount: db.maximum_amount,
            minimumTenureMonths: db.minimum_tenure_months,
            maximumTenureMonths: db.maximum_tenure_months,
            minimumInterestRate: db.minimum_interest_rate,
            maximumInterestRate: db.maximum_interest_rate,
            isActive: db.is_active
        )
    }
    
    // Cached products for mapping loan_product_id -> LoanType
    private var productCache: [UUID: LoanType] = [:]
    
    private func ensureProductCache() async throws {
        if productCache.isEmpty {
            let products = try await fetchLoanProducts()
            for p in products {
                productCache[p.id] = p.loanType
            }
        }
    }
    
    private func toDomainApplication(_ db: DBLoanApplication) -> LoanApplication {
        LoanApplication(
            id: db.id,
            borrowerID: db.borrower_id,
            assignedOfficerID: db.assigned_officer_id,
            loanType: productCache[db.loan_product_id] ?? .personal,
            requestedAmount: db.requested_amount,
            tenureMonths: db.tenure_months,
            interestRate: db.interest_rate,
            status: mapAppStatus(db.status),
            documentIDs: [],
            createdAt: db.created_at,
            updatedAt: db.updated_at
        )
    }

    // MARK: - LoanService Protocol
    
    func fetchLoanProducts() async throws -> [LoanProduct] {
        let response = try await client
            .from("loan_products")
            .select()
            .eq("is_active", value: true)
            .execute()
        
        let dbProducts = try SupabaseManager.shared.decoder.decode([DBLoanProduct].self, from: response.data)
        return dbProducts.map(toDomainProduct)
    }

    func createApplication(productID: UUID, requestedAmount: Decimal, tenureMonths: Int) async throws -> LoanApplication {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to apply"])
        }
        
        let url = URL(string: "\(apiBase)/applications")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "loanProductId": productID.uuidString,
            "requestedAmount": NSDecimalNumber(decimal: requestedAmount).doubleValue,
            "tenureMonths": tenureMonths
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        if let httpRes = httpResponse as? HTTPURLResponse, !(200...299).contains(httpRes.statusCode) {
            let errorStr = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "API", code: httpRes.statusCode, userInfo: [NSLocalizedDescriptionKey: "Application failed: \(errorStr)"])
        }
        
        // Parse the response from the backend
        let dbApp = try SupabaseManager.shared.decoder.decode(DBLoanApplication.self, from: data)
        try await ensureProductCache()
        return toDomainApplication(dbApp)
    }

    func submitApplication(id: UUID) async throws -> LoanApplication {
        throw NSError(domain: "LoanService", code: 501, userInfo: [NSLocalizedDescriptionKey: "Not implemented — creation IS submission"])
    }

    func fetchApplications(for borrowerID: UUID) async throws -> [LoanApplication] {
        try await ensureProductCache()
        let response = try await client
            .from("loan_applications")
            .select()
            .eq("borrower_id", value: borrowerID)
            .order("created_at", ascending: false)
            .execute()
            
        let dbApps = try SupabaseManager.shared.decoder.decode([DBLoanApplication].self, from: response.data)
        return dbApps.map(toDomainApplication)
    }

    func fetchAssignedApplications(officerID: UUID) async throws -> [LoanApplication] {
        try await ensureProductCache()
        let response = try await client
            .from("loan_applications")
            .select()
            .eq("assigned_officer_id", value: officerID)
            .order("created_at", ascending: false)
            .execute()
            
        let dbApps = try SupabaseManager.shared.decoder.decode([DBLoanApplication].self, from: response.data)
        return dbApps.map(toDomainApplication)
    }

    func updateStatus(applicationID: UUID, to status: ApplicationStatus, note: String?) async throws {
        // Route through specific workflow endpoints based on target status
        switch status {
        case .underReview:
            try await startReview(applicationID: applicationID)
        case .approved:
            try await approveApplication(applicationID: applicationID, remark: note)
        case .rejected:
            try await rejectApplication(applicationID: applicationID, remark: note)
        case .escalated:
            try await sendToManager(applicationID: applicationID, remark: note)
        default:
            throw NSError(domain: "LoanService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Use specific workflow actions for status transitions"])
        }
    }

    func fetchActiveLoans(borrowerID: UUID) async throws -> [Loan] {
        try await ensureProductCache()
        let response = try await client
            .from("loans")
            .select()
            .eq("borrower_id", value: borrowerID)
            .execute()
            
        let dbLoans = try SupabaseManager.shared.decoder.decode([DBLoan].self, from: response.data)
        
        // Fetch EMIs for each loan
        var loans: [Loan] = []
        for dbLoan in dbLoans {
            let emis = try await fetchEMISchedule(loanID: dbLoan.id)
            // Determine loan type from the application's product
            let loanType = await loanTypeForApplication(dbLoan.application_id)
            loans.append(Loan(
                id: dbLoan.id,
                applicationID: dbLoan.application_id,
                borrowerID: dbLoan.borrower_id,
                loanType: loanType,
                principal: dbLoan.principal,
                interestRate: dbLoan.interest_rate,
                tenureMonths: dbLoan.tenure_months,
                disbursementDate: dbLoan.disbursement_date,
                outstandingBalance: dbLoan.outstanding_balance,
                emiSchedule: emis,
                status: mapLoanStatus(dbLoan.status)
            ))
        }
        return loans
    }

    private func loanTypeForApplication(_ applicationID: UUID) async -> LoanType {
        do {
            let response = try await client
                .from("loan_applications")
                .select("loan_product_id")
                .eq("id", value: applicationID)
                .single()
                .execute()
            struct AppProduct: Decodable { let loan_product_id: UUID }
            let appProd = try SupabaseManager.shared.decoder.decode(AppProduct.self, from: response.data)
            return productCache[appProd.loan_product_id] ?? .personal
        } catch {
            return .personal
        }
    }

    func fetchEMISchedule(loanID: UUID) async throws -> [EMI] {
        let response = try await client
            .from("emis")
            .select()
            .eq("loan_id", value: loanID)
            .order("installment_number", ascending: true)
            .execute()
            
        let dbEmis = try SupabaseManager.shared.decoder.decode([DBEMI].self, from: response.data)
            
        return dbEmis.map { dbEmi in
            EMI(
                id: dbEmi.id,
                installmentNumber: dbEmi.installment_number,
                dueDate: dbEmi.due_date,
                principalComponent: dbEmi.principal_component,
                interestComponent: dbEmi.interest_component,
                totalAmount: dbEmi.total_amount,
                status: mapEMIStatus(dbEmi.status),
                paidAt: dbEmi.paid_at
            )
        }
    }

    // MARK: - EMI Payment

    func payEMI(emiID: UUID) async throws -> EMI {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to pay EMIs"])
        }

        let url = URL(string: "\(apiBase)/emis/\(emiID.uuidString)/pay")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, httpResponse) = try await URLSession.shared.data(for: request)

        if let httpRes = httpResponse as? HTTPURLResponse, !(200...299).contains(httpRes.statusCode) {
            let errorStr = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "API", code: httpRes.statusCode, userInfo: [NSLocalizedDescriptionKey: "Payment failed: \(errorStr)"])
        }

        // Backend returns { emi: {...}, loan: {...} }
        // Parse the EMI from the response
        struct PayResponse: Decodable {
            let emi: DBEMI
        }
        let payResponse = try SupabaseManager.shared.decoder.decode(PayResponse.self, from: data)
        let dbEmi = payResponse.emi
        return EMI(
            id: dbEmi.id,
            installmentNumber: dbEmi.installment_number,
            dueDate: dbEmi.due_date,
            principalComponent: dbEmi.principal_component,
            interestComponent: dbEmi.interest_component,
            totalAmount: dbEmi.total_amount,
            status: mapEMIStatus(dbEmi.status),
            paidAt: dbEmi.paid_at
        )
    }

    // MARK: - Staff Workflow Actions

    func startReview(applicationID: UUID) async throws {
        try await postWorkflowAction(applicationID: applicationID, action: "start-review", body: nil)
    }

    func requestDocuments(applicationID: UUID, documentTypes: [String], remark: String?) async throws {
        var body: [String: Any] = ["documentTypes": documentTypes]
        if let remark { body["remark"] = remark }
        try await postWorkflowAction(applicationID: applicationID, action: "request-documents", body: body)
    }

    func documentsUploaded(applicationID: UUID, documentIDs: [UUID]) async throws {
        let body: [String: Any] = ["documentIds": documentIDs.map(\.uuidString)]
        try await postWorkflowAction(applicationID: applicationID, action: "documents-uploaded", body: body)
    }

    func sendToManager(applicationID: UUID, remark: String?) async throws {
        var body: [String: Any]? = nil
        if let remark { body = ["remark": remark] }
        try await postWorkflowAction(applicationID: applicationID, action: "send-to-manager", body: body)
    }

    func approveApplication(applicationID: UUID, remark: String?) async throws {
        var body: [String: Any]? = nil
        if let remark { body = ["remark": remark] }
        try await postWorkflowAction(applicationID: applicationID, action: "approve", body: body)
    }

    func rejectApplication(applicationID: UUID, remark: String?) async throws {
        var body: [String: Any]? = nil
        if let remark { body = ["remark": remark] }
        try await postWorkflowAction(applicationID: applicationID, action: "reject", body: body)
    }

    func fetchApplicationDetails(applicationID: UUID) async throws -> LoanApplication {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let url = URL(string: "\(apiBase)/applications/\(applicationID.uuidString)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        if let httpRes = httpResponse as? HTTPURLResponse, !(200...299).contains(httpRes.statusCode) {
            let errorStr = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "API", code: httpRes.statusCode, userInfo: [NSLocalizedDescriptionKey: errorStr])
        }

        try await ensureProductCache()
        let dbApp = try SupabaseManager.shared.decoder.decode(DBLoanApplication.self, from: data)
        return toDomainApplication(dbApp)
    }

    private struct DBApplicationEvent: Decodable {
        let id: UUID
        let application_id: UUID
        let actor_id: UUID?
        let event_type: String
        let remark: String?
        let from_status: String?
        let to_status: String?
        let created_at: Date
    }

    func fetchApplicationEvents(applicationID: UUID) async throws -> [ApplicationEvent] {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let url = URL(string: "\(apiBase)/applications/\(applicationID.uuidString)/events")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        if let httpRes = httpResponse as? HTTPURLResponse, !(200...299).contains(httpRes.statusCode) {
            return []
        }

        let dbEvents = try SupabaseManager.shared.decoder.decode([DBApplicationEvent].self, from: data)
        return dbEvents.map { db in
            ApplicationEvent(
                id: db.id,
                applicationID: db.application_id,
                actorID: db.actor_id,
                eventType: db.event_type,
                remark: db.remark,
                fromStatus: db.from_status,
                toStatus: db.to_status,
                createdAt: db.created_at
            )
        }
    }

    // MARK: - Private Helper

    private func postWorkflowAction(applicationID: UUID, action: String, body: [String: Any]?) async throws {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let url = URL(string: "\(apiBase)/applications/\(applicationID.uuidString)/\(action)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } else {
            request.httpBody = "{}".data(using: .utf8)
        }

        let (data, httpResponse) = try await URLSession.shared.data(for: request)

        if let httpRes = httpResponse as? HTTPURLResponse, !(200...299).contains(httpRes.statusCode) {
            let errorStr = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "API", code: httpRes.statusCode, userInfo: [NSLocalizedDescriptionKey: "\(action) failed: \(errorStr)"])
        }
    }
}
