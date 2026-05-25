import Foundation
import Observation

@MainActor
@Observable
final class LoanApplicationViewModel {
    var draft: LoanApplication?
    var isSubmitting: Bool = false
    var errorMessage: String?
    
    var requestedAmount: Double = 50000
    var tenureMonths: Int = 12
    var purpose: String = ""

    func submit(
        loanService: any LoanService,
        borrowerID: UUID,
        loanType: LoanType,
        interestRate: Double
    ) async -> Bool {
        isSubmitting = true
        errorMessage = nil
        do {
            let app = LoanApplication(
                borrowerID: borrowerID,
                loanType: loanType,
                requestedAmount: Decimal(requestedAmount),
                tenureMonths: tenureMonths,
                interestRate: interestRate,
                status: .draft
            )
            let created = try await loanService.createApplication(app)
            isSubmitting = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
            return false
        }
    }
}
