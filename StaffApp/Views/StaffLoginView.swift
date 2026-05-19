import SwiftUI
import LMSCore
import LMSDesignSystem

struct StaffLoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.l) {
                Text("LMS Staff Portal").font(.lmsTitle)
                SectionCard {
                    TextField("Work Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    PrimaryButton("Sign In with Passkey") {
                        // TODO: AuthService.signInWithPasskey
                    }
                }
                Spacer()
            }
            .padding(Spacing.m)
            .navigationTitle("Sign in")
        }
    }
}

#Preview { StaffLoginView() }
