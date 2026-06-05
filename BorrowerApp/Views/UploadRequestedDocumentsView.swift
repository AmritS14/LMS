import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Lets a borrower upload documents an officer has requested for an
/// application that is in `.additionalInfoRequired`. On submit it uploads each
/// file, then calls `documentsUploaded` to move the application back into review.
struct UploadRequestedDocumentsView: View {
    let application: LoanApplication
    let requestNote: String?
    /// Called after a successful submission so the caller can refresh.
    var onComplete: () async -> Void

    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var uploadedKinds: Set<DocumentKind> = []
    @State private var uploadedDocumentIDs: [UUID] = []
    @State private var isUploadingDoc = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    @State private var activeDocumentKind: DocumentKind?
    @State private var showSourcePicker = false
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private var requestedDocumentKind: DocumentKind {
        guard let note = requestNote?.lowercased() else { return .other }
        
        // Scan for keyword combinations to identify requested document
        if note.contains("bank statement") || note.contains("bank") || note.contains("statement") || note.contains("passbook") {
            return .bankStatement
        }
        if note.contains("salary") || note.contains("slip") || note.contains("income") || note.contains("pay") || note.contains("payslip") {
            return .incomeProof
        }
        if note.contains("id") || note.contains("identity") || note.contains("pan") || note.contains("aadhaar") || note.contains("aadhar") || note.contains("passport") || note.contains("voter") || note.contains("license") || note.contains("card") {
            return .identityProof
        }
        if note.contains("address") || note.contains("utility") || note.contains("bill") || note.contains("resident") || note.contains("rent") || note.contains("lease") {
            return .addressProof
        }
        if note.contains("collateral") || note.contains("property") || note.contains("asset") || note.contains("house") || note.contains("vehicle") || note.contains("car") || note.contains("land") {
            return .collateral
        }
        
        return .other
    }

    private var requestedDocumentTitle: String {
        switch requestedDocumentKind {
        case .identityProof: return "ID Proof"
        case .addressProof: return "Address Proof"
        case .incomeProof: return "Salary Slip"
        case .bankStatement: return "Bank Statement"
        case .collateral: return "Collateral Document"
        case .other: return "Requested Document"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    header

                    if let requestNote, !requestNote.isEmpty {
                        requestNoteCard(requestNote)
                    }

                    documentRows

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.lmsDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.m)
                    }

                    submitButton
                }
                .padding(.vertical, Spacing.l)
            }
            .scrollIndicators(.hidden)
            .background(Color.lmsBackground.ignoresSafeArea())
            .navigationTitle("Upload Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
            }
            .disabled(isUploadingDoc || isSubmitting)
            .overlay {
                if isUploadingDoc || isSubmitting {
                    VStack(spacing: Spacing.s) {
                        ProgressView().progressViewStyle(.circular)
                        Text(isSubmitting ? "Submitting…" : "Uploading…").font(.subheadline)
                    }
                    .padding(Spacing.l)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                }
            }
            .confirmationDialog("Choose File Source", isPresented: $showSourcePicker, titleVisibility: .visible) {
                Button { showPhotoPicker = true } label: { Label("Photo Library", systemImage: "photo.on.rectangle") }
                Button { showFilePicker = true } label: { Label("Browse Files", systemImage: "folder") }
                Button("Cancel", role: .cancel) { activeDocumentKind = nil }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem, let kind = activeDocumentKind else { return }
                selectedPhotoItem = nil
                Task {
                    await handlePhotoPickerResult(item: newItem, kind: kind)
                    activeDocumentKind = nil
                }
            }
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf, .jpeg, .png], allowsMultipleSelection: false) { result in
                guard let kind = activeDocumentKind else { return }
                if case .success(let urls) = result, let url = urls.first {
                    Task {
                        await handleFileImporterResult(url: url, kind: kind)
                        activeDocumentKind = nil
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text("\(application.loanType.rawValue.capitalized) Loan")
                .font(.title3.weight(.semibold))
            Text("Your loan officer has requested your \(requestedDocumentTitle.lowercased()). Please upload it below to continue your application.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.m)
    }

    private func requestNoteCard(_ note: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "quote.bubble.fill")
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Officer's note")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(note)
                    .font(.subheadline)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .padding(.horizontal, Spacing.m)
    }

    private var documentRows: some View {
        VStack(spacing: 0) {
            switch requestedDocumentKind {
            case .identityProof:
                docRow(kind: .identityProof, title: "ID Proof", icon: "person.text.rectangle.fill", iconColor: .blue)
            case .addressProof:
                docRow(kind: .addressProof, title: "Address Proof", icon: "house.fill", iconColor: .teal)
            case .incomeProof:
                docRow(kind: .incomeProof, title: "Salary Slips", icon: "doc.text.fill", iconColor: .orange)
            case .bankStatement:
                docRow(kind: .bankStatement, title: "Bank Statement", icon: "building.columns.fill", iconColor: .indigo)
            case .collateral:
                docRow(kind: .collateral, title: "Collateral Document", icon: "shield.fill", iconColor: .green)
            case .other:
                docRow(kind: .other, title: "Requested Document", icon: "doc.fill", iconColor: .gray)
            }
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .padding(.horizontal, Spacing.m)
    }

    @ViewBuilder
    private func docRow(kind: DocumentKind, title: String, icon: String, iconColor: Color) -> some View {
        let isUploaded = uploadedKinds.contains(kind)
        Button {
            activeDocumentKind = kind
            showSourcePicker = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
                    .frame(width: 30, height: 30)
                    .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text(title).foregroundStyle(.primary)
                Spacer()
                if isUploaded {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.lmsSuccess)
                } else {
                    Text("Upload").font(.subheadline.weight(.medium)).foregroundStyle(.tint)
                }
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }

    private var submitButton: some View {
        VStack(spacing: Spacing.xs) {
            PrimaryButton("Submit Documents", isLoading: isSubmitting) {
                Task { await submit() }
            }
            .disabled(uploadedDocumentIDs.isEmpty)
            .padding(.horizontal, Spacing.m)

            if uploadedDocumentIDs.isEmpty {
                Text("Upload at least one document to submit.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(uploadedDocumentIDs.count) document\(uploadedDocumentIDs.count > 1 ? "s" : "") ready to submit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func submit() async {
        guard let env, !uploadedDocumentIDs.isEmpty else { return }
        isSubmitting = true
        errorMessage = nil
        do {
            try await env.loans.documentsUploaded(applicationID: application.id, documentIDs: uploadedDocumentIDs)
            await onComplete()
            isSubmitting = false
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
        }
    }

    private func handlePhotoPickerResult(item: PhotosPickerItem, kind: DocumentKind) async {
        guard let env, let userID = session.currentUser?.id else { return }
        isUploadingDoc = true
        errorMessage = nil
        do {
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                throw NSError(domain: "Upload", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not load selected photo"])
            }
            let isPNG = imageData.prefix(4) == Data([0x89, 0x50, 0x4E, 0x47])
            let mimeType = isPNG ? "image/png" : "image/jpeg"
            let ext = isPNG ? "png" : "jpg"
            let fileName = "\(kind.rawValue)_\(UUID().uuidString.prefix(8)).\(ext)"
            let doc = try await env.documents.upload(imageData, fileName: fileName, mimeType: mimeType, kind: kind, ownerID: userID)
            registerUpload(doc.id, kind: kind)
        } catch {
            errorMessage = error.localizedDescription
        }
        isUploadingDoc = false
    }

    private func handleFileImporterResult(url: URL, kind: DocumentKind) async {
        guard let env, let userID = session.currentUser?.id else { return }
        isUploadingDoc = true
        errorMessage = nil
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            let fileData = try Data(contentsOf: url)
            let ext = url.pathExtension.lowercased()
            let mimeType: String
            switch ext {
            case "pdf": mimeType = "application/pdf"
            case "png": mimeType = "image/png"
            case "jpg", "jpeg": mimeType = "image/jpeg"
            default: mimeType = "application/octet-stream"
            }
            let doc = try await env.documents.upload(fileData, fileName: url.lastPathComponent, mimeType: mimeType, kind: kind, ownerID: userID)
            registerUpload(doc.id, kind: kind)
        } catch {
            errorMessage = error.localizedDescription
        }
        isUploadingDoc = false
    }

    private func registerUpload(_ id: UUID, kind: DocumentKind) {
        if !uploadedDocumentIDs.contains(id) { uploadedDocumentIDs.append(id) }
        uploadedKinds.insert(kind)
    }
}
