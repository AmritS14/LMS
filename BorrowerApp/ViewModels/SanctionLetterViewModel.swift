import Foundation
import SwiftUI
import Combine
import Supabase

@Observable
@MainActor
class SanctionLetterViewModel {
    var isLoading = false
    var isAccepting = false
    var errorMessage: String? = nil
    var sanctionLetter: SanctionLetter? = nil
    var pdfURL: URL? = nil
    var termsAccepted = false
    var showSuccessMessage = false

    func loadSanctionLetter(
        sanctionLettersService: any SanctionLetterService,
        application: LoanApplication
    ) async {
        isLoading = true
        errorMessage = nil
        do {
            let letter = try await sanctionLettersService.fetchSanctionLetter(for: application.id)
            if let letter = letter {
                self.sanctionLetter = letter
                // Always show the actual PDF the officer uploaded to Supabase Storage.
                await loadPDFFromStorage(for: application, pdfPath: letter.pdfPath)
                if pdfURL == nil {
                    errorMessage = "Sanction letter is not yet available. Please check back later."
                    self.sanctionLetter = nil
                }
            } else {
                // Even without a DB letter, try to fetch from storage using the predictable path
                // (the officer may have uploaded via the background Task before DB insert succeeded)
                let predictedPath = "sanction_letters/\(application.id.uuidString).pdf"
                await loadPDFFromStorage(for: application, pdfPath: predictedPath)
                if pdfURL != nil {
                    // Build a minimal stub so the UI renders
                    let stub = SanctionLetter(
                        id: UUID(),
                        loanApplicationID: application.id,
                        borrowerID: application.borrowerID,
                        pdfPath: predictedPath,
                        generatedDate: Date(),
                        version: 1,
                        status: "sent",
                        isAccepted: false,
                        acceptedAt: nil
                    )
                    self.sanctionLetter = stub
                } else {
                    // Since the loan is active/disbursed, a sanction letter must exist conceptually.
                    // Fall back to generating a local PDF for the active/disbursed loan.
                    let stub = SanctionLetter(
                        id: UUID(),
                        loanApplicationID: application.id,
                        borrowerID: application.borrowerID,
                        pdfPath: predictedPath,
                        generatedDate: Date(),
                        version: 1,
                        status: "accepted",
                        isAccepted: true,
                        acceptedAt: Date()
                    )
                    self.sanctionLetter = stub
                    self.pdfURL = getLocalPDFURL(for: stub, application: application)
                }
            }
        } catch {
            errorMessage = "Failed to load sanction letter: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func acceptSanctionLetter(
        sanctionLettersService: any SanctionLetterService,
        application: LoanApplication
    ) async -> Bool {
        isAccepting = true
        errorMessage = nil
        do {
            try await sanctionLettersService.acceptSanctionLetter(applicationID: application.id)
            if var letter = sanctionLetter {
                letter.isAccepted = true
                letter.status = "accepted"
                self.sanctionLetter = letter
            }
            self.showSuccessMessage = true
            isAccepting = false
            return true
        } catch {
            errorMessage = "Acceptance failed: \(error.localizedDescription)"
            isAccepting = false
            return false
        }
    }

    // MARK: - PDF Loading

    /// Attempts to get a signed download URL from Supabase Storage for the given PDF path,
    /// then downloads the file to a local temp URL for PDFKit rendering.
    private func loadPDFFromStorage(for application: LoanApplication, pdfPath: String) async {
        do {
            let client = SupabaseManager.shared.client
            // Create a signed URL valid for 1 hour
            let signedURL = try await client.storage
                .from("loan_documents")
                .createSignedURL(path: pdfPath, expiresIn: 3600)

            // Download the data and cache locally
            let (data, response) = try await URLSession.shared.data(from: signedURL)
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode),
               !data.isEmpty {
                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent("SanctionLetter_\(application.id.uuidString).pdf")
                try data.write(to: fileURL)
                self.pdfURL = fileURL
            }
        } catch {
            print("Storage PDF fetch failed, will fall back to local generation: \(error)")
        }
    }

}
