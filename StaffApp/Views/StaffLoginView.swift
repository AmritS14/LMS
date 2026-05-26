import SwiftUI

struct StaffLoginView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var viewModel = AuthViewModel()
    @State private var password: String = ""
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    private var isSignInEnabled: Bool {
        !viewModel.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !viewModel.isBusy
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.l) {
                Text("LMS Staff Portal").font(.lmsTitle)
                SectionCard {
                    TextField("Work Email", text: $viewModel.identifier)
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

                    if let errorMessage = viewModel.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(Color.lmsDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton("Sign In", isLoading: viewModel.isBusy, action: submit)
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
        Task {
            if let user = await viewModel.signIn(authService: auth, password: password) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    session.currentUser = user
                }
            }
        }
    }
}

#Preview { StaffLoginView() }
