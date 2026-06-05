import SwiftUI

struct RejectModalView: View {
    let app: ManagerApplication
    var onComplete: (String?) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason = "Documentation"
    @State private var remarks = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil

    private let reasons = [
        ("Credit Risk", "creditcard"),
        ("Income Risk", "banknote"),
        ("Documentation", "doc.text"),
        ("Other", "ellipsis")
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    SectionCard {
                        HStack(spacing: Spacing.sm) {
                            AvatarView(initials: app.borrowerInitials, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.borrowerName).font(.lmsHeadline)
                                Text("\(app.referenceCode) • \(app.amountText)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("SELECT PRIMARY REASON")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(reasons, id: \.0) { reason, icon in
                            reasonRow(reason, icon: icon)
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        HStack {
                            Text("REASONING & REMARKS")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Optional").font(.caption).foregroundStyle(.tertiary)
                        }
                        TextEditor(text: $remarks)
                            .frame(height: 100)
                            .scrollContentBackground(.hidden)
                            .padding(Spacing.s)
                            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.input, style: .continuous))
                            .overlay(alignment: .topLeading) {
                                if remarks.isEmpty {
                                    Text("Provide context for this rejection…")
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

                    Button(role: .destructive) {
                        Task {
                            isSubmitting = true
                            errorMessage = nil
                            do {
                                try await onComplete(rejectionSummary)
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
                            Text("Reject Application")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 28)
                        }
                    }
                    .disabled(isSubmitting)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: CornerRadius.button))
                    .controlSize(.large)
                    .tint(.lmsDanger)
                }
                .padding(Spacing.m)
            }
            .background(Color.lmsBackground)
            .navigationTitle("Reject Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
            }
        }
    }

    private var rejectionSummary: String {
        remarks.isEmpty ? selectedReason : "\(selectedReason): \(remarks)"
    }

    private func reasonRow(_ reason: String, icon: String) -> some View {
        let isSelected = selectedReason == reason
        return Button {
            selectedReason = reason
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon).foregroundStyle(.primary).frame(width: 24)
                Text(reason).foregroundStyle(.primary)
                Spacer()
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.lmsAccent : Color.lmsGray4)
            }
            .padding(Spacing.m)
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .stroke(isSelected ? Color.lmsAccent : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
