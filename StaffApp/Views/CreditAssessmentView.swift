import SwiftUI

struct CreditAssessmentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    SectionCard(title: "Borrower Credit Summary") {
                        LabeledContent("Score", value: "—")
                        LabeledContent("Active Loans", value: "—")
                        LabeledContent("Defaults", value: "—")
                    }
                    SectionCard(title: "Risk Notes") {
                        Text("No analysis yet").foregroundStyle(.secondary)
                    }
                }
                .padding(Spacing.m)
            }
            .navigationTitle("Credit")
        }
    }
}
