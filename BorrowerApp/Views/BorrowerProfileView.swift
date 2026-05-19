import SwiftUI
import LMSCore
import LMSDesignSystem

struct BorrowerProfileView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("Name", value: session.currentUser?.fullName ?? "—")
                    LabeledContent("Email", value: session.currentUser?.email ?? "—")
                    LabeledContent("Phone", value: session.currentUser?.phone ?? "—")
                }
                Section("KYC") {
                    LabeledContent("Status", value: session.currentUser?.kycStatus.rawValue.capitalized ?? "—")
                    NavigationLink("Manage KYC") { KYCView() }
                }
                Section("Credit") {
                    LabeledContent("Credit Score", value: "—")
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
