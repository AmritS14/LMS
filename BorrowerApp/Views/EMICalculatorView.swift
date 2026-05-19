import SwiftUI
import LMSCore
import LMSDesignSystem

struct EMICalculatorView: View {
    @State private var principal: Decimal = 500_000
    @State private var rate: Double = 9.5
    @State private var tenureMonths: Int = 60

    var body: some View {
        Form {
            Section("Inputs") {
                TextField("Principal", value: $principal, format: .number).keyboardType(.decimalPad)
                Stepper("Rate: \(rate, format: .number.precision(.fractionLength(2)))%", value: $rate, in: 1...30, step: 0.25)
                Stepper("Tenure: \(tenureMonths) months", value: $tenureMonths, in: 6...360, step: 6)
            }
            Section("Result") {
                // TODO: live calculation from EMICalculator
                LabeledContent("Monthly EMI", value: "—")
                LabeledContent("Total Interest", value: "—")
                LabeledContent("Total Payable", value: "—")
            }
        }
        .navigationTitle("EMI Calculator")
    }
}

#Preview { NavigationStack { EMICalculatorView() } }
