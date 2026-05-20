//
//  LoanConfigFormView.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI

// MARK: - Loan Configuration Form View

/// The main form view for managing Loan Configurations (US-41).
/// Groups loan products by category into Form sections
/// with inline editing and a prominent Save button.
struct LoanConfigFormView: View {
    @Bindable var viewModel: LoanConfigViewModel
    
    @State private var showAddLoanAlert = false
    @State private var newLoanName = ""
    @State private var selectedCategoryForNewLoan: LoanCategory = .personal
    @State private var errorMessage: String? = nil
    @State private var selectedProduct: LoanProduct? = nil

    var body: some View {
        Form {
            // Product sections grouped by category
            ForEach(viewModel.activeCategories) { category in
                categorySection(for: category)
            }

            // Save button
            saveSection
        }
        .formStyle(.grouped)
        .sheet(item: $selectedProduct) { product in
            if let binding = viewModel.binding(for: product.id) {
                LoanProductEditorSheet(product: binding) {
                    selectedProduct = nil
                }
            }
        }
        .navigationTitle("Loan Configurations")
        .alert("Configuration Saved", isPresented: $viewModel.showSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("All loan product configurations have been saved successfully.")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newLoanName = ""
                    errorMessage = nil
                    showAddLoanAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New Loan Product", isPresented: $showAddLoanAlert) {
            TextField("Loan Name", text: $newLoanName)
            Picker("Category", selection: $selectedCategoryForNewLoan) {
                ForEach(LoanCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            Button("Cancel", role: .cancel) {}
            Button("Add") {
                do {
                    try viewModel.addLoanProduct(category: selectedCategoryForNewLoan, name: newLoanName)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            .disabled(newLoanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter a unique name for the new loan product.")
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Sections

    /// A section for a specific loan category containing its products.
    private func categorySection(for category: LoanCategory) -> some View {
        Section {
            if let products = viewModel.productsByCategory[category] {
                ForEach(products) { product in
                    LoanProductRowView(
                        product: product,
                        action: {
                            selectedProduct = product
                        }
                    )
                }
                .onDelete { offsets in
                    viewModel.deleteLoans(category: category, at: offsets)
                }
            }
        } header: {
            SectionHeaderView(
                title: category.rawValue,
                systemImage: category.systemImage
            )
        }
    }

    /// Prominent save button at the bottom of the form.
    private var saveSection: some View {
        Section {
            PrimaryButton("Save Configuration", isLoading: viewModel.isSaving) {
                Task {
                    await viewModel.saveConfiguration()
                }
            }
            .disabled(!viewModel.hasUnsavedChanges)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
}

#Preview {
    NavigationStack {
        LoanConfigFormView(viewModel: LoanConfigViewModel())
    }
}
