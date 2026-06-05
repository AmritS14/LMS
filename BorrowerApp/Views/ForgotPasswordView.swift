import SwiftUI
import Supabase

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appEnvironment) private var env

    @State private var email = ""
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @FocusState private var emailFocused: Bool

    var body: some View {
        Form {
            Section {
                TextField("Registered email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.send)
                    .focused($emailFocused)
                    .onSubmit(sendLink)
            } header: {
                Text("Reset Password")
            } footer: {
                Text("Enter the email associated with your account. We'll send a link to reset your password.")
            }

            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(Color.lmsDanger)
                        .font(.footnote)
                }
            }

            Section {
                PrimaryButton("Send Reset Link", isLoading: isSending, action: sendLink)
                    .disabled(isSending)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { emailFocused = true }
        .alert("Link Sent", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("A password reset link has been sent to \(email). Please check your inbox.")
        }
    }

    private func sendLink() {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter your registered email."
            return
        }
        errorMessage = nil
        isSending = true
        emailFocused = false
        Task {
            do {
                // Use Supabase's built-in password reset — sends an email with a magic link
                try await SupabaseManager.shared.client.auth.resetPasswordForEmail(
                    trimmed,
                    redirectTo: URL(string: "lms://reset-password")
                )
                isSending = false
                showSuccess = true
            } catch {
                isSending = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack { ForgotPasswordView() }
}

