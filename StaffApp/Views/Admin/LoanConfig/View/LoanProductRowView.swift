//
//  LoanProductRowView.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI

// MARK: - Loan Product Row (Tap Target)

/// A reusable row displaying a summary of a loan product's name,
/// interest rate, and max tenure. Tapping this row will open a sheet to edit its parameters.
struct LoanProductRowView: View {
    let product: LoanProduct
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    // Title
                    Text(product.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    // Rate and Tenure summary
                    HStack(spacing: 16) {
                        Text("\(product.interestRate, specifier: "%.2f")%")
                            .foregroundStyle(.secondary)
                        
                        Text("\(product.maxTenure) \(product.tenureUnit.rawValue.lowercased())")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }

                Spacer()

                // Trailing chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(AdminSpacing.cardPadding)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Loan Product Editor Sheet

/// A sheet to edit a single loan product's parameters inline.
struct LoanProductEditorSheet: View {
    @Binding var product: LoanProduct
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var draftProduct: LoanProduct
    @State private var showUnsavedChangesAlert = false

    init(product: Binding<LoanProduct>, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self._product = product
        self.onSave = onSave
        self.onCancel = onCancel
        self._draftProduct = State(initialValue: product.wrappedValue)
    }

    private var hasChanges: Bool {
        draftProduct != product
    }

    /// Clean number formatter for editable amount fields (only numbers, no symbol inside text field).
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Form {
                // Section: Loan Name
                Section {
                    TextField("Name", text: $draftProduct.name)
                } header: {
                    Text("Loan Name")
                }
                
                // Section: Amounts
                Section {
                    HStack {
                        Text("Min Amount")
                        Spacer()
                        TextField("Min", value: $draftProduct.minAmount, formatter: numberFormatter)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Max Amount")
                        Spacer()
                        TextField("Max", value: $draftProduct.maxAmount, formatter: numberFormatter)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Amounts (₹)")
                }

                // Section: Interest Rate
                Section {
                    HStack {
                        Text("Rate")
                        Spacer()
                        Text("\(draftProduct.interestRate, specifier: "%.2f")%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $draftProduct.interestRate, in: 1...30, step: 0.25)
                } header: {
                    Text("Interest Rate")
                }

                // Section: Tenure
                Section {
                    Stepper(value: $draftProduct.maxTenure, in: 1...1000, step: 1) {
                        HStack {
                            Text("Max Tenure")
                            Spacer()
                            Text("\(draftProduct.maxTenure)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Picker("Tenure Unit", selection: $draftProduct.tenureUnit) {
                          ForEach(TenureUnit.allCases) { unit in
                              Text(unit.rawValue).tag(unit)
                          }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Tenure")
                }
            }
            .navigationTitle("Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges {
                            showUnsavedChangesAlert = true
                        } else {
                            onCancel()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        product = draftProduct
                        onSave()
                    }
                    .fontWeight(.bold)
                }
            }
            .alert("Unsaved Changes", isPresented: $showUnsavedChangesAlert) {
                Button("Stay", role: .cancel) {}
                Button("Discard Changes", role: .destructive) {
                    onCancel()
                }
                Button("Save & Exit") {
                    product = draftProduct
                    onSave()
                }
            } message: {
                Text("You have unsaved changes. Do you want to leave without saving?")
            }
        }
    }
}

#Preview {
    Form {
        LoanProductRowView(
            product: LoanProduct.sampleProducts[.personal]![0],
            action: {}
        )
    }
}
