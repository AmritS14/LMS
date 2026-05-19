import SwiftUI
import LMSCore
import LMSDesignSystem

struct OfficerApplicationQueueView: View {
    var body: some View {
        NavigationStack {
            List {
                // TODO: LoanService.fetchAssignedApplications
                ForEach(0..<5, id: \.self) { _ in
                    NavigationLink {
                        ApplicationReviewDetailView()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Application #—").font(.lmsHeadline)
                                Text("Borrower —").font(.lmsCaption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            StatusBadge("New", tone: .info)
                        }
                    }
                }
            }
            .navigationTitle("My Queue")
        }
    }
}

struct ApplicationReviewDetailView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.m) {
                SectionCard(title: "Borrower") {
                    LabeledContent("Name", value: "—")
                    LabeledContent("Credit Score", value: "—")
                }
                SectionCard(title: "Loan") {
                    LabeledContent("Type", value: "—")
                    LabeledContent("Amount", value: "—")
                    LabeledContent("Tenure", value: "—")
                }
                SectionCard(title: "Documents") {
                    Text("No documents").foregroundStyle(.secondary)
                }
                HStack {
                    PrimaryButton("Recommend") { /* TODO */ }
                    PrimaryButton("Request Docs") { /* TODO */ }
                }
            }
            .padding(Spacing.m)
        }
        .navigationTitle("Review")
    }
}
