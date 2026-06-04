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

    /// PDF storage path for each application that has had its sanction letter issued,
    /// keyed by application ID. Populated by scanning application events.
    var sanctionLetterPDFPaths: [UUID: String] = [:]

    func fetchDashboardData(
        loanService: any LoanService,
        sanctionLetterService: any SanctionLetterService,
        borrowerID: UUID
    ) async {
        if activeLoans.isEmpty && applications.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        do {
            async let loansReq = loanService.fetchActiveLoans(borrowerID: borrowerID)
            async let appsReq = loanService.fetchApplications(for: borrowerID)

            let fetchedLoans = try await loansReq
            self.activeLoans = fetchedLoans.filter { $0.status == .active }
            
            var fetchedApps = try await appsReq
            
            await withTaskGroup(of: (Int, SanctionLetter?).self) { group in
                for i in 0..<fetchedApps.count {
                    let app = fetchedApps[i]
                    if app.status == .approved || app.status == .disbursed || app.status == .recommended {
                        group.addTask {
                            let letter = try? await sanctionLetterService.fetchSanctionLetter(for: app.id)
                            return (i, letter)
                        }
                    }
                }
                for await (i, letter) in group {
                    if let letter = letter {
                        fetchedApps[i].sanctionLetter = letter
                    }
                }
            }
            
            self.applications = fetchedApps
            
            await loadRequestNotes(loanService: loanService)
            await loadSanctionLetterEvents(loanService: loanService)
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
        await withTaskGroup(of: (UUID, String?).self) { group in
            for app in pending {
                group.addTask {
                    guard let events = try? await loanService.fetchApplicationEvents(applicationID: app.id) else { return (app.id, nil) }
                    let note = events
                        .filter({ $0.eventType == "document_requested" && !($0.remark ?? "").isEmpty })
                        .sorted(by: { $0.createdAt > $1.createdAt })
                        .first?
                        .remark
                    return (app.id, note)
                }
            }
            for await (id, note) in group {
                if let note = note {
                    notes[id] = note
                }
            }
        }
        requestNotes = notes
    }

    /// For each approved/recommended application, scan events for a
    /// `[SANCTION_LETTER_ISSUED]` remark which carries the PDF path in `metadata`.
    /// This allows the borrower to download the letter without a dedicated table.
    private func loadSanctionLetterEvents(loanService: any LoanService) async {
        let eligible = applications.filter {
            $0.status == .approved || $0.status == .recommended || $0.status == .disbursed
        }
        
        var paths: [UUID: String] = [:]
        await withTaskGroup(of: (UUID, String?).self) { group in
            for app in eligible {
                group.addTask {
                    guard let events = try? await loanService.fetchApplicationEvents(applicationID: app.id) else { return (app.id, nil) }
                    let slEvent = events
                        .filter({ $0.remark == "[SANCTION_LETTER_ISSUED]" })
                        .sorted(by: { $0.createdAt > $1.createdAt })
                        .first
                    if slEvent != nil {
                        return (app.id, "sanction_letters/\(app.id.uuidString).pdf")
                    }
                    return (app.id, nil)
                }
            }
            for await (id, path) in group {
                if let path = path {
                    paths[id] = path
                }
            }
        }
        sanctionLetterPDFPaths = paths
    }
}
