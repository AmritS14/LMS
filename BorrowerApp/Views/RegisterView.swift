
import SwiftUI

struct RegisterView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    // MARK: Password Validation
    private var hasLowercase: Bool {
        password.range(of: ".*[a-z]+.*", options: .regularExpression) != nil
    }

    private var hasUppercase: Bool {
        password.range(of: ".*[A-Z]+.*", options: .regularExpression) != nil
    }

    private var hasNumber: Bool {
        password.range(of: ".*[0-9]+.*", options: .regularExpression) != nil
    }

    private var hasSpecial: Bool {
        password.range(of: ".*[^a-zA-Z0-9]+.*", options: .regularExpression) != nil
    }

    private var isPasswordValid: Bool {
        hasLowercase &&
        hasUppercase &&
        hasNumber &&
        hasSpecial &&
        password.count >= 8
    }

    private var isFormValid: Bool {

        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isPasswordValid &&
        password == confirmPassword
    }

    var body: some View {

        ZStack {

            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Custom Nav Bar
                HStack {

                    Button {
                        dismiss()
                    } label: {

                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(
                                color: .black.opacity(0.08),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                    }

                    Spacer()

                    Text("Register")
                        .font(.system(size: 18, weight: .bold))

                    Spacer()

                    Color.clear
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {

                    VStack(alignment: .leading, spacing: 0) {

                        // MARK: Section Header
                        Text("Personal Details")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)

                        // MARK: Form Card
                        VStack(spacing: 0) {

                            CustomFormField(
                                placeholder: "Full Name",
                                text: $fullName,
                                contentType: .name,
                                keyboard: .default,
                                isSecure: false,
                                hasDivider: true
                            )

                            CustomFormField(
                                placeholder: "Email",
                                text: $email,
                                contentType: .emailAddress,
                                keyboard: .emailAddress,
                                isSecure: false,
                                hasDivider: true
                            )

                            CustomFormField(
                                placeholder: "Phone Number",
                                text: $phone,
                                contentType: .telephoneNumber,
                                keyboard: .phonePad,
                                isSecure: false,
                                hasDivider: true
                            )

                            CustomFormField(
                                placeholder: "Password",
                                text: $password,
                                contentType: .newPassword,
                                keyboard: .default,
                                isSecure: true,
                                hasDivider: true
                            )

                            CustomFormField(
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                contentType: .newPassword,
                                keyboard: .default,
                                isSecure: true,
                                hasDivider: false
                            )
                        }
                        .background(Color(.systemBackground))
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14,
                                style: .continuous
                            )
                        )
                        .padding(.horizontal, 16)

                        // MARK: Password Requirements
                        VStack(alignment: .leading, spacing: 6) {

                            Text("Password must contain:")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 2)

                            HStack(spacing: 16) {

                                VStack(alignment: .leading, spacing: 6) {

                                    RequirementRow(
                                        text: "8+ characters",
                                        isMet: password.count >= 8
                                    )

                                    RequirementRow(
                                        text: "Uppercase letter",
                                        isMet: hasUppercase
                                    )

                                    RequirementRow(
                                        text: "Lowercase letter",
                                        isMet: hasLowercase
                                    )
                                }

                                VStack(alignment: .leading, spacing: 6) {

                                    RequirementRow(
                                        text: "Number",
                                        isMet: hasNumber
                                    )

                                    RequirementRow(
                                        text: "Special character",
                                        isMet: hasSpecial
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                        // MARK: Error Message
                        if let errorMessage {

                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                        }

                        // MARK: Create Account Button
                        Button {

                            guard isFormValid else {

                                if password != confirmPassword {

                                    errorMessage = "Passwords do not match."

                                } else {

                                    errorMessage = "Please fill in all fields correctly."
                                }

                                return
                            }

                            errorMessage = nil
                            isSubmitting = true

                            Task {

                                try? await Task.sleep(for: .milliseconds(800))

                                isSubmitting = false
                                showSuccess = true
                            }

                        } label: {

                            HStack {

                                if isSubmitting {

                                    ProgressView()
                                        .tint(.blue)

                                } else {

                                    Text("Create Account")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 120)
                            .padding(.vertical, 16)
                            .background(Color(.blue))
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 14,
                                    style: .continuous
                                )
                            )
                        }
                        .disabled(isSubmitting)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Account Created!", isPresented: $showSuccess) {

            Button("Sign In") {
                dismiss()
            }

        } message: {

            Text("Your account has been created. Please sign in with your credentials.")
        }
    }
}

// MARK: - Custom Form Field
struct CustomFormField: View {

    let placeholder: String
    @Binding var text: String

    let contentType: UITextContentType
    let keyboard: UIKeyboardType
    let isSecure: Bool
    let hasDivider: Bool

    var body: some View {

        VStack(spacing: 0) {

            Group {

                if isSecure {

                    SecureField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .textContentType(contentType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                } else {

                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .textContentType(contentType)
                        .textInputAutocapitalization(
                            contentType == .emailAddress
                            ? .never
                            : .words
                        )
                        .autocorrectionDisabled(
                            contentType == .emailAddress
                        )
                }
            }
            .font(.system(size: 16))
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            if hasDivider {

                Divider()
                    .padding(.leading, 20)
            }
        }
    }
}

// MARK: - Requirement Row
struct RequirementRow: View {

    let text: String
    let isMet: Bool

    var body: some View {

        HStack(spacing: 6) {

            Image(
                systemName: isMet
                ? "checkmark.circle.fill"
                : "circle"
            )
            .font(.system(size: 12))
            .foregroundStyle(
                isMet
                ? .green
                : .secondary
            )

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(
                    isMet
                    ? .primary
                    : .secondary
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isMet)
    }
}

// MARK: - Preview
#Preview {

    RegisterView()
}
