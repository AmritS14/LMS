import SwiftUI

struct StaffLoginView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isBusy: Bool = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    private var isSignInEnabled: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !isBusy
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: App Branding
                    branding
                        .padding(.top, 48)
                        .padding(.bottom, 36)

                    // MARK: Login Form
                    VStack(spacing: 0) {
                        // Email field
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            TextField("Work Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.next)
                                .focused($focusedField, equals: .email)
                                .onSubmit { focusedField = .password }
                        }
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, 14)

                        Divider()
                            .padding(.leading, 52)

                        // Password field
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .submitLabel(.go)
                                .focused($focusedField, equals: .password)
                                .onSubmit(submit)
                        }
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, 14)
                    }
                    .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.horizontal, Spacing.m)

                    // MARK: Error Message
                    if let errorMessage {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.footnote)
                            Text(errorMessage)
                                .font(.footnote)
                        }
                        .foregroundStyle(Color.lmsDanger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.l)
                        .padding(.top, Spacing.sm)
                    }

                    // MARK: Sign In Button
                    Button(action: submit) {
                        ZStack {
                            Text("Sign In")
                                .font(.headline)
                                .opacity(isBusy ? 0 : 1)
                            if isBusy {
                                ProgressView().tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 28)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 10))
                    .controlSize(.large)
                    .disabled(!isSignInEnabled)
                    .padding(.horizontal, Spacing.m)
                    .padding(.top, 24)

                    // MARK: Forgot Password
                    Button {
                        // Placeholder for forgot password flow
                    } label: {
                        Text("Forgot Password?")
                            .font(.subheadline)
                    }
                    .padding(.top, Spacing.m)

                    Spacer(minLength: 60)

                    // MARK: Footer
                    VStack(spacing: 4) {
                        Text("Loan Management System")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text("v\(appVersion)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.bottom, Spacing.l)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.lmsBackground)
            .navigationTitle("Sign In")
            .toolbarTitleDisplayMode(.large)
        }
    }

    // MARK: Branding

    private var branding: some View {
        VStack(spacing: Spacing.m) {
            ZStack {
                Circle()
                    .fill(Color.lmsAccent.gradient)
                    .frame(width: 80, height: 80)
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text("LMS Staff Portal")
                    .font(.title2.weight(.bold))
                Text("Sign in to your account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func submit() {
        guard let auth = env?.auth, isSignInEnabled else { return }
        focusedField = nil
        isBusy = true
        errorMessage = nil
        Task {
            do {
                let user = try await auth.signIn(email: email, password: password)
                isBusy = false
                withAnimation(.easeInOut(duration: 0.4)) {
                    session.currentUser = user
                }
            } catch {
                errorMessage = error.localizedDescription
                isBusy = false
            }
        }
    }
}

#Preview { StaffLoginView().environment(SessionStore()) }
