import Foundation

protocol SanctionLetterService: Sendable {
    func generateSanctionLetter(
        applicationID: UUID,
        borrowerID: UUID,
        amount: Decimal,
        interestRate: Double,
        tenureMonths: Int,
        loanType: LoanType,
        borrowerName: String
    ) async throws -> SanctionLetter

    func fetchSanctionLetter(for applicationID: UUID) async throws -> SanctionLetter?
    func acceptSanctionLetter(applicationID: UUID) async throws
    func sendSanctionLetter(applicationID: UUID) async throws
}
