import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appEnvironment) private var env

    @State private var viewModel = AuthViewModel()
    @State private var navigateToOTP = false
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()

    @State private var showSuccess = false
    @State private var errorMessage: String?

    @FocusState private var focusedField: Field?

    private enum Field: Hashable { case name, email, phone, password, confirm }

    // MARK: - Password validation
    private var hasLowercase: Bool { password.range(of: "[a-z]", options: .regularExpression) != nil }
    private var hasUppercase: Bool { password.range(of: "[A-Z]", options: .regularExpression) != nil }
    private var hasNumber: Bool { password.range(of: "[0-9]", options: .regularExpression) != nil }
    private var hasSpecial: Bool { password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil }

    private var isPasswordValid: Bool {
        hasLowercase && hasUppercase && hasNumber && hasSpecial && password.count >= 8
    }

    private var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isPasswordValid &&
        password == confirmPassword &&
        isAtLeast18
    }

    private var isAtLeast18: Bool {
        let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
        return age >= 18
    }

    var body: some View {
        Form {
            Section {
                TextField("Full Name", text: $fullName)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .name)
                    .onSubmit { focusedField = .email }

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focusedField, equals: .email)
                    .onSubmit { focusedField = .phone }

                TextField("Phone Number", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .focused($focusedField, equals: .phone)

                DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "en_IN"))
            } header: {
                Text("Personal Details")
            } footer: {
                Text("Important: Please ensure that your Full Name, Date of Birth, and Phone Number exactly match the details on your government-issued documents (Aadhaar Card and PAN Card). The same mobile number must be registered with your Aadhaar for proper KYC verification.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, Spacing.xs)
            }

            Section {
                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .password)
                    .onSubmit { focusedField = .confirm }

                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .confirm)
                    .onSubmit { focusedField = nil }
            } header: {
                Text("Password")
            } footer: {
                passwordRequirements
            }

            if !isAtLeast18 {
                Section {
                    Label("You must be at least 18 years old to register.", systemImage: "xmark.circle.fill")
                        .foregroundStyle(Color.lmsDanger)
                        .font(.footnote)
                }
            }

            if let errorMessage = errorMessage ?? viewModel.errorMessage ?? (password != confirmPassword && !password.isEmpty && !confirmPassword.isEmpty ? "Passwords do not match." : nil) {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(Color.lmsDanger)
                        .font(.footnote)
                }
            }

            Section {
                PrimaryButton("Create Account", isLoading: viewModel.isBusy, action: submit)
                    .disabled(viewModel.isBusy || !isFormValid)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToOTP) {
            OTPVerificationView(viewModel: viewModel)
        }
    }


    // MARK: - Password Requirements
    private var passwordRequirements: some View {
        VStack(alignment: .leading, spacing: Spacing.xs_s) {
            Text("Password must contain:")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                RequirementRow(text: "At least 8 characters", isMet: password.count >= 8)
                RequirementRow(text: "An uppercase letter", isMet: hasUppercase)
                RequirementRow(text: "A lowercase letter", isMet: hasLowercase)
                RequirementRow(text: "A number", isMet: hasNumber)
                RequirementRow(text: "A special character", isMet: hasSpecial)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private func submit() {
        guard isFormValid else {
            errorMessage = password != confirmPassword
                ? "Passwords do not match."
                : "Please fill in all fields correctly."
            return
        }
        guard let auth = env?.auth else {
            errorMessage = "App is not configured. Please try again."
            return
        }
        errorMessage = nil
        focusedField = nil
        // Set the identifier on the shared view model so OTPVerificationView can use it
        viewModel.identifier = email.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            let success = await viewModel.signUp(
                authService: auth,
                password: password,
                fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                dob: dateOfBirth
            )
            if success {
                // Navigate to OTP verification screen
                navigateToOTP = true
            } else {
                errorMessage = viewModel.errorMessage ?? "Registration failed. Please try again."
            }
        }
    }
}

// MARK: - Requirement Row
struct RequirementRow: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: Spacing.xs_s) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.footnote)
                .foregroundStyle(isMet ? AnyShapeStyle(Color.lmsSuccess) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
                .symbolEffectIfAvailable(value: isMet)

            Text(text)
                .font(.footnote)
                .foregroundStyle(isMet ? .primary : .secondary)
        }
        .animation(.easeInOut(duration: 0.2), value: isMet)
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
    NavigationStack { RegisterView() }
}
