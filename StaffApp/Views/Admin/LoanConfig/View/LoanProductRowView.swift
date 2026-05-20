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
                        
                        Text("\(product.maxTenure) months")
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
            .padding(.vertical, 8)
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

    /// Currency formatter for amount fields.
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter
    }    ()

    var body: some View {
        NavigationStack {
            Form {
                Section("Loan Name") {
                    TextField("Name", text: $product.name)
                }
                
                Section("Amounts") {
                    HStack {
                        Label("Min Amount", systemImage: "arrow.down.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("Min", value: $product.minAmount, formatter: currencyFormatter)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .frame(width: 150)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Label("Max Amount", systemImage: "arrow.up.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("Max", value: $product.maxAmount, formatter: currencyFormatter)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .frame(width: 150)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Interest Rate") {
                    HStack {
                        Label("Rate", systemImage: "percent")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(product.interestRate, specifier: "%.2f")%")
                            .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    Slider(value: $product.interestRate, in: 1...30, step: 0.25)
                        .tint(Color.accentColor)
                }

                Section("Tenure") {
                    HStack {
                        Label("Max Tenure", systemImage: "calendar.badge.clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Stepper("\(product.maxTenure) months", value: $product.maxTenure, in: 6...480, step: 6)
                    }
                }
            }
            .navigationTitle("Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onSave()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave()
                    }
                }
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
