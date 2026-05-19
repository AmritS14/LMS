import SwiftUI
import LMSCore
import LMSDesignSystem

struct RepaymentDashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    SectionCard(title: "Active Loan") {
                        // TODO: bind to LoanService
                        LabeledContent("Outstanding", value: "—")
                        LabeledContent("Next EMI", value: "—")
                        LabeledContent("Due Date", value: "—")
                    }
                    SectionCard(title: "Upcoming EMIs") {
                        Text("No upcoming EMIs").foregroundStyle(.secondary)
                    }
                    SectionCard(title: "Payment History") {
                        Text("No payments yet").foregroundStyle(.secondary)
                    }
                }
                .padding(Spacing.m)
            }
            .navigationTitle("Repayments")
        }
    }
}

#Preview { RepaymentDashboardView() }
