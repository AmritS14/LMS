import SwiftUI

struct LoginView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    
    @State private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.l) {
                Text("Welcome to LMS").font(.lmsTitle)
                Text("Sign in with mobile number or email").font(.lmsBody).foregroundStyle(.secondary)

                SectionCard {
                    TextField("Mobile or Email", text: $viewModel.identifier)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .disabled(viewModel.showOTPField)
                        
                    if viewModel.showOTPField {
                        TextField("OTP", text: $viewModel.otp)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.oneTimeCode)
                            .keyboardType(.numberPad)
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.lmsCaption)
                            .foregroundStyle(Color.lmsDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton(viewModel.showOTPField ? "Verify" : "Send OTP", isLoading: viewModel.isBusy) {
                        guard let auth = env?.auth else { return }
                        Task {
                            if viewModel.showOTPField {
                                if let user = await viewModel.verifyOTP(authService: auth) {
                                    session.currentUser = user
                                    // Normally we would fetch borrower profile as well
                                }
                            } else {
                                await viewModel.requestOTP(authService: auth)
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding(Spacing.m)
            .navigationTitle("Sign in")
        }
    }
}

#Preview {
    // Requires mock environment
    LoginView()
        .environment(SessionStore())
}
