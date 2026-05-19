import SwiftUI
import LMSCore
import LMSDesignSystem

struct LoginView: View {
    @State private var identifier: String = ""
    @State private var otp: String = ""
    @State private var otpRequested: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.l) {
                Text("Welcome to LMS").font(.lmsTitle)
                Text("Sign in with mobile number or email").font(.lmsBody).foregroundStyle(.secondary)

                SectionCard {
                    TextField("Mobile or Email", text: $identifier)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.username)
                    if otpRequested {
                        TextField("OTP", text: $otp)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.oneTimeCode)
                            .keyboardType(.numberPad)
                    }
                    PrimaryButton(otpRequested ? "Verify" : "Send OTP") {
                        // TODO: call AuthService
                        otpRequested = true
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
    LoginView()
}
