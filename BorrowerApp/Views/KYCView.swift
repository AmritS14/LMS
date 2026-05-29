import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct KYCView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var isUploading = false
    @State private var uploadMessage: String?
    @State private var uploadDidFail = false
    @State private var uploadedDocuments: [DocumentKind] = []

    // File picker state
    @State private var activeDocumentKind: DocumentKind?
    @State private var showSourcePicker = false
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    // Aadhaar KYC chooser
    @State private var showAadhaarChooser = false
    @State private var showAadhaarXMLView = false

    var body: some View {
        List {
            Section {
                aadhaarIdentityRow
            } header: {
                Text("Identity")
            } footer: {
                Text("Verify instantly using Aadhaar XML, or upload a photo for manual review.")
            }

            Section {
                documentRow(kind: .addressProof, title: "Address Proof", icon: "house.fill", iconColor: .teal)
            } header: {
                Text("Address")
            } footer: {
                Text("Utility bill, lease agreement, or bank statement showing your current address.")
            }

            Section {
                documentRow(kind: .incomeProof, title: "Salary Slips", icon: "doc.text.fill", iconColor: .orange)
                documentRow(kind: .bankStatement, title: "Bank Statement", icon: "building.columns.fill", iconColor: .indigo)
            } header: {
                Text("Income")
            } footer: {
                Text("Last three months' salary slips and bank statements.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("KYC Documents")
        .navigationBarTitleDisplayMode(.large)
        .disabled(isUploading)
        .task { await fetchDocuments() }
        .overlay {
            if isUploading {
                VStack(spacing: Spacing.s) {
                    ProgressView()
                    Text("Uploading…").font(.subheadline)
                }
                .padding(Spacing.l)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
        }
        .overlay(alignment: .bottom) {
            if let msg = uploadMessage {
                Label(msg, systemImage: uploadDidFail ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.sm)
                    .background(uploadDidFail ? Color.lmsDanger : Color.lmsSuccess, in: Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .padding(.bottom, Spacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: uploadMessage)
        .confirmationDialog("Upload ID Proof", isPresented: $showAadhaarChooser, titleVisibility: .visible) {
            Button("Aadhaar XML — Instant Verification") {
                showAadhaarXMLView = true
            }
            Button("Upload Photo (slower — manual review required)") {
                activeDocumentKind = .identityProof
                showSourcePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showAadhaarXMLView) {
            AadhaarKYCView()
                .onDisappear { Task { await fetchDocuments() } }
        }
        .confirmationDialog("Choose File Source", isPresented: $showSourcePicker, titleVisibility: .visible) {
            Button {
                showPhotoPicker = true
            } label: {
                Label("Photo Library", systemImage: "photo.on.rectangle")
            }
            Button {
                showFilePicker = true
            } label: {
                Label("Browse Files", systemImage: "folder")
            }
            Button("Cancel", role: .cancel) {
                activeDocumentKind = nil
            }
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
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf, .jpeg, .png],
            allowsMultipleSelection: false
        ) { result in
            guard let kind = activeDocumentKind else { return }
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        await handleFileImporterResult(url: url, kind: kind)
                        activeDocumentKind = nil
                    }
                }
            case .failure(let error):
                uploadDidFail = true
                uploadMessage = error.localizedDescription
                activeDocumentKind = nil
            }
        }
    }

    @ViewBuilder
    private var aadhaarIdentityRow: some View {
        let isUploaded = uploadedDocuments.contains(.identityProof)
        Button(action: { showAadhaarChooser = true }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.blue)
                    .frame(width: 30, height: 30)
                    .background(Color.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("ID Proof (Aadhaar)")
                        .foregroundStyle(.primary)
                    Text("XML · Photo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isUploaded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.lmsSuccess)
                        .symbolEffectIfAvailable(value: isUploaded)
                } else {
                    Text("Upload")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.tint)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func documentRow(kind: DocumentKind, title: String, icon: String, iconColor: Color) -> some View {
        let isUploaded = uploadedDocuments.contains(kind)
        Button(action: {
            activeDocumentKind = kind
            showSourcePicker = true
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
                    .frame(width: 30, height: 30)
                    .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                if isUploaded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.lmsSuccess)
                        .symbolEffectIfAvailable(value: isUploaded)
                } else {
                    Text("Upload")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.tint)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    private func fetchDocuments() async {
        guard let env, let userID = session.currentUser?.id else { return }
        do {
            let docs = try await env.documents.list(ownerID: userID)
            uploadedDocuments = docs.map { $0.kind }
        } catch {
            // ignore; UI shows empty
        }
    }

    // MARK: - Photo Picker Handler

    private func handlePhotoPickerResult(item: PhotosPickerItem, kind: DocumentKind) async {
        guard let env, let userID = session.currentUser?.id else { return }
        isUploading = true
        uploadMessage = nil

        do {
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                throw NSError(domain: "KYC", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not load selected photo"])
            }

            let mimeType: String
            let ext: String
            // Check first bytes for PNG magic number
            if imageData.prefix(4) == Data([0x89, 0x50, 0x4E, 0x47]) {
                mimeType = "image/png"
                ext = "png"
            } else {
                mimeType = "image/jpeg"
                ext = "jpg"
            }

            let fileName = "\(kind.rawValue)_\(UUID().uuidString.prefix(8)).\(ext)"

            _ = try await env.documents.upload(
                imageData,
                fileName: fileName,
                mimeType: mimeType,
                kind: kind,
                ownerID: userID
            )
            uploadDidFail = false
            uploadMessage = "\(displayName(for: kind)) uploaded"
            await fetchDocuments()
        } catch {
            uploadDidFail = true
            uploadMessage = error.localizedDescription
        }
        isUploading = false

        try? await Task.sleep(for: .seconds(3))
        if !isUploading { uploadMessage = nil }
    }

    // MARK: - File Importer Handler

    private func handleFileImporterResult(url: URL, kind: DocumentKind) async {
        guard let env, let userID = session.currentUser?.id else { return }
        isUploading = true
        uploadMessage = nil

        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        do {
            let fileData = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            let ext = url.pathExtension.lowercased()

            let mimeType: String
            switch ext {
            case "pdf": mimeType = "application/pdf"
            case "png": mimeType = "image/png"
            case "jpg", "jpeg": mimeType = "image/jpeg"
            default: mimeType = "application/octet-stream"
            }

            _ = try await env.documents.upload(
                fileData,
                fileName: fileName,
                mimeType: mimeType,
                kind: kind,
                ownerID: userID
            )
            uploadDidFail = false
            uploadMessage = "\(displayName(for: kind)) uploaded"
            await fetchDocuments()
        } catch {
            uploadDidFail = true
            uploadMessage = error.localizedDescription
        }
        isUploading = false

        try? await Task.sleep(for: .seconds(3))
        if !isUploading { uploadMessage = nil }
    }

    private func displayName(for kind: DocumentKind) -> String {
        switch kind {
        case .identityProof: return "ID Proof"
        case .addressProof: return "Address Proof"
        case .incomeProof: return "Salary Slip"
        case .bankStatement: return "Bank Statement"
        case .collateral: return "Collateral"
        case .other: return "Document"
        }
    }
}

private extension View {
    @ViewBuilder
    func symbolEffectIfAvailable<V: Equatable>(value: V) -> some View {
        if #available(iOS 17.0, *) {
            self.symbolEffect(.bounce, value: value)
        } else {
            self
        }
    }
}

#Preview {
    NavigationStack {
        KYCView()
            .environment(SessionStore(
                currentUser: MockAuthService.seedBorrower,
                borrowerProfile: MockAuthService.seedBorrowerProfile
            ))
            .environment(\.appEnvironment, AppEnvironment(
                auth: MockAuthService(),
                loans: MockLoanService(),
                documents: MockDocumentService(),
                notifications: MockNotificationService(),
                messaging: MockMessagingService(),
                keychain: MockKeychainService()
            ))
    }
}
