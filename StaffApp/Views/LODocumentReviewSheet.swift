import SwiftUI

struct LODocumentReviewSheet: View {
    let document: LoanDocument
    @Environment(\.dismiss) private var dismiss

    @State private var verificationStatus: DocumentVerificationStatus
    @State private var resolutionNotes = ""
    @State private var saved = false

    init(document: LoanDocument) {
        self.document = document
        _verificationStatus = State(initialValue: document.status)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.m) {

                // Mock Document Preview
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .fill(Color.secondary.opacity(0.08))

                    VStack(spacing: Spacing.m) {
                        Image(systemName: documentIcon)
                            .font(.system(size: 56))
                            .foregroundStyle(statusColor)
                        Text(document.fileName)
                            .font(.lmsHeadline)
                            .multilineTextAlignment(.center)
                        Text(document.kind.displayName)
                            .font(.lmsCaption)
                            .foregroundStyle(.secondary)
                        StatusBadge(document.status.displayName, tone: statusTone(document.status))
                    }
                    .padding()
                }
                .frame(maxHeight: 220)
                .padding(.horizontal, Spacing.m)

                // Action Picker
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("Update Verification Status")
                        .font(.lmsHeadline)
                        .padding(.horizontal, Spacing.m)

                    HStack(spacing: Spacing.s) {
                        StatusPillButton(label: "Verified", color: .lmsSuccess, isSelected: verificationStatus == .verified) {
                            withAnimation { verificationStatus = .verified }
                        }
                        StatusPillButton(label: "Needs Review", color: .lmsWarning, isSelected: verificationStatus == .pending) {
                            withAnimation { verificationStatus = .pending }
                        }
                        StatusPillButton(label: "Rejected / Flagged", color: .lmsDanger, isSelected: verificationStatus == .rejected) {
                            withAnimation { verificationStatus = .rejected }
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                }

                // Resolution notes (shown when pending or rejected)
                if verificationStatus != .verified {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text(verificationStatus == .rejected ? "Rejection Reason" : "Review Notes")
                            .font(.lmsHeadline)
                        TextEditor(text: $resolutionNotes)
                            .frame(minHeight: 100)
                            .padding(Spacing.s)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.small)
                                    .strokeBorder(Color.secondary.opacity(0.3))
                            )
                            .overlay(alignment: .topLeading) {
                                if resolutionNotes.isEmpty {
                                    Text("Describe the issue clearly for the borrower…")
                                        .font(.lmsBody)
                                        .foregroundStyle(.tertiary)
                                        .padding(12)
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                    .padding(.horizontal, Spacing.m)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                PrimaryButton("Save Review", isLoading: saved) {
                    saved = true
                    Task {
                        try? await MockData.sharedDocumentService.updateStatus(documentID: document.id, status: verificationStatus)
                        try? await Task.sleep(for: .milliseconds(500))
                        dismiss()
                    }
                }
                .padding(Spacing.m)
            }
            .padding(.top, Spacing.m)
            .navigationTitle("Review Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var documentIcon: String {
        switch document.kind {
        case .identityProof, .addressProof: return "creditcard.and.123"
        case .incomeProof, .bankStatement: return "banknote"
        case .collateral: return "house.fill"
        default: return "doc.fill"
        }
    }

    private var statusColor: Color {
        switch verificationStatus {
        case .verified: return .lmsSuccess
        case .rejected: return .lmsDanger
        case .pending: return .lmsWarning
        }
    }

    private func statusTone(_ status: DocumentVerificationStatus) -> StatusBadge.Tone {
        switch status {
        case .verified: return .success
        case .rejected: return .danger
        case .pending: return .warning
        }
    }
}

struct StatusPillButton: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.lmsCaption.weight(isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.s)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected
                        ? AnyShapeStyle(color)
                        : AnyShapeStyle(color.opacity(0.12))
                    , in: Capsule()
                )
                .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: isSelected ? 0 : 1))
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    LODocumentReviewSheet(document: MockData.janeDocuments[0])
}
