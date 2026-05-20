//
//  LoanConfigViewModel.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI
import Observation

// MARK: - Loan Configuration ViewModel

/// Manages the state for the Loan Configuration form (US-41).
/// Holds editable loan products grouped by category
/// and handles save operations with async/await.
@Observable
@MainActor
final class LoanConfigViewModel {

    // MARK: - State

    /// Loan products grouped by category — the source of truth for the form.
    var productsByCategory: [LoanCategory: [LoanProduct]]

    /// Tracks whether a save operation is currently in progress.
    var isSaving: Bool = false

    /// Controls display of the save success alert.
    var showSaveAlert: Bool = false

    /// Tracks whether unsaved changes exist.
    var hasUnsavedChanges: Bool = false

    // MARK: - Initialization

    init(products: [LoanCategory: [LoanProduct]] = LoanProduct.sampleProducts) {
        self.productsByCategory = products
    }

    // MARK: - Computed Properties

    /// Ordered list of categories that have at least one product.
    var activeCategories: [LoanCategory] {
        LoanCategory.allCases.filter { category in
            guard let products = productsByCategory[category] else { return false }
            return !products.isEmpty
        }
    }

    /// Total count of all loan products across categories.
    var totalProductCount: Int {
        productsByCategory.values.reduce(0) { $0 + $1.count }
    }

    // MARK: - Actions

    /// Saves the current loan configuration.
    /// Simulates a network call with a brief delay.
    func saveConfiguration() async {
        isSaving = true
        defer { isSaving = false }

        // Simulate network persistence
        try? await Task.sleep(for: .seconds(1))
        
        AuditLogger.log(action: "Loan Configurations Saved", details: "Total Products: \(totalProductCount)")

        hasUnsavedChanges = false
        showSaveAlert = true
    }

    /// Marks that the user has made edits to the configuration.
    func markDirty() {
        if !hasUnsavedChanges {
            hasUnsavedChanges = true
        }
    }
    
    /// Adds a new loan product, preventing duplicate names.
    func addLoanProduct(category: LoanCategory, name: String) throws {
        // Prevent duplicate names across all categories
        let isDuplicate = productsByCategory.values.flatMap { $0 }.contains { $0.name.lowercased() == name.lowercased() }
        guard !isDuplicate else {
            throw NSError(domain: "DuplicateError", code: 1, userInfo: [NSLocalizedDescriptionKey: "A loan product with this name already exists."])
        }
        
        let newProduct = LoanProduct(name: name, minAmount: 10000, maxAmount: 100000, interestRate: 10.0, maxTenure: 12)
        productsByCategory[category, default: []].append(newProduct)
        AuditLogger.log(action: "Loan Product Added", details: "Name: \(name), Category: \(category.rawValue)")
        markDirty()
    }
    
    /// Deletes loans from a specific category.
    func deleteLoans(category: LoanCategory, at offsets: IndexSet) {
        guard let products = productsByCategory[category] else { return }
        
        for index in offsets {
            let product = products[index]
            AuditLogger.log(action: "Loan Product Deleted", details: "Name: \(product.name), Category: \(category.rawValue)")
        }
        
        productsByCategory[category]?.remove(atOffsets: offsets)
        markDirty()
    }

    /// Returns a binding to a specific product within any category.
    func binding(for productID: UUID) -> Binding<LoanProduct>? {
        for category in productsByCategory.keys {
            if let catIndex = productsByCategory[category]?.firstIndex(where: { $0.id == productID }) {
                return Binding(
                    get: { [weak self] in
                        self?.productsByCategory[category]?[catIndex]
                            ?? LoanProduct(name: "", minAmount: 0, maxAmount: 0, interestRate: 0, maxTenure: 0)
                    },
                    set: { [weak self] newValue in
                        self?.productsByCategory[category]?[catIndex] = newValue
                        self?.markDirty()
                    }
                )
            }
        }
        return nil
    }

    /// Returns a binding to a specific product within a category.
    /// - Parameters:
    ///   - category: The loan category.
    ///   - productID: The UUID of the product.
    /// - Returns: A `Binding<LoanProduct>` or `nil` if not found.
    func binding(for category: LoanCategory, productID: UUID) -> Binding<LoanProduct>? {
        guard let catIndex = productsByCategory[category]?.firstIndex(where: { $0.id == productID }) else {
            return nil
        }

        return Binding(
            get: { [weak self] in
                self?.productsByCategory[category]?[catIndex]
                    ?? LoanProduct(name: "", minAmount: 0, maxAmount: 0, interestRate: 0, maxTenure: 0)
            },
            set: { [weak self] newValue in
                self?.productsByCategory[category]?[catIndex] = newValue
                self?.markDirty()
            }
        )
    }
}
