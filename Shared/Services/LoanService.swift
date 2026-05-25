import Foundation

protocol LoanService: Sendable {
    func fetchLoanProducts() async throws -> [LoanProduct]
    func createApplication(productID: UUID, requestedAmount: Decimal, tenureMonths: Int) async throws -> LoanApplication
    func submitApplication(id: UUID) async throws -> LoanApplication
    func fetchApplications(for borrowerID: UUID) async throws -> [LoanApplication]
    func fetchAssignedApplications(officerID: UUID) async throws -> [LoanApplication]
    func updateStatus(applicationID: UUID, to status: ApplicationStatus, note: String?) async throws
    func fetchActiveLoans(borrowerID: UUID) async throws -> [Loan]
    func fetchEMISchedule(loanID: UUID) async throws -> [EMI]
}
