//
//  AddLoanProductSheet.swift
//  LMS
//
//  Created by Shailesh on 22/05/26.
//

import SwiftUI

struct AddLoanProductSheet: View {
    @Bindable var viewModel: LoanConfigViewModel
    let onDismiss: () -> Void

    @State private var name: String = ""
    @State private var selectedCategory: LoanCategory = .personal
    @State private var minAmount: Double = 50_000
    @State private var maxAmount: Double = 10_00_000
    @State private var interestRate: Double = 10.0
    @State private var maxTenure: Int = 12
    @State private var tenureUnit: TenureUnit = .months
    @State private var errorMessage: String? = nil

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AdminSpacing.sectionGap) {
                    
                    // Section 1: Category Selection Dropdown
                    VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                        SectionHeaderView(title: "Category", systemImage: "grid")
                        
                        Menu {
                            ForEach(LoanCategory.allCases) { category in
                                Button {
                                    selectedCategory = category
                                } label: {
                                    HStack {
                                        Text(category.rawValue)
                                        Spacer()
                                        Image(systemName: category.systemImage)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedCategory.systemImage)
                                    .foregroundColor(AdminColor.accent)
                                Text(selectedCategory.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                AdminColor.cardBackground,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }

                    // Section 2: Product Name
                    VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                        SectionHeaderView(title: "Product Name", systemImage: "tag")
                        
                        TextField("e.g. Standard Home Loan", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .padding(AdminSpacing.cardPadding)
                            .background(
                                AdminColor.cardBackground,
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                    }

                    // Section 3: Financial Limits
                    VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                        SectionHeaderView(title: "Configure Limits", systemImage: "indianrupeesign.circle")
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Minimum Amount")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    Text("₹")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    TextField("Min Amount", value: $minAmount, formatter: numberFormatter)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numberPad)
                                }
                            }
                            
                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Maximum Amount")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    Text("₹")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    TextField("Max Amount", value: $maxAmount, formatter: numberFormatter)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numberPad)
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
                    }

                    // Section 4: Interest Rate
                    VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                        SectionHeaderView(title: "Interest Rate", systemImage: "percent")
                        
                        VStack(spacing: Spacing.s) {
                            HStack {
                                Text("Rate")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(interestRate, specifier: "%.2f")%")
                                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                                    .foregroundStyle(AdminColor.accent)
                            }
                            Slider(value: $interestRate, in: 1...30, step: 0.25)
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
                    }

                    // Section 5: Tenure Constraints
                    VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                        SectionHeaderView(title: "Tenure Constraints", systemImage: "calendar.badge.clock")
                        
                        VStack(spacing: Spacing.s) {
                            HStack {
                                Text("Max Tenure")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Stepper("\(maxTenure) \(tenureUnit.rawValue.lowercased())", value: $maxTenure, in: 1...1000, step: 1)
                            }
                            
                            Divider()
                            
                            Picker("Tenure Unit", selection: $tenureUnit) {
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
                    }
                }
                .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
                .padding(.vertical, 24)
            }
            .background(AdminColor.background)
            .navigationTitle("New Loan Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .tint(AdminColor.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        handleCreateProduct()
                    }
                    .tint(AdminColor.accent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || maxAmount < minAmount || minAmount <= 0)
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

    private func handleCreateProduct() {
        do {
            let isDuplicate = viewModel.productsByCategory.values.flatMap { $0 }.contains { $0.name.lowercased() == name.lowercased() }
            guard !isDuplicate else {
                throw NSError(domain: "DuplicateError", code: 1, userInfo: [NSLocalizedDescriptionKey: "A loan product with this name already exists."])
            }

            let newProduct = LoanProduct(
                name: name,
                minAmount: minAmount,
                maxAmount: maxAmount,
                interestRate: interestRate,
                maxTenure: maxTenure,
                tenureUnit: tenureUnit
            )
            
            viewModel.productsByCategory[selectedCategory, default: []].append(newProduct)
            viewModel.markDirty()
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
