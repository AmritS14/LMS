import Foundation

actor MockSanctionLetterService: SanctionLetterService {
    private var sanctionLetters: [UUID: SanctionLetter] = [:]

    func generateSanctionLetter(
        applicationID: UUID,
        borrowerID: UUID,
        amount: Decimal,
        interestRate: Double,
        tenureMonths: Int,
        loanType: LoanType,
        borrowerName: String
    ) async throws -> SanctionLetter {
        try await Task.sleep(for: .milliseconds(400))
        let letter = SanctionLetter(
            id: UUID(),
            loanApplicationID: applicationID,
            borrowerID: borrowerID,
            pdfPath: "mock_sanction_letters/\(applicationID.uuidString).pdf",
            generatedDate: Date(),
            version: 1,
            status: "generated",
            isAccepted: false,
            acceptedAt: nil
        )
        sanctionLetters[applicationID] = letter
        return letter
    }

    func fetchSanctionLetter(for applicationID: UUID) async throws -> SanctionLetter? {
        try await Task.sleep(for: .milliseconds(150))
        return sanctionLetters[applicationID]
    }

    func acceptSanctionLetter(applicationID: UUID) async throws {
        try await Task.sleep(for: .milliseconds(300))
        guard var letter = sanctionLetters[applicationID] else {
            throw NSError(domain: "MockSanctionLetterService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Sanction letter not found"])
        }
        letter.isAccepted = true
        letter.acceptedAt = Date()
        letter.status = "accepted"
        sanctionLetters[applicationID] = letter
    }

    func sendSanctionLetter(applicationID: UUID) async throws {
        try await Task.sleep(for: .milliseconds(200))
        guard var letter = sanctionLetters[applicationID] else {
            throw NSError(domain: "MockSanctionLetterService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Sanction letter not found"])
        }
        letter.status = "sent"
        sanctionLetters[applicationID] = letter
    }
}
