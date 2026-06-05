import SwiftUI

struct SendBackModalView: View {
    let app: ManagerApplication
    var onComplete: (String?) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReasons: Set<String> = []
    @State private var remarks = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil

    private let reasons = [
        "Missing Documents",
        "Incorrect Data",
        "Verification Required",
        "Clarification Needed"
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    Text("Select the reasons for returning \(app.referenceCode) to \(app.officerName).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    SectionCard(title: "Reasons") {
                        ForEach(reasons, id: \.self) { reason in
                            reasonRow(reason)
                            if reason != reasons.last { Divider() }
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("ASSIGN TO LOAN OFFICER")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        HStack {
                            Label(app.officerName, systemImage: "person.crop.circle")
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(Spacing.m)
                        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("ADDITIONAL REMARKS")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextEditor(text: $remarks)
                            .frame(height: 100)
                            .scrollContentBackground(.hidden)
                            .padding(Spacing.s)
                            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.input, style: .continuous))
                            .overlay(alignment: .topLeading) {
                                if remarks.isEmpty {
                                    Text("Specify the changes required…")
                                        .font(.subheadline)
                                        .foregroundStyle(.tertiary)
                                        .padding(Spacing.m)
                                        .allowsHitTesting(false)
                                }
                            }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task {
                            isSubmitting = true
                            errorMessage = nil
                            do {
                                try await onComplete(sendBackSummary)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSubmitting = false
                        }
                    } label: {
                        if isSubmitting {
                            ProgressView().progressViewStyle(.circular).tint(.white)
                        } else {
                            Label("Send Back to Officer", systemImage: "paperplane.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 28)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: CornerRadius.button))
                    .controlSize(.large)
                    .tint(.lmsWarning)
                    .disabled(selectedReasons.isEmpty || isSubmitting)
                }
                .padding(Spacing.m)
            }
            .background(Color.lmsBackground)
            .navigationTitle("Send Back")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) { Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.primary).padding(8).background(Color(uiColor: .systemGray5), in: Circle()) }
                }
            }
        }
    }

    private var sendBackSummary: String {
        let joined = selectedReasons.sorted().joined(separator: ", ")
        return remarks.isEmpty ? joined : "\(joined) — \(remarks)"
    }

    private func reasonRow(_ reason: String) -> some View {
        let isOn = selectedReasons.contains(reason)
        return Button {
            if isOn { selectedReasons.remove(reason) } else { selectedReasons.insert(reason) }
        } label: {
            HStack {
                Text(reason).font(.subheadline).foregroundStyle(.primary)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isOn ? Color.lmsAccent : Color.lmsGray4)
            }
            .padding(.vertical, Spacing.s)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
