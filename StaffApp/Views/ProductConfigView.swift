import SwiftUI

struct ProductConfigView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Loan Products") {
                    ForEach(LoanType.allCases) { type in
                        NavigationLink(type.rawValue.capitalized) {
                            LoanProductDetailView(type: type)
                        }
                    }
                }
            }
            .navigationTitle("Products")
        }
    }
}

struct LoanProductDetailView: View {
    let type: LoanType

    var body: some View {
        Form {
            Section("Pricing") {
                LabeledContent("Base Rate", value: "—")
                LabeledContent("Processing Fee", value: "—")
            }
            Section("Eligibility") {
                LabeledContent("Min Income", value: "—")
                LabeledContent("Min Credit Score", value: "—")
            }
        }
        .navigationTitle(type.rawValue.capitalized)
    }
}
