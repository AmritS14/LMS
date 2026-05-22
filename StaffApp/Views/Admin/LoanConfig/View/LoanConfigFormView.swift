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
    
    @State private var showAddLoanSheet = false
    @State private var errorMessage: String? = nil
    @State private var selectedProduct: LoanProduct? = nil

    var body: some View {
        List {
            // Product sections grouped by category
            ForEach(viewModel.activeCategories) { category in
                // Category Header Row
                SectionHeaderView(
                    title: category.rawValue,
                    systemImage: category.systemImage
                )
                .listRowInsets(EdgeInsets(
                    top: AdminSpacing.headerTopInset,
                    leading: AdminSpacing.cardRowHorizontalInset,
                    bottom: AdminSpacing.headerBottomInset,
                    trailing: AdminSpacing.cardRowHorizontalInset
                ))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                // Category Products Rows
                if let products = viewModel.productsByCategory[category] {
                    ForEach(products) { product in
                        LoanProductRowView(
                            product: product,
                            action: {
                                selectedProduct = product
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(
                            top: AdminSpacing.cardRowVerticalInset,
                            leading: AdminSpacing.cardRowHorizontalInset,
                            bottom: AdminSpacing.cardRowVerticalInset,
                            trailing: AdminSpacing.cardRowHorizontalInset
                        ))
                    }
                    .onDelete { offsets in
                        viewModel.deleteLoans(category: category, at: offsets)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AdminColor.background)
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
            }
        }
        .sheet(isPresented: $showAddLoanSheet) {
            AddLoanProductSheet(viewModel: viewModel) {
                showAddLoanSheet = false
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
