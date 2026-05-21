import SwiftUI

struct LOClarificationRequestView: View {
    let application: LoanApplication
    let documents: [LoanDocument]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDocIDs: Set<UUID> = []
    @State private var remarks = ""
    @State private var sent = false

    private var pendingDocs: [LoanDocument] {
        documents.filter { $0.status == .pending || $0.status == .rejected }
    }

    private var borrowerName: String {
        MockData.borrowerUser(for: application.borrowerID)?.fullName ?? "Borrower"
    }

    private var appIDShort: String { "#\(application.id.uuidString.prefix(8).uppercased())" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {

                    // Borrower context banner
                    HStack(spacing: Spacing.m) {
                        ZStack {
                            Circle()
                                .fill(Color.lmsNavyBlue.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Text(borrowerName.prefix(1))
                                .font(.lmsTitle2)
                                .foregroundStyle(Color.lmsNavyBlue)
                        }
                        VStack(alignment: .leading) {
                            Text("To: \(borrowerName)")
                                .font(.lmsHeadline)
                            Text("Re: \(appIDShort) — \(application.loanType.rawValue.capitalized) Loan")
                                .font(.lmsCaption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(Spacing.m)
                    .background(Color.lmsNavyBlue.opacity(0.06), in: RoundedRectangle(cornerRadius: CornerRadius.medium))

                    // Document checklist
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("Select Documents to Request")
                            .font(.lmsHeadline)

                        if pendingDocs.isEmpty {
                            Text("All documents are verified.")
                                .font(.lmsBody)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(pendingDocs) { doc in
                                let isSelected = selectedDocIDs.contains(doc.id)
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        if isSelected { selectedDocIDs.remove(doc.id) }
                                        else { selectedDocIDs.insert(doc.id) }
                                    }
                                } label: {
                                    HStack(spacing: Spacing.m) {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(isSelected ? Color.lmsPrimary : Color.secondary)
                                            .font(.title3)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(doc.kind.displayName)
                                                .font(.lmsSubheadline)
                                                .foregroundStyle(.primary)
                                            Text(doc.fileName)
                                                .font(.lmsCaption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()
                                        StatusBadge(doc.status.displayName, tone: doc.status == .rejected ? .danger : .warning)
                                    }
                                    .padding(Spacing.m)
                                    .background(
                                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                                            .strokeBorder(isSelected ? Color.lmsPrimary : Color.secondary.opacity(0.2))
                                            .background(
                                                RoundedRectangle(cornerRadius: CornerRadius.medium)
                                                    .fill(isSelected ? Color.lmsPrimary.opacity(0.06) : Color(.systemBackground))
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Custom remarks
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("Message to Borrower")
                            .font(.lmsHeadline)
                        TextEditor(text: $remarks)
                            .frame(minHeight: 110)
                            .padding(Spacing.s)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.small)
                                    .strokeBorder(Color.secondary.opacity(0.3))
                            )
                            .overlay(alignment: .topLeading) {
                                if remarks.isEmpty {
                                    Text("Explain what is needed and why…")
                                        .font(.lmsBody)
                                        .foregroundStyle(.tertiary)
                                        .padding(12)
                                        .allowsHitTesting(false)
                                }
                            }
                    }

                    Spacer(minLength: Spacing.xl)

                    PrimaryButton("Send Request to \(borrowerName)", isLoading: sent) {
                        sent = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            dismiss()
                        }
                    }
                    .disabled(selectedDocIDs.isEmpty && remarks.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(Spacing.m)
            }
            .navigationTitle("Request Clarification")
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
    LOClarificationRequestView(application: MockData.appJane, documents: MockData.janeDocuments)
}
