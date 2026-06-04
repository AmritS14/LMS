import SwiftUI

struct ForcePasswordChangeView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isBusy = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Update Your Password")
                .font(.title2).bold()
            
            Text("For your security, please update your temporary password before continuing.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                SecureField("New Password", text: $newPassword)
                    .textFieldStyle(.roundedBorder)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.vertical)
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
            
            Button("Update Password") {
                updatePassword()
            }
            .buttonStyle(.borderedProminent)
            .disabled(newPassword.isEmpty || confirmPassword.isEmpty || isBusy)
            
            if isBusy {
                ProgressView()
            }
        }
        .padding(32)
    }
    
    private func updatePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        guard let auth = env?.auth else { return }
        
        isBusy = true
        errorMessage = nil
        Task {
            do {
                let user = try await auth.updatePassword(password: newPassword)
                isBusy = false
                withAnimation {
                    session.currentUser = user
                }
            } catch {
                isBusy = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    ForcePasswordChangeView()
        .environment(SessionStore(currentUser: MockAuthService.seedBorrower))
        .environment(\.appEnvironment, AppEnvironment(auth: MockAuthService(), loans: MockLoanService(), documents: MockDocumentService(), notifications: MockNotificationService(), messaging: MockMessagingService(), keychain: MockKeychainService()))
}
