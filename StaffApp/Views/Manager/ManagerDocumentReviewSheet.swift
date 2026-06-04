import SwiftUI

struct ManagerDocumentReviewSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.appEnvironment) private var env
    @Environment(ManagerStore.self) private var store
    
    let document: LoanDocument
    let isReadOnly: Bool
    let onSave: () -> Void

    @State private var selectedStatus: DocumentVerificationStatus
    @State private var reviewNotes: String
    @State private var rejectionReason: String
    @State private var kycReport: AadhaarVerificationReport? = nil
    @State private var isLoadingReport = false
    @State private var documentURL: URL? = nil
    @State private var isLoadingURL = false
    @State private var errorMessage: String? = nil
    @State private var isSaving = false

    private var isImage: Bool {
        let name = document.fileName.lowercased()
        return name.hasSuffix(".png") || name.hasSuffix(".jpg") || name.hasSuffix(".jpeg") || name.hasSuffix(".heic")
    }

    init(document: LoanDocument, isReadOnly: Bool = false, onSave: @escaping () -> Void) {
        self.document = document
        self.isReadOnly = isReadOnly
        self.onSave = onSave

        // Initialize state from existing document properties.
        _selectedStatus = State(initialValue: document.status)
        // Default to empty strings as we don't have existing notes/rejections in LoanDocument model directly
        _reviewNotes = State(initialValue: "")
        _rejectionReason = State(initialValue: "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMessage)
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Document Preview Card
                    documentPreviewSection

                    if !isReadOnly {
                        // Review Options Section
                        reviewOptionsSection

                        // Action Buttons
                        VStack(spacing: 12) {
                            saveButton
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Review Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                            .padding(8)
                            .background(Color(uiColor: .systemGray5), in: Circle())
                    }
                }
            }
            .task {
                guard let env else { return }
                isLoadingURL = true
                documentURL = try? await env.documents.signedURL(documentID: document.id)
                isLoadingURL = false
                
                if document.kind == .identityProof {
                    isLoadingReport = true
                    kycReport = try? await env.aadhaarKYC.report(documentID: document.id)
                    isLoadingReport = false
                }
            }
        }
    }

    private var documentPreviewSection: some View {
        VStack(spacing: 16) {
            // Attached document header
            HStack(spacing: 12) {
                Image(systemName: document.kind.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(selectedStatus.color)
                    .frame(width: 44, height: 44)
                    .background(selectedStatus.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(document.fileName)
                        .font(.system(size: 16, weight: .bold))
                    Text(document.kind.displayLabel)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                StatusBadge(
                    selectedStatus.displayLabel,
                    tone: selectedStatus.tone,
                    size: .small
                )
            }
            .padding(.horizontal, 4)

            // Verification block: UIDAI report card or image preview
            Group {
                if isLoadingReport {
                    HStack(spacing: 10) {
                        ProgressView().scaleEffect(0.8)
                        Text("Loading verification report…")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else if let report = kycReport {
                    AadhaarVerificationReportCard(report: report)
                } else {
                    VStack(spacing: 16) {
                        if isLoadingURL {
                            HStack(spacing: 10) {
                                ProgressView().scaleEffect(0.8)
                                Text("Loading document…")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            VStack(spacing: 16) {
                                // Inline Image Preview (if image)
                                if isImage, let url = documentURL {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(height: 200)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxHeight: 300)
                                                .cornerRadius(12)
                                        case .failure:
                                            VStack(spacing: 8) {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .font(.title)
                                                    .foregroundColor(.orange)
                                                Text("Failed to load image preview")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(height: 200)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(8)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                                } else {
                                    // Document Icon and Type label
                                    VStack(spacing: 12) {
                                        Image(systemName: isImage ? "photo.fill" : "doc.text.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.blue.opacity(0.8))
                                        
                                        Text(document.fileName)
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                    .padding(.vertical, 16)
                                }
                                
                                // Open Document Button
                                if let url = documentURL {
                                    Link(destination: url) {
                                        HStack {
                                            Image(systemName: "arrow.up.right.app.fill")
                                            Text(isImage ? "View Full Image" : "Open Document")
                                        }
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.blue, Color(red: 0.15, green: 0.4, blue: 0.95)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(10)
                                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 8)
                                } else {
                                    Text("Unable to generate access link")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .shadow(color: .black.opacity(0.02), radius: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }

    private var reviewOptionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Review Action")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                // Verify Option
                optionButton(
                    status: .verified,
                    title: "Verify",
                    icon: "checkmark.circle.fill",
                    selectedColor: .green
                )

                // Needs Review Option
                optionButton(
                    status: .pending,
                    title: "Needs Review",
                    icon: "questionmark.circle.fill",
                    selectedColor: .orange
                )

                // Reject Option
                optionButton(
                    status: .rejected,
                    title: "Reject",
                    icon: "xmark.circle.fill",
                    selectedColor: .red
                )
            }

            // Conditional TextFields
            if selectedStatus == .pending {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Review Notes")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)

                    TextField("Enter notes for the borrower or team...", text: $reviewNotes, axis: .vertical)
                        .lineLimit(3...5)
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                        )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if selectedStatus == .rejected {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rejection Reason")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)

                    TextField("Enter rejection reason for the borrower...", text: $rejectionReason, axis: .vertical)
                        .lineLimit(3...5)
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                        )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }

    private func optionButton(status: DocumentVerificationStatus, title: String, icon: String, selectedColor: Color) -> some View {
        let isSelected = selectedStatus == status

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedStatus = status
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(isSelected ? .white : selectedColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? selectedColor : selectedColor.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedColor.opacity(isSelected ? 0.0 : 0.25), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var saveButton: some View {
        Button {
            Task {
                isSaving = true
                errorMessage = nil
                do {
                    try await store.updateDocumentReview(
                        documentID: document.id,
                        status: selectedStatus,
                        reviewNotes: selectedStatus == .pending ? reviewNotes : nil,
                        rejectionReason: selectedStatus == .rejected ? rejectionReason : nil
                    )
                    onSave()
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                }
                isSaving = false
            }
        } label: {
            HStack {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text(document.status == .verified ? "Update Review" : "Save Review")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color(red: 0.15, green: 0.4, blue: 0.95)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }
}

// Helper extensions mapping status to visual badges
extension DocumentVerificationStatus {
    var color: Color {
        switch self {
        case .verified: return .green
        case .pending: return .orange
        case .rejected: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .verified: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }
    
    var tone: StatusBadge.Tone {
        switch self {
        case .verified: return .success
        case .pending: return .warning
        case .rejected: return .danger
        }
    }
    
    var displayLabel: String {
        switch self {
        case .verified: return "Verified"
        case .pending: return "Pending Review"
        case .rejected: return "Rejected"
        }
    }
}

extension DocumentKind {
    var iconName: String {
        switch self {
        case .identityProof: return "person.text.rectangle"
        case .addressProof: return "house.fill"
        case .incomeProof: return "doc.text.fill"
        case .bankStatement: return "list.bullet.rectangle"
        case .collateral: return "building.columns.fill"
        case .other: return "doc.fill"
        }
    }
    
    var displayLabel: String {
        switch self {
        case .identityProof: return "Identity Proof"
        case .addressProof: return "Address Proof"
        case .incomeProof: return "Income Proof"
        case .bankStatement: return "Bank Statement"
        case .collateral: return "Collateral"
        case .other: return "Other Document"
        }
    }
}
