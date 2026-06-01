import Foundation

protocol LoanService: Sendable {
    func fetchLoanProducts() async throws -> [LoanProduct]
    /// Admin-only: create a new loan product. Requires the admin role server-side.
    func createLoanProduct(_ product: LoanProduct) async throws -> LoanProduct
    func updateLoanProduct(_ product: LoanProduct) async throws -> LoanProduct
    func deleteLoanProduct(id: UUID) async throws
    func createApplication(productID: UUID, requestedAmount: Decimal, tenureMonths: Int) async throws -> LoanApplication
    func submitApplication(id: UUID) async throws -> LoanApplication
    func fetchApplications(for borrowerID: UUID) async throws -> [LoanApplication]
    func fetchAssignedApplications(officerID: UUID) async throws -> [LoanApplication]
    func fetchApplications(statuses: [String]) async throws -> [LoanApplication]
    func updateStatus(applicationID: UUID, to status: ApplicationStatus, note: String?) async throws
    func fetchActiveLoans(borrowerID: UUID) async throws -> [Loan]
    func fetchEMISchedule(loanID: UUID) async throws -> [EMI]
    func payEMI(emiID: UUID) async throws -> EMI

    // Staff workflow actions
    func startReview(applicationID: UUID) async throws
    func requestDocuments(applicationID: UUID, documentTypes: [String], remark: String?) async throws
    func documentsUploaded(applicationID: UUID, documentIDs: [UUID]) async throws
    func sendToManager(applicationID: UUID, remark: String?) async throws
    func approveApplication(applicationID: UUID, remark: String?) async throws
    func rejectApplication(applicationID: UUID, remark: String?) async throws
    func disburseLoan(applicationID: UUID) async throws
    func fetchApplicationDetails(applicationID: UUID) async throws -> LoanApplication
    func fetchApplicationEvents(applicationID: UUID) async throws -> [ApplicationEvent]
    
    // Foreclosure actions
    func calculateForeclosure(loanID: UUID) async throws -> ForeclosureDetails
    func forecloseLoan(loanID: UUID, totalPayoff: Decimal) async throws -> Loan
}
