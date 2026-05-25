import SwiftUI
import UniformTypeIdentifiers

struct KYCView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    
    @State private var isUploading = false
    @State private var uploadMessage: String?
    @State private var uploadedDocuments: [DocumentKind] = []
    
    @State private var isPickerPresented = false
    @State private var documentKindToUpload: DocumentKind? = nil
    
    var body: some View {
        List {
            Section("Identity") {
                documentRow(kind: .identityProof, title: "ID Proof", icon: "person.text.rectangle", iconColor: .blue)
            }
            Section("Address") {
                documentRow(kind: .addressProof, title: "Address Proof", icon: "house", iconColor: .teal)
            }
            Section("Income") {
                documentRow(kind: .incomeProof, title: "Salary Slips", icon: "doc.text", iconColor: .orange)
                documentRow(kind: .bankStatement, title: "Bank Statement", icon: "building.columns", iconColor: .indigo)
            }
        }
        .navigationTitle("KYC")
        .disabled(isUploading)
        .task {
            await fetchDocuments()
        }
        .overlay {
            if isUploading {
                ProgressView("Uploading...")
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .overlay(alignment: .bottom) {
            if let msg = uploadMessage {
                Text(msg)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(msg.contains("Failed") ? Color.red : Color.green)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: uploadMessage)
        .fileImporter(
            isPresented: $isPickerPresented,
            allowedContentTypes: [UTType.pdf, UTType.image, UTType.text, UTType.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first, let kind = documentKindToUpload else { return }
                uploadPickedDocument(url: url, kind: kind)
            case .failure(let error):
                uploadMessage = "Selection failed: \(error.localizedDescription)"
                clearMessageAfterDelay()
            }
        }
    }
    
    @ViewBuilder
    private func documentRow(kind: DocumentKind, title: String, icon: String, iconColor: Color) -> some View {
        Button(action: {
            documentKindToUpload = kind
            isPickerPresented = true
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                
                Text(title)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                let isUploaded = uploadedDocuments.contains(kind)
                
                Group {
                    if #available(iOS 17.0, *) {
                        Image(systemName: isUploaded ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                            .font(.title2)
                            .symbolEffect(.bounce, value: isUploaded)
                    } else {
                        Image(systemName: isUploaded ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                            .font(.title2)
                    }
                }
                .foregroundStyle(isUploaded ? .green : .red)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func fetchDocuments() async {
        guard let env = env, let userID = session.currentUser?.id else { return }
        do {
            let docs = try await env.documents.list(ownerID: userID)
            uploadedDocuments = docs.map { $0.kind }
        } catch {
            print("Failed to fetch documents: \(error)")
        }
    }
    
    private func uploadPickedDocument(url: URL, kind: DocumentKind) {
        guard let env = env, let userID = session.currentUser?.id else { return }
        
        guard url.startAccessingSecurityScopedResource() else {
            uploadMessage = "Cannot access file."
            clearMessageAfterDelay()
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            let mimeType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
            
            isUploading = true
            uploadMessage = nil
            
            Task {
                do {
                    _ = try await env.documents.upload(data, fileName: fileName, mimeType: mimeType, kind: kind, ownerID: userID)
                    uploadMessage = "Uploaded \(kind.rawValue) successfully!"
                    await fetchDocuments()
                } catch {
                    uploadMessage = "Failed to upload."
                }
                isUploading = false
                clearMessageAfterDelay()
            }
        } catch {
            uploadMessage = "Failed to read file."
            clearMessageAfterDelay()
        }
    }
    
    private func clearMessageAfterDelay() {
        Task {
            try? await Task.sleep(for: .seconds(3))
            if !isUploading {
                uploadMessage = nil
            }
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
