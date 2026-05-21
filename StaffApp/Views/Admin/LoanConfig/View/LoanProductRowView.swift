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
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
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

    /// Clean number formatter for editable amount fields (only numbers, no symbol inside text field).
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.maximumFractionDigits = 0
        return formatter
    }    ()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AdminSpacing.sectionGap) {
                    // Section: Loan Name
                    VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                        SectionHeaderView(title: "Loan Name", systemImage: "tag")
                        
                        VStack(spacing: Spacing.s) {
                            TextField("Name", text: $product.name)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(AdminSpacing.cardPadding)
                        .background(
                            AdminColor.cardBackground,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                    }
                    
                    // Section: Amounts
                    VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                        SectionHeaderView(title: "Amounts", systemImage: "indianrupeesign.circle")
                        
                        VStack(spacing: Spacing.s) {
                            HStack {
                                Text("Min Amount")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("₹")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    TextField("Min", value: $product.minAmount, formatter: numberFormatter)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numberPad)
                                        .frame(width: 120)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                            
                            Divider()

                            HStack {
                                Text("Max Amount")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("₹")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    TextField("Max", value: $product.maxAmount, formatter: numberFormatter)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numberPad)
                                        .frame(width: 120)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }
                        .padding(AdminSpacing.cardPadding)
                        .background(
                            AdminColor.cardBackground,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                    }

                    // Section: Interest Rate
                    VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                        SectionHeaderView(title: "Interest Rate", systemImage: "percent")
                        
                        VStack(spacing: Spacing.s) {
                            HStack {
                                Text("Rate")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(product.interestRate, specifier: "%.2f")%")
                                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                                    .foregroundStyle(AdminColor.accent)
                            }
                            Slider(value: $product.interestRate, in: 1...30, step: 0.25)
                                .tint(AdminColor.accent)
                        }
                        .padding(AdminSpacing.cardPadding)
                        .background(
                            AdminColor.cardBackground,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                    }

                    // Section: Tenure
                    VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                        SectionHeaderView(title: "Tenure", systemImage: "calendar.badge.clock")
                        
                        VStack(spacing: Spacing.s) {
                            HStack {
                                Text("Max Tenure")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Stepper("\(product.maxTenure) \(product.tenureUnit.rawValue.lowercased())", value: $product.maxTenure, in: 1...1000, step: 1)
                            }
                            
                            Divider()
                            
                            Picker("Tenure Unit", selection: $product.tenureUnit) {
                                ForEach(TenureUnit.allCases) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(AdminSpacing.cardPadding)
                        .background(
                            AdminColor.cardBackground,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
                .padding(.vertical, AdminSpacing.cardRowHorizontalInset)
            }
            .background(AdminColor.background)
            .navigationTitle("Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onSave()
                    }
                    .tint(AdminColor.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave()
                    }
                    .tint(AdminColor.accent)
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
