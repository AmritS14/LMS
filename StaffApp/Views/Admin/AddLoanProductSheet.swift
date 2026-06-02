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
    @State private var isSaving: Bool = false

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Category Selection Dropdown
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(LoanCategory.allCases) { category in
                            Text(category.rawValue)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Section 2: Product Name
                Section {
                    TextField("Product Name (e.g. Standard Home Loan)", text: $name)
                } header: {
                    Text("Product Name")
                }

                // Section 3: Financial Limits
                Section {
                    HStack {
                        Text("Minimum Amount")
                        Spacer()
                        TextField("Min", value: $minAmount, formatter: numberFormatter)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Maximum Amount")
                        Spacer()
                        TextField("Max", value: $maxAmount, formatter: numberFormatter)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Configure Limits (₹)")
                }

                // Section 4: Interest Rate
                Section {
                    HStack {
                        Text("Rate")
                        Spacer()
                        Text("\(interestRate, specifier: "%.2f")%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $interestRate, in: 1...30, step: 0.25)
                } header: {
                    Text("Interest Rate")
                }

                // Section 5: Tenure Constraints
                Section {
                    Stepper(value: $maxTenure, in: 1...1000, step: 1) {
                        HStack {
                            Text("Max Tenure")
                            Spacer()
                            Text("\(maxTenure)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Picker("Tenure Unit", selection: $tenureUnit) {
                        ForEach(TenureUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Tenure Constraints")
                }
            }
            .navigationTitle("New Loan Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        handleCreateProduct()
                    }
                    .fontWeight(.bold)
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || maxAmount < minAmount || minAmount <= 0)
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
        let isDuplicate = viewModel.productsByCategory.values.flatMap { $0 }.contains { $0.name.lowercased() == name.lowercased() }
        guard !isDuplicate else {
            errorMessage = "A loan product with this name already exists."
            return
        }

        let newProduct = AdminLoanProduct(
            name: name,
            minAmount: minAmount,
            maxAmount: maxAmount,
            interestRate: interestRate,
            maxTenure: maxTenure,
            tenureUnit: tenureUnit
        )

        isSaving = true
        Task {
            do {
                try await viewModel.addProduct(newProduct, category: selectedCategory)
                onDismiss()
            } catch {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
