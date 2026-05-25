import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    var activeLoans: [Loan] = []
    var applications: [LoanApplication] = []
    var isLoading: Bool = false
    var errorMessage: String?

    func fetchDashboardData(loanService: any LoanService, borrowerID: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            async let loansReq = loanService.fetchActiveLoans(borrowerID: borrowerID)
            async let appsReq = loanService.fetchApplications(for: borrowerID)
            
            let fetchedLoans = try await loansReq
            self.activeLoans = fetchedLoans.filter { $0.status == .active }
            self.applications = try await appsReq
        } catch {
            errorMessage = String(describing: error)
        }
        isLoading = false
    }
}
