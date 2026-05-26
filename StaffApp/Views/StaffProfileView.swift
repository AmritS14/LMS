import SwiftUI

struct StaffProfileView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var isSigningOut = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("Name", value: session.currentUser?.fullName ?? "—")
                    LabeledContent("Email", value: session.currentUser?.email ?? "—")
                    LabeledContent("Role", value: session.role?.rawValue.capitalized ?? "—")
                }
                Section {
                    Button(role: .destructive) {
                        Task {
                            isSigningOut = true
                            try? await env?.auth.signOut()
                            await MainActor.run {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    session.currentUser = nil
                                }
                            }
                        }
                    } label: {
                        if isSigningOut {
                            HStack {
                                ProgressView().tint(.red)
                                Text("Signing out…")
                            }
                        } else {
                            Text("Sign Out")
                        }
                    }
                    .disabled(isSigningOut)
                }
            }
            .navigationTitle("Profile")
        }
    }
}
