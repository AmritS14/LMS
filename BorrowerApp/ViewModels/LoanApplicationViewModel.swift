import Foundation
import Observation

@MainActor
@Observable
final class LoanApplicationViewModel {
    var isSubmitting: Bool = false
    var errorMessage: String?
    
    // Form fields
    var requestedAmount: Double = 50000
    var tenureMonths: Int = 12

    // Available loan products fetched from Supabase
    var loanProducts: [LoanProduct] = []
    var selectedProduct: LoanProduct?
    var isLoadingProducts: Bool = false

    // After submission — application ID for document linking
    var submittedApplicationID: UUID?

    // Uploaded document IDs for this application
    var uploadedDocumentIDs: [UUID] = []

    // Document linking status
    var isLinkingDocuments: Bool = false
    var documentsLinked: Bool = false

    func loadProducts(loanService: any LoanService) async {
        isLoadingProducts = true
        do {
            loanProducts = try await loanService.fetchLoanProducts()
            // Auto-select first product if none selected
            if selectedProduct == nil, let first = loanProducts.first {
                selectedProduct = first
                // Set defaults from product
                requestedAmount = NSDecimalNumber(decimal: first.minimumAmount).doubleValue
                tenureMonths = first.minimumTenureMonths
            }
        } catch {
            errorMessage = "Failed to load loan products: \(error.localizedDescription)"
        }
        isLoadingProducts = false
    }

    func submit(
        loanService: any LoanService,
        borrowerID: UUID
    ) async -> Bool {
        guard let product = selectedProduct else {
            errorMessage = "Please select a loan product"
            return false
        }
        
        isSubmitting = true
        errorMessage = nil
        do {
            let application = try await loanService.createApplication(
                productID: product.id,
                requestedAmount: Decimal(requestedAmount),
                tenureMonths: tenureMonths
            )
            submittedApplicationID = application.id
            isSubmitting = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
            return false
        }
    }

    /// Called after documents have been uploaded. Links all uploaded document IDs to the application.
    func linkDocuments(loanService: any LoanService) async -> Bool {
        guard let appID = submittedApplicationID, !uploadedDocumentIDs.isEmpty else {
            return true // Nothing to link
        }

        isLinkingDocuments = true
        errorMessage = nil
        do {
            try await loanService.documentsUploaded(
                applicationID: appID,
                documentIDs: uploadedDocumentIDs
            )
            documentsLinked = true
            isLinkingDocuments = false
            return true
        } catch {
            errorMessage = "Failed to link documents: \(error.localizedDescription)"
            isLinkingDocuments = false
            return false
        }
    }

    func addUploadedDocumentID(_ id: UUID) {
        if !uploadedDocumentIDs.contains(id) {
            uploadedDocumentIDs.append(id)
        }
    }

    func reset() {
        submittedApplicationID = nil
        uploadedDocumentIDs = []
        documentsLinked = false
        errorMessage = nil
    }
}
