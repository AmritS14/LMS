import SwiftUI

struct EMICalculatorView: View {
    @State private var principal: Decimal = 500_000
    @State private var rate: Double = 9.5
    @State private var tenureMonths: Int = 60

    var body: some View {
        Form {
            Section("Loan Details") {
                LabeledContent("Principal") {
                    TextField("Amount", value: $principal, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                Stepper(
                    value: $rate,
                    in: 1...30,
                    step: 0.25
                ) {
                    LabeledContent("Interest Rate", value: String(format: "%.2f%%", rate))
                }
                Stepper(
                    value: $tenureMonths,
                    in: 6...360,
                    step: 6
                ) {
                    LabeledContent("Tenure", value: "\(tenureMonths) months")
                }
            }

            Section("Result") {
                let result = EMICalculator.calculate(
                    principal: principal,
                    annualInterestRate: rate,
                    tenureMonths: tenureMonths,
                    startDate: .now
                )
                LabeledContent("Monthly EMI", value: Formatting.currency(result.monthlyInstallment))
                LabeledContent("Total Interest", value: Formatting.currency(result.totalInterest))
                LabeledContent("Total Payable", value: Formatting.currency(result.totalPayable))
            }
        }
        .navigationTitle("EMI Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview { NavigationStack { EMICalculatorView() } }
