import SwiftUI

struct UserManagementView: View {
    @State private var selectedRole: UserRole = .borrower

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Role", selection: $selectedRole) {
                    ForEach(UserRole.allCases, id: \.self) {
                        Text($0.rawValue.capitalized).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding(Spacing.m)

                List {
                    // TODO: AdminService.listUsers(role:)
                    Text("No users").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Users")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Invite", systemImage: "person.crop.circle.badge.plus") { /* TODO */ }
                }
            }
        }
    }
}
