import SwiftUI

struct ApproveModalView: View {
    let app: ManagerApplication
    var onComplete: (String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var remarks = "Excellent credit profile, approved for full amount."
    @State private var notifyBorrower = true

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Approve \(app.amountText) loan")
                            .font(.lmsTitle3)
                        Text("Reviewing \(app.referenceCode) for \(app.borrowerName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("Remarks").font(.subheadline.weight(.semibold))
                        TextEditor(text: $remarks)
                            .frame(height: 110)
                            .scrollContentBackground(.hidden)
                            .padding(Spacing.s)
                            .background(Color.lmsBackground, in: RoundedRectangle(cornerRadius: CornerRadius.input, style: .continuous))
                    }

                    Toggle(isOn: $notifyBorrower) {
                        Label("Notify Borrower", systemImage: "bell")
                    }
                    .tint(.lmsSuccess)
                    .padding(Spacing.m)
                    .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))

                    Button {
                        onComplete(remarks)
                        dismiss()
                    } label: {
                        Text("Confirm Approval")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 28)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: CornerRadius.button))
                    .controlSize(.large)
                    .tint(.lmsSuccess)
                }
                .padding(Spacing.m)
            }
            .background(Color.lmsBackground)
            .navigationTitle("Approve Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    Text("preview").sheet(isPresented: .constant(true)) {
        Text("ApproveModalView requires a ManagerApplication")
    }
}
