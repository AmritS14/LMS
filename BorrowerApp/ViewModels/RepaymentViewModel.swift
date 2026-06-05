import Foundation
import Observation

@MainActor
@Observable
final class RepaymentViewModel {
    var activeLoan: Loan?
    var emiSchedule: [EMI] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private var loanService: (any LoanService)?

    func loadRepaymentData(loanService: any LoanService, loan: Loan) async {
        self.loanService = loanService
        if activeLoan == nil {
            isLoading = true
        }
        errorMessage = nil
        do {
            self.activeLoan = loan
            self.emiSchedule = try await loanService.fetchEMISchedule(loanID: loan.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
