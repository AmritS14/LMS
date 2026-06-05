import SwiftUI

struct StaffLoginView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
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
            ZStack {
                // Subtle light gradient background with decorative shapes
                LinearGradient(
                    colors: [Color(.systemBackground), Color.blue.opacity(0.04), Color.blue.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Decorative Background Circles
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.blue.opacity(0.03))
                            .frame(width: 250, height: 250)
                            .offset(x: 100, y: -50)
                    }
                    Spacer()
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer()
                            .frame(height: 40)
                        
                        // Header Section
                        VStack(spacing: 16) {
                            // Logo (scaled and centered)
                            Image("AdminLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                            
                            VStack(spacing: 6) {
                                Text("Welcome Back")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color(.label))
                                
                                Text("Sign in to access your dashboard")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.bottom, 12)
                        
                        // Login Card
                        VStack(alignment: .leading, spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Address")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.secondary)
                                
                                HStack(spacing: 12) {
                                    TextField("Enter your email address", text: $email)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .submitLabel(.next)
                                        .focused($focusedField, equals: .email)
                                        .onSubmit { focusedField = .password }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.secondary)
                                
                                HStack(spacing: 12) {
                                    SecureField("Enter your password", text: $password)
                                        .textContentType(.password)
                                        .submitLabel(.go)
                                        .focused($focusedField, equals: .password)
                                        .onSubmit(submit)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            
                            // Remember Me
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    rememberMe.toggle()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 18))
                                        .foregroundStyle(rememberMe ? Color.blue : Color.secondary)
                                    
                                    Text("Remember Me")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                            
                            // Error Message
                            if let errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(Color.red)
                                    Text(errorMessage)
                                        .font(.footnote)
                                        .foregroundStyle(Color.red)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                            }
                            
                            // Login Button
                            Button(action: submit) {
                                HStack {
                                    Spacer()
                                    if isBusy {
                                        ProgressView().progressViewStyle(.circular)
                                            .tint(.white)
                                    } else {
                                        Text("Sign In")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .background(
                                    isSignInEnabled ?
                                    LinearGradient(colors: [Color.blue, Color.blue.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .disabled(!isSignInEnabled)
                            .padding(.top, 8)
                        }
                        .padding(24)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
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
