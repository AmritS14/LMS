
import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Custom nav bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)

                // MARK: Title
                Text("Reset Password")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 28)

                // MARK: Email field
                TextField("Enter registered email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                // MARK: Error message
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }

                // MARK: Send Reset Link button
                Button {
                    let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        errorMessage = "Please enter your registered email."
                        return
                    }
                    errorMessage = nil
                    isSending = true
                    Task {
                        try? await Task.sleep(for: .milliseconds(800))
                        isSending = false
                        showSuccess = true
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSending ? Color.blue.opacity(0.6) : Color.blue)
                            .frame(height: 50)

                        if isSending {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send Reset Link")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .disabled(isSending)
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .alert("Link Sent!", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("A password reset link has been sent to \(email). Please check your inbox.")
        }
    }
}

#Preview {
    ForgotPasswordView()
}
