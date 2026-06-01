import Foundation
import Observation

@MainActor
@Observable
final class RepaymentViewModel {
    var activeLoan: Loan?
    var emiSchedule: [EMI] = []
    var isLoading: Bool = false
    var errorMessage: String?

    func loadRepaymentData(loanService: any LoanService, loan: Loan) async {
        isLoading = true
        errorMessage = nil
        do {
            self.activeLoan = loan
            self.emiSchedule = try await loanService.fetchEMISchedule(loanID: loan.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func payEMI(_ emi: EMI) async {
        // Mock payment flow
        // In a real app, this would integrate with a payment gateway.
        if let index = emiSchedule.firstIndex(where: { $0.id == emi.id }) {
            emiSchedule[index].status = .paid
        }
    }
}
