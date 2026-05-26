import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    var activeLoans: [Loan] = []
    var applications: [LoanApplication] = []
    var isLoading: Bool = false
    var errorMessage: String?

    /// Latest "documents requested" note from the officer, keyed by application ID.
    /// Populated for applications currently in `.additionalInfoRequired`.
    var requestNotes: [UUID: String] = [:]

    func fetchDashboardData(loanService: any LoanService, borrowerID: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            async let loansReq = loanService.fetchActiveLoans(borrowerID: borrowerID)
            async let appsReq = loanService.fetchApplications(for: borrowerID)

            let fetchedLoans = try await loansReq
            self.activeLoans = fetchedLoans.filter { $0.status == .active }
            self.applications = try await appsReq
            await loadRequestNotes(loanService: loanService)
        } catch {
            errorMessage = String(describing: error)
        }
        isLoading = false
    }

    /// For each application awaiting more documents, pull the officer's request
    /// message from its event feed so the borrower can see what's needed.
    private func loadRequestNotes(loanService: any LoanService) async {
        let pending = applications.filter { $0.status == .additionalInfoRequired }
        guard !pending.isEmpty else {
            requestNotes = [:]
            return
        }
        var notes: [UUID: String] = [:]
        for app in pending {
            guard let events = try? await loanService.fetchApplicationEvents(applicationID: app.id) else { continue }
            // The most recent document_requested event carrying a remark is the
            // officer's message to the borrower.
            if let note = events
                .filter({ $0.eventType == "document_requested" && !($0.remark ?? "").isEmpty })
                .sorted(by: { $0.createdAt > $1.createdAt })
                .first?
                .remark {
                notes[app.id] = note
            }
        }
        requestNotes = notes
    }
}
