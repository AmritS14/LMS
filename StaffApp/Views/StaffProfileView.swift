import SwiftUI

struct StaffProfileView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("Name", value: session.currentUser?.fullName ?? "—")
                    LabeledContent("Email", value: session.currentUser?.email ?? "—")
                    LabeledContent("Role", value: session.role?.rawValue.capitalized ?? "—")
                }
                Section {
                    Button("Sign Out", role: .destructive) {
                        // TODO: AuthService.signOut
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
