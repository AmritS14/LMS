import SwiftUI

struct PortfolioDashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    SectionCard(title: "Portfolio") {
                        LabeledContent("Total Disbursed", value: "—")
                        LabeledContent("Outstanding", value: "—")
                        LabeledContent("Active Loans", value: "—")
                    }
                    SectionCard(title: "Health") {
                        LabeledContent("Collection Efficiency", value: "—")
                        LabeledContent("NPA Ratio", value: "—")
                    }
                }
                .padding(Spacing.m)
            }
            .navigationTitle("Portfolio")
        }
    }
}
