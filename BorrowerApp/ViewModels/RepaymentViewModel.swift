import Foundation
import Observation

@MainActor
@Observable
final class RepaymentViewModel {
    var activeLoan: Loan?
    var emiSchedule: [EMI] = []
    var isLoading: Bool = false
    var isPaying: Bool = false
    var errorMessage: String?
    var paymentSuccess: Bool = false

    private var loanService: (any LoanService)?

    func loadRepaymentData(loanService: any LoanService, loan: Loan) async {
        self.loanService = loanService
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
        guard let loanService else {
            errorMessage = "Service not available"
            return
        }
        
        isPaying = true
        errorMessage = nil
        paymentSuccess = false
        
        do {
            let updatedEMI = try await loanService.payEMI(emiID: emi.id)
            
            // Update the local EMI schedule
            if let index = emiSchedule.firstIndex(where: { $0.id == emi.id }) {
                emiSchedule[index] = updatedEMI
            }
            
            // Refresh the loan data to get updated outstanding balance
            if let loan = activeLoan {
                let loans = try await loanService.fetchActiveLoans(borrowerID: loan.borrowerID)
                if let refreshedLoan = loans.first(where: { $0.id == loan.id }) {
                    self.activeLoan = refreshedLoan
                    self.emiSchedule = refreshedLoan.emiSchedule
                }
            }
            
            paymentSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isPaying = false
    }
}
