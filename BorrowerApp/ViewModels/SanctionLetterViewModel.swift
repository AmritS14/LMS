import Foundation
import SwiftUI
import Combine

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
            if let letter = letter, letter.status == "sent" || letter.status == "accepted" || letter.isAccepted {
                self.sanctionLetter = letter
                self.pdfURL = getLocalPDFURL(for: letter, application: application)
            } else {
                self.sanctionLetter = nil
                self.pdfURL = nil
                errorMessage = "Sanction letter is not yet available for review."
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

    private func getLocalPDFURL(for letter: SanctionLetter, application: LoanApplication) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Sanction_Letter_\(letter.loanApplicationID.uuidString).pdf")
        
        let referenceCode = "SL-" + letter.loanApplicationID.uuidString.replacingOccurrences(of: "-", with: "").prefix(6).uppercased()
        let amount = application.requestedAmount
        let rate = application.interestRate
        let tenure = application.tenureMonths
        
        let monthlyRate = (rate / 100.0) / 12.0
        let emiDouble: Double
        if monthlyRate > 0 {
            let num = Double(truncating: amount as NSDecimalNumber) * monthlyRate * pow(1.0 + monthlyRate, Double(tenure))
            let den = pow(1.0 + monthlyRate, Double(tenure)) - 1.0
            emiDouble = den > 0 ? num / den : Double(truncating: amount as NSDecimalNumber) / Double(tenure)
        } else {
            emiDouble = Double(truncating: amount as NSDecimalNumber) / Double(tenure)
        }
        let emi = Decimal(emiDouble)
        let fee = max(Decimal(2500), amount * Decimal(0.015))
        
        let pdfData = SupabaseSanctionLetterService.drawPDF(
            applicationID: letter.loanApplicationID,
            amount: amount,
            interestRate: rate,
            tenureMonths: tenure,
            loanType: application.loanType,
            borrowerName: application.borrowerName ?? "Borrower",
            referenceCode: referenceCode,
            emi: emi,
            fee: fee
        )
        
        try? pdfData.write(to: fileURL)
        return fileURL
    }
}
