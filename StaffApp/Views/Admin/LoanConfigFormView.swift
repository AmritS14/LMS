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
    @Environment(\.appEnvironment) private var env

    @State private var showAddLoanSheet = false
    @State private var errorMessage: String? = nil
    @State private var selectedProduct: AdminLoanProduct? = nil

    var body: some View {
        List {
            // Product sections grouped by category
            ForEach(viewModel.activeCategories) { category in
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
                    Text(category.rawValue).font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(item: $selectedProduct) { product in
            if let binding = viewModel.binding(for: product.id) {
                LoanProductEditorSheet(
                    product: binding,
                    onSave: {
                        selectedProduct = nil
                    },
                    onCancel: {
                        selectedProduct = nil
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showAddLoanSheet) {
            AddLoanProductSheet(viewModel: viewModel) {
                showAddLoanSheet = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .navigationTitle("Loan Configurations")
        .task {
            viewModel.configure(environment: env)
            await viewModel.load()
        }
        .alert("Configuration Saved", isPresented: $viewModel.showSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("All loan product configurations have been saved successfully.")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    errorMessage = nil
                    showAddLoanSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
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
}

#Preview {
    NavigationStack {
        LoanConfigFormView(viewModel: LoanConfigViewModel())
    }
}
