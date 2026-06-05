import SwiftUI
import UIKit
import PDFKit
import QuickLook

// MARK: - Preview Phase

private enum DocumentPreviewPhase {
    case loading
    case image(UIImage, URL)
    case pdf(Data, URL)
    case unsupported(URL)
    case empty
    case failed(String)
}

// MARK: - PDFKit Wrapper

private struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(data: data)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - QuickLook Wrapper

private struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
            url as NSURL
        }
    }
}

// MARK: - Sheet

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
    @State private var previewPhase: DocumentPreviewPhase = .loading
    @State private var showFullScreen = false
    @State private var tempFileURL: URL? = nil
    @State private var errorMessage: String? = nil
    @State private var isSaving = false

    init(document: LoanDocument, isReadOnly: Bool = false, onSave: @escaping () -> Void) {
        self.document = document
        self.isReadOnly = isReadOnly
        self.onSave = onSave
        _selectedStatus = State(initialValue: document.status)
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

                    documentPreviewSection

                    if !isReadOnly {
                        reviewOptionsSection

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
            .task(id: document.id) {
                previewPhase = .loading
                await loadPreview()

                if document.kind == .identityProof, let env {
                    isLoadingReport = true
                    kycReport = try? await env.aadhaarKYC.report(documentID: document.id)
                    isLoadingReport = false
                }
            }
            .onDisappear {
                cleanupTempFile()
            }
            .fullScreenCover(isPresented: $showFullScreen) {
                fullScreenViewer
            }
        }
    }

    // MARK: - Full-Screen Viewer

    @ViewBuilder
    private var fullScreenViewer: some View {
        switch previewPhase {
        case .image(_, let url), .pdf(_, let url):
            QuickLookPreview(url: url).ignoresSafeArea()
        default:
            EmptyView()
        }
    }

    // MARK: - Load Preview

    @MainActor
    private func loadPreview() async {
        // Resolve a URL to fetch from
        let signedURL: URL
        do {
            if let env {
                signedURL = try await env.documents.signedURL(documentID: document.id)
            } else if let fallback = document.remoteURL {
                signedURL = fallback
            } else {
                previewPhase = .empty
                return
            }
        } catch {
            if let fallback = document.remoteURL {
                signedURL = fallback
            } else {
                previewPhase = .failed(error.localizedDescription)
                return
            }
        }

        // Download raw bytes
        let data: Data
        do {
            let (bytes, _) = try await URLSession.shared.data(from: signedURL)
            data = bytes
        } catch {
            previewPhase = .failed("Download failed: \(error.localizedDescription)")
            return
        }

        // Write to a temp file so QuickLook can open it by URL
        let ext = (document.fileName as NSString).pathExtension
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext.isEmpty ? "bin" : ext)
        do {
            try data.write(to: tempURL)
        } catch {
            previewPhase = .failed("Could not prepare file: \(error.localizedDescription)")
            return
        }
        cleanupTempFile()
        tempFileURL = tempURL

        // Detect content type from bytes
        if let image = UIImage(data: data) {
            previewPhase = .image(image, tempURL)
        } else if data.starts(with: [0x25, 0x50, 0x44, 0x46]) { // %PDF magic bytes
            previewPhase = .pdf(data, tempURL)
        } else {
            previewPhase = .unsupported(signedURL)
        }
    }

    private func cleanupTempFile() {
        guard let url = tempFileURL else { return }
        try? FileManager.default.removeItem(at: url)
        tempFileURL = nil
    }

    // MARK: - Document Preview Section

    private var documentPreviewSection: some View {
        VStack(spacing: 16) {
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
                    previewContent
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

    @ViewBuilder
    private var previewContent: some View {
        switch previewPhase {
        case .loading:
            HStack(spacing: 10) {
                ProgressView().scaleEffect(0.8)
                Text("Loading document…")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)

        case .image(let uiImage, _):
            VStack(spacing: 12) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 360)
                    .cornerRadius(12)
                viewFullScreenButton
            }

        case .pdf(let data, _):
            VStack(spacing: 12) {
                PDFKitView(data: data)
                    .frame(maxHeight: 360)
                    .cornerRadius(12)
                viewFullScreenButton
            }

        case .unsupported(let url):
            VStack(spacing: 12) {
                Image(systemName: "doc.questionmark.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("Preview not available")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                Link(destination: url) {
                    HStack {
                        Image(systemName: "arrow.up.right.app.fill")
                        Text("Open Document")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color(red: 0.15, green: 0.4, blue: 0.95)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
            }

        case .empty:
            VStack(spacing: 8) {
                Image(systemName: "icloud.slash")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("Awaiting Upload")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                Text("The borrower has not uploaded this document yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 10)

        case .failed(let message):
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                Button {
                    Task {
                        previewPhase = .loading
                        await loadPreview()
                    }
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
        }
    }

    private var viewFullScreenButton: some View {
        Button {
            showFullScreen = true
        } label: {
            HStack {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                Text("View Full Screen")
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color(red: 0.15, green: 0.4, blue: 0.95)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .cornerRadius(10)
            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    // MARK: - Review Options

    private var reviewOptionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Review Action")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                optionButton(status: .verified, title: "Verify", icon: "checkmark.circle.fill", selectedColor: .green)
                optionButton(status: .pending, title: "Needs Review", icon: "questionmark.circle.fill", selectedColor: .orange)
                optionButton(status: .rejected, title: "Reject", icon: "xmark.circle.fill", selectedColor: .red)
            }

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

    // MARK: - Save

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
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }
}

// MARK: - Status Extensions

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
