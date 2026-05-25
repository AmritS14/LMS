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
            _ = try await loanService.createApplication(
                productID: product.id,
                requestedAmount: Decimal(requestedAmount),
                tenureMonths: tenureMonths
            )
            isSubmitting = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
            return false
        }
    }
}
