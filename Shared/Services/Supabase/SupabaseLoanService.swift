import Foundation
import Supabase

/// Supabase implementation of LoanService
actor SupabaseLoanService: LoanService {
    private let client: SupabaseClient
    
    // Cached mapping of loan_product_id -> LoanType
    private var productCache: [UUID: LoanType] = [:]

    init(client: SupabaseClient) {
        self.client = client
    }
    
    // MARK: - DB Models
    
    private struct DBLoanProduct: Decodable {
        let id: UUID
        let name: String
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
    
    // MARK: - Helpers
    
    private func fetchProductCacheIfNeeded() async throws {
        if productCache.isEmpty {
            let products: [DBLoanProduct] = try await client
                .from("loan_products")
                .select()
                .execute()
                .value
                
            for product in products {
                let lowerName = product.name.lowercased()
                if lowerName.contains("home") { productCache[product.id] = .home }
                else if lowerName.contains("vehicle") || lowerName.contains("auto") { productCache[product.id] = .vehicle }
                else if lowerName.contains("education") { productCache[product.id] = .education }
                else if lowerName.contains("business") { productCache[product.id] = .business }
                else { productCache[product.id] = .personal }
            }
        }
    }
    
    private func mapAppStatus(_ raw: String) -> ApplicationStatus {
        switch raw.lowercased() {
        case "submitted": return .submitted
        case "under_review": return .underReview
        case "document_pending": return .additionalInfoRequired
        case "pending_manager_approval": return .escalated
        case "approved": return .approved
        case "rejected": return .rejected
        case "disbursed": return .disbursed
        case "closed": return .closed
        default: return .draft
        }
    }
    
    private func mapLoanStatus(_ raw: String) -> LoanStatus {
        switch raw.lowercased() {
        case "settled": return .settled
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
    
    private func toDomainApplication(_ dbApp: DBLoanApplication) -> LoanApplication {
        return LoanApplication(
            id: dbApp.id,
            borrowerID: dbApp.borrower_id,
            assignedOfficerID: dbApp.assigned_officer_id,
            loanType: productCache[dbApp.loan_product_id] ?? .personal,
            requestedAmount: dbApp.requested_amount,
            tenureMonths: dbApp.tenure_months,
            interestRate: dbApp.interest_rate,
            status: mapAppStatus(dbApp.status),
            documentIDs: [],
            createdAt: dbApp.created_at,
            updatedAt: dbApp.updated_at
        )
    }

    // MARK: - LoanService Protocol

    func createApplication(_ draft: LoanApplication) async throws -> LoanApplication {
        try await fetchProductCacheIfNeeded()
        // Find the product ID that matches the loanType
        let productID = productCache.first(where: { $0.value == draft.loanType })?.key
        
        guard let validProductID = productID else {
            throw NSError(domain: "LoanService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Loan Type"])
        }
        
        // Call the NestJS API
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])
        }
        
        let url = URL(string: "https://arshitsinghal-lms-backend.hf.space/api/applications")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "loanProductId": validProductID.uuidString,
            "requestedAmount": NSDecimalNumber(decimal: draft.requestedAmount).doubleValue,
            "tenureMonths": draft.tenureMonths
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpRes = response as? HTTPURLResponse, !(200...299).contains(httpRes.statusCode) {
            let errorStr = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "API", code: httpRes.statusCode, userInfo: [NSLocalizedDescriptionKey: errorStr])
        }
        
        // Re-fetch the user's applications to get the newly created one (or we could parse the API response)
        // We'll just return the draft with submitted status to satisfy UI immediately, 
        // as the UI will likely trigger a re-fetch.
        var submittedApp = draft
        submittedApp.status = .submitted
        return submittedApp
    }

    func submitApplication(id: UUID) async throws -> LoanApplication {
        // Not used by the borrower app in this flow, creation is submission.
        throw NSError(domain: "LoanService", code: 501, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    func fetchApplications(for borrowerID: UUID) async throws -> [LoanApplication] {
        try await fetchProductCacheIfNeeded()
        let dbApps: [DBLoanApplication] = try await client
            .from("loan_applications")
            .select()
            .eq("borrower_id", value: borrowerID)
            .order("created_at", ascending: false)
            .execute()
            .value
            
        return dbApps.map(toDomainApplication)
    }

    func fetchAssignedApplications(officerID: UUID) async throws -> [LoanApplication] {
        try await fetchProductCacheIfNeeded()
        let dbApps: [DBLoanApplication] = try await client
            .from("loan_applications")
            .select()
            .eq("assigned_officer_id", value: officerID)
            .order("created_at", ascending: false)
            .execute()
            .value
            
        return dbApps.map(toDomainApplication)
    }

    func updateStatus(applicationID: UUID, to status: ApplicationStatus, note: String?) async throws {
        // Typically only officers do this via API. We'll leave unimplemented for borrower migration.
        throw NSError(domain: "LoanService", code: 501, userInfo: [NSLocalizedDescriptionKey: "Not implemented for borrower"])
    }

    func fetchActiveLoans(borrowerID: UUID) async throws -> [Loan] {
        let dbLoans: [DBLoan] = try await client
            .from("loans")
            .select()
            .eq("borrower_id", value: borrowerID)
            .execute()
            .value
            
        return dbLoans.map { dbLoan in
            Loan(
                id: dbLoan.id,
                applicationID: dbLoan.application_id,
                borrowerID: dbLoan.borrower_id,
                loanType: .personal, // We would need to join loan_applications to get the type properly, but keeping it simple
                principal: dbLoan.principal,
                interestRate: dbLoan.interest_rate,
                tenureMonths: dbLoan.tenure_months,
                disbursementDate: dbLoan.disbursement_date,
                outstandingBalance: dbLoan.outstanding_balance,
                emiSchedule: [], // EMIs fetched separately
                status: mapLoanStatus(dbLoan.status)
            )
        }
    }

    func fetchEMISchedule(loanID: UUID) async throws -> [EMI] {
        let dbEmis: [DBEMI] = try await client
            .from("emis")
            .select()
            .eq("loan_id", value: loanID)
            .order("installment_number", ascending: true)
            .execute()
            .value
            
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
}
