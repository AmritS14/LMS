import SwiftUI

struct StaffLoginView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var email: String = ""
    @State private var isLoading = false
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.lmsNavyBlue.opacity(0.92), Color.lmsPrimary.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    Spacer()

                    // Logo block
                    VStack(spacing: Spacing.m) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.15))
                                .frame(width: 88, height: 88)
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                        }
                        Text("LMS Staff Portal")
                            .font(.lmsTitle)
                            .foregroundStyle(.white)
                        Text("Secure access for authorised staff")
                            .font(.lmsSubheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    Spacer()

                    // Card
                    VStack(spacing: Spacing.l) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Work Email")
                                .font(.lmsCaption)
                                .foregroundStyle(.secondary)
                            TextField("you@organisation.in", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }

                        PrimaryButton("Sign In with Passkey", isLoading: isLoading) {
                            signIn()
                        }

                        if showError {
                            Label("Sign-in failed. Please try again.", systemImage: "exclamationmark.triangle")
                                .font(.lmsCaption)
                                .foregroundStyle(Color.lmsDanger)
                        }

                        HStack {
                            Divider()
                            Text("or").font(.lmsCaption).foregroundStyle(.secondary)
                            Divider()
                        }

                        // Demo quick-login buttons
                        VStack(spacing: Spacing.s) {
                            Text("Demo Login").font(.lmsCaption).foregroundStyle(.secondary)
                            HStack(spacing: Spacing.s) {
                                DemoRoleButton(label: "Officer", color: .lmsNavyBlue) { signInAs(.loanOfficer) }
                                DemoRoleButton(label: "Manager", color: .lmsPrimary) { signInAs(.manager) }
                                DemoRoleButton(label: "Admin", color: .lmsAccent) { signInAs(.admin) }
                            }
                        }
                    }
                    .padding(Spacing.l)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.large))
                    .padding(.horizontal, Spacing.m)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func signIn() {
        guard let env else { return }
        isLoading = true
        Task {
            do {
                let user = try await env.auth.signInWithPasskey()
                session.currentUser = user
                session.staffProfile = MockData.loanOfficerStaff
            } catch {
                showError = true
            }
            isLoading = false
        }
    }

    private func signInAs(_ role: UserRole) {
        switch role {
        case .loanOfficer:
            session.currentUser = MockData.loanOfficerUser
            session.staffProfile = MockData.loanOfficerStaff
        case .manager:
            session.currentUser = MockData.managerUser
        default:
            let adminUser = User(fullName: "Admin User", email: "admin@lmsbank.in", phone: "+91-9000000099", role: role)
            session.currentUser = adminUser
        }
    }
}

private struct DemoRoleButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.lmsCaption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s)
                .background(color, in: RoundedRectangle(cornerRadius: CornerRadius.small))
        }
    }
}

#Preview { StaffLoginView() }
