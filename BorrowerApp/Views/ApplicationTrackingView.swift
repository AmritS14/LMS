import SwiftUI

struct ApplicationTrackingView: View {
    var body: some View {
        List {
            // TODO: bind to LoanService.fetchApplications
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack {
                        Text("Personal Loan").font(.lmsHeadline)
                        Spacer()
                        StatusBadge("Under Review", tone: .info)
                    }
                    Text("Submitted on -").font(.lmsCaption).foregroundStyle(.secondary)
                }
                .padding(.vertical, Spacing.xs)
            }
        }
        .navigationTitle("My Applications")
    }
}

#Preview { NavigationStack { ApplicationTrackingView() } }
