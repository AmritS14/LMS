import SwiftUI

struct StaffLoginView: View {
    @Environment(SessionStore.self) private var session
    @State private var userID: String = ""
    @State private var password: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // Header Branding Section
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "building.columns.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.linearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .padding(.top, 16)
                        
                        Text("LMS Staff Portal")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text("Enter your credentials to access the system.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                // Input Fields
                Section {
                    HStack {
                        Image(systemName: "person")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField("User ID", text: $userID)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Image(systemName: "lock")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        SecureField("Password", text: $password)
                    }
                } header: {
                    Text("Account Login")
                }

                // Login Button
                Section {
                    Button(action: handleSignIn) {
                        Text("Login")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(userID.isEmpty || password.isEmpty)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Login Failed", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func handleSignIn() {
        let cleanUserID = userID.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if !cleanUserID.isEmpty && !password.isEmpty {
            // Role detection based on prefix
            let determinedRole: UserRole
            if cleanUserID.hasPrefix("ADM") {
                determinedRole = .admin
            } else if cleanUserID.hasPrefix("MGR") {
                determinedRole = .manager
            } else {
                determinedRole = .loanOfficer
            }
            
            let mockUser = User(
                fullName: "Staff Member",
                email: "\(cleanUserID.lowercased())@lms.com",
                phone: "+91 99999 88888",
                role: determinedRole,
                isActive: true
            )
            session.currentUser = mockUser
        } else {
            alertMessage = "Please enter your User ID and Password."
            showAlert = true
        }
    }
}

#Preview {
    StaffLoginView()
        .environment(SessionStore())
}
