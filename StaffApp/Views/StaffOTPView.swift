import SwiftUI

struct StaffOTPView: View {
    let email: String
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    
    @State private var otp: String = ""
    @State private var isBusy: Bool = false
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Enter OTP")
                .font(.title2).bold()
                .accessibilityAddTraits(.isHeader)
            
            Text("We sent a verification code to \(email)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            TextField("000000", text: $otp)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .accessibilityLabel("One Time Password")
                .font(.title).bold()
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .onChange(of: otp) { _, newValue in
                    if newValue.count == 6 {
                        verify()
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            
            Button("Verify") {
                verify()
            }
            .buttonStyle(.borderedProminent)
            .disabled(otp.count < 6 || isBusy)
            
            if isBusy {
                ProgressView()
            }
        }
        .padding()
        .onAppear {
            isFocused = true
        }
    }
    
    private func verify() {
        guard let auth = env?.auth else { return }
        isBusy = true
        errorMessage = nil
        
        Task {
            do {
                let user = try await auth.verifyOTP(identifier: email, code: otp)
                isBusy = false
                withAnimation {
                    session.currentUser = user
                }
            } catch {
                isBusy = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
