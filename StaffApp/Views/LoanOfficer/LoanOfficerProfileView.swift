import SwiftUI

struct LoanOfficerProfileView: View {
    @Environment(AppViewModel.self) var viewModel
    @Environment(\.appEnvironment) private var env
    @Environment(SessionStore.self) private var session
    
    // Settings state
    @State private var enableNotifications = true
    @State private var enableBiometrics = false
    @State private var syncOnCellular = true
    
    @State private var showLogoutConfirmation = false

    var body: some View {
        List {
            // MARK: Profile Header
            headerView
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            
            // MARK: Branch Details
            let branch = viewModel.selectedBranch.isEmpty ? (viewModel.officerProfile.branch.isEmpty ? "—" : viewModel.officerProfile.branch) : viewModel.selectedBranch
            if branch != "—" && !branch.isEmpty {
                Section("Branch") {
                    LabeledContent("Branch", value: branch)
                }
            }
            
            // MARK: Preferences & Security
            Section("Notification Preferences") {
                Toggle("Push Alerts", isOn: $enableNotifications)
                    .tint(Color.lmsAccent)
                Toggle("Biometric Security", isOn: $enableBiometrics)
                    .tint(Color.lmsAccent)
                Toggle("Cellular Data Sync", isOn: $syncOnCellular)
                    .tint(Color.lmsAccent)
            }
            
            // MARK: Personal Details
            Section("Personal Details") {
                LabeledContent("Officer ID", value: viewModel.officerProfile.employeeId.isEmpty ? "—" : viewModel.officerProfile.employeeId)
                LabeledContent("Email", value: session.currentUser?.email ?? "—")
                LabeledContent("Phone", value: session.currentUser?.phone ?? "—")
            }
            
            // MARK: Logout
            Section {
                Button(role: .destructive) {
                    showLogoutConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Out?", isPresented: $showLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                Task {
                    try? await env?.auth.signOut()
                    session.currentUser = nil
                    session.staffProfile = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 14) {
            LOAvatarView(
                initials: viewModel.officerProfile.avatarInitials,
                size: 84,
                colors: [
                    Color(red: 0.1, green: 0.4, blue: 0.9),
                    Color(red: 0.3, green: 0.6, blue: 1.0)
                ]
            )
            .shadow(color: Color.blue.opacity(0.15), radius: 8, x: 0, y: 4)

            VStack(spacing: 6) {
                Text(viewModel.officerProfile.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(viewModel.officerProfile.designation)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.15), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s)
    }
}
