import SwiftUI

struct NewLoanApplicationView: View {
    @State private var loanType: LoanType = .personal
    @State private var amount: Decimal = 100_000
    @State private var tenureMonths: Int = 24

    var body: some View {
        NavigationStack {
            Form {
                Section("Loan") {
                    Picker("Type", selection: $loanType) {
                        ForEach(LoanType.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    TextField("Amount", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                    Stepper("Tenure: \(tenureMonths) months", value: $tenureMonths, in: 6...360, step: 6)
                }
                Section {
                    PrimaryButton("Submit Application") {
                        // TODO: LoanService.createApplication
                    }
                }
            }
            .navigationTitle("Apply")
        }
    }
}

#Preview { NewLoanApplicationView() }
