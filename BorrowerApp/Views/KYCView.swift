import SwiftUI

struct KYCView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var isUploading = false
    @State private var uploadMessage: String?
    @State private var uploadDidFail = false
    @State private var uploadedDocuments: [DocumentKind] = []

    var body: some View {
        List {
            Section {
                documentRow(kind: .identityProof, title: "ID Proof", icon: "person.text.rectangle.fill", iconColor: .blue)
            } header: {
                Text("Identity")
            } footer: {
                Text("Government-issued photo ID, e.g., passport or driver's licence.")
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
    }

    @ViewBuilder
    private func documentRow(kind: DocumentKind, title: String, icon: String, iconColor: Color) -> some View {
        let isUploaded = uploadedDocuments.contains(kind)
        Button(action: { uploadMockDocument(kind: kind) }) {
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

    private func fetchDocuments() async {
        guard let env, let userID = session.currentUser?.id else { return }
        do {
            let docs = try await env.documents.list(ownerID: userID)
            uploadedDocuments = docs.map { $0.kind }
        } catch {
            // ignore; UI shows empty
        }
    }

    private func uploadMockDocument(kind: DocumentKind) {
        guard let env, let userID = session.currentUser?.id else { return }
        isUploading = true
        uploadMessage = nil
        Task {
            do {
                _ = try await env.documents.upload(
                    Data(),
                    fileName: "mock_\(kind.rawValue).pdf",
                    mimeType: "application/pdf",
                    kind: kind,
                    ownerID: userID
                )
                uploadDidFail = false
                uploadMessage = "Uploaded \(kind.rawValue.capitalized)"
                await fetchDocuments()
            } catch {
                uploadDidFail = true
                uploadMessage = "Upload failed. Please try again."
            }
            isUploading = false

            try? await Task.sleep(for: .seconds(3))
            if !isUploading { uploadMessage = nil }
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
