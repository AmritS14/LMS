import SwiftUI
import Supabase

struct UpdatePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    // MARK: - Password validation
    private var hasLowercase: Bool { password.range(of: "[a-z]", options: .regularExpression) != nil }
    private var hasUppercase: Bool { password.range(of: "[A-Z]", options: .regularExpression) != nil }
    private var hasNumber: Bool { password.range(of: "[0-9]", options: .regularExpression) != nil }
    private var hasSpecial: Bool { password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil }

    private var isPasswordValid: Bool {
        hasLowercase && hasUppercase && hasNumber && hasSpecial && password.count >= 8
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("New Password", text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("Update Password")
                } footer: {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        RequirementRow(text: "At least 8 characters", isMet: password.count >= 8)
                        RequirementRow(text: "One uppercase letter", isMet: hasUppercase)
                        RequirementRow(text: "One lowercase letter", isMet: hasLowercase)
                        RequirementRow(text: "One number", isMet: hasNumber)
                        RequirementRow(text: "One special character", isMet: hasSpecial)
                    }
                    .padding(.top, Spacing.xs)
                }
                
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(Color.lmsDanger)
                            .font(.footnote)
                    }
                }
                
                Section {
                    PrimaryButton("Update Password", isLoading: isSubmitting, action: updatePassword)
                        .disabled(isSubmitting || !isPasswordValid || password != confirmPassword)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("New Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Password Updated", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your password has been updated successfully. You can now sign in with your new password.")
            }
        }
    }
    
    private func updatePassword() {
        guard isPasswordValid, password == confirmPassword else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await SupabaseManager.shared.client.auth.update(user: UserAttributes(password: password))
                isSubmitting = false
                showSuccess = true
                try await SupabaseManager.shared.client.auth.signOut()
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
