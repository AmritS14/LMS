import SwiftUI

struct KYCView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    
    @State private var isUploading = false
    @State private var uploadMessage: String?
    @State private var uploadedDocuments: [DocumentKind] = []
    
    var body: some View {
        List {
            Section("Identity") {
                documentRow(kind: .identityProof, title: "ID Proof", icon: "person.text.rectangle")
            }
            Section("Address") {
                documentRow(kind: .addressProof, title: "Address Proof", icon: "house")
            }
            Section("Income") {
                documentRow(kind: .incomeProof, title: "Salary Slips", icon: "doc.text")
                documentRow(kind: .bankStatement, title: "Bank Statement", icon: "building.columns")
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
    }
    
    @ViewBuilder
    private func documentRow(kind: DocumentKind, title: String, icon: String) -> some View {
        Button(action: { uploadMockDocument(kind: kind) }) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(.primary)
                Spacer()
                
                if uploadedDocuments.contains(kind) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Submitted")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.doc")
                        Text("Upload")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                }
            }
        }
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
    
    private func uploadMockDocument(kind: DocumentKind) {
        guard let env = env, let userID = session.currentUser?.id else { return }
        isUploading = true
        uploadMessage = nil
        Task {
            do {
                _ = try await env.documents.upload(Data(), fileName: "mock_\(kind.rawValue).pdf", mimeType: "application/pdf", kind: kind, ownerID: userID)
                uploadMessage = "Uploaded \(kind.rawValue) successfully!"
                await fetchDocuments()
            } catch {
                uploadMessage = "Failed to upload."
            }
            isUploading = false
            
            // Auto dismiss toast after 3 seconds
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
            .environment(SessionStore())
    }
}
