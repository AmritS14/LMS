import SwiftUI

struct ManagerProfileView: View {
    @Environment(ManagerStore.self) private var managerStore
    @Environment(SessionStore.self) private var session

    @State private var notificationsEnabled = true
    @State private var biometricEnabled = true

    private var profileName: String {
        managerStore.managerProfile.name
    }

    private var employeeID: String {
        managerStore.managerProfile.employeeID
    }

    private var branchName: String {
        managerStore.branchName
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

            Section("Branch Information") {
                LabeledContent("Branch", value: branchName)
                LabeledContent("Branch Code", value: "BLR-MG01")
                LabeledContent("Region", value: "South India")
            }

            // MARK: Preferences

            Section("Preferences") {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Notifications", systemImage: "bell.badge")
                }

                NavigationLink {
                    placeholderDetail("Report Preferences")
                } label: {
                    Label("Report Preferences", systemImage: "doc.text")
                }

                NavigationLink {
                    placeholderDetail("Approval Preferences")
                } label: {
                    Label("Approval Preferences", systemImage: "checkmark.seal")
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
            }

            // MARK: Support

            Section("Support") {
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
            }

            // MARK: Account

            Section {
                Button(role: .destructive) {
                    // TODO: AuthService.signOut
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
