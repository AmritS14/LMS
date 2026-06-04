import SwiftUI

struct ManagerProfileView: View {
    @Environment(ManagerStore.self) private var managerStore
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var notificationsEnabled = true
    @State private var emailAlerts = true
    @State private var riskAlerts = true
    @State private var biometricEnabled = true
    @State private var showLogoutConfirmation = false

    private var profileName: String {
        managerStore.managerProfile.name
    }

    private var employeeID: String {
        managerStore.managerProfile.employeeID
    }

    private var branchName: String? {
        let name = managerStore.branchName
        return (name == "—" || name.isEmpty) ? nil : name
    }

    var body: some View {
        List {
            // MARK: Profile header

            Section {
                HStack(spacing: Spacing.m) {
                    AvatarView(initials: initials(from: profileName), size: 56)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(profileName)
                            .font(.lmsTitle3)
                        Text(employeeID)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Branch Manager")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()
                }
                .padding(.vertical, Spacing.xs)
            }

            // MARK: Branch Information

            if let branchName {
                Section("Branch") {
                    LabeledContent("Branch", value: branchName)
                }
            }

            // MARK: Notification Preferences

            Section("Notification Preferences") {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Push Notifications", systemImage: "bell.badge")
                }

                Toggle(isOn: $emailAlerts) {
                    Label("Email Alerts", systemImage: "envelope")
                }

                Toggle(isOn: $riskAlerts) {
                    Label("Risk Alerts", systemImage: "exclamationmark.shield")
                }

                NavigationLink(value: ManagerRoute.riskAlerts) {
                    Label("Alert Thresholds", systemImage: "slider.horizontal.3")
                }
            }

            // MARK: Security

            Section("Security") {
                NavigationLink {
                    placeholderDetail("Change Password")
                } label: {
                    Label("Change Password", systemImage: "lock")
                }

                Toggle(isOn: $biometricEnabled) {
                    Label("Face ID / Touch ID", systemImage: "faceid")
                }

                NavigationLink {
                    placeholderDetail("Two-Factor Authentication")
                } label: {
                    Label("Two-Factor Authentication", systemImage: "lock.shield")
                }
            }




            // MARK: Help

            Section("Help") {
                NavigationLink {
                    placeholderDetail("Help & FAQ")
                } label: {
                    Label("Help & FAQ", systemImage: "questionmark.circle")
                }

                NavigationLink {
                    placeholderDetail("Contact Support")
                } label: {
                    Label("Contact Support", systemImage: "envelope")
                }

                LabeledContent {
                    Text("1.0.0 (Build 42)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } label: {
                    Label("App Version", systemImage: "info.circle")
                }
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
            Text("Are you sure you want to sign out? You will need to log in again to access the manager dashboard.")
        }
    }

    // MARK: Helpers

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    private func placeholderDetail(_ title: String) -> some View {
        Text(title)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ManagerProfileView()
    }
    .environment(ManagerStore.preview)
    .environment(SessionStore())
}
