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
            VStack(spacing: Spacing.l) {
                Text("LMS Staff Portal").font(.lmsTitle)
                SectionCard {
                    TextField("Work Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .email)
                        .onSubmit { focusedField = .password }
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .focused($focusedField, equals: .password)
                        .onSubmit(submit)

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(Color.lmsDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton("Sign In", isLoading: isBusy, action: submit)
                        .disabled(!isSignInEnabled)
                }
                Spacer()
            }
            .padding(Spacing.m)
            .navigationTitle("Sign in")
        }
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

#Preview { StaffLoginView() }
