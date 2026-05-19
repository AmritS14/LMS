import SwiftUI

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
                    LabeledContent("Status", value: session.borrowerProfile?.kycStatus.rawValue.capitalized ?? "—")
                    NavigationLink("Manage KYC") { KYCView() }
                }
                Section("Credit") {
                    LabeledContent(
                        "Credit Score",
                        value: session.borrowerProfile?.creditScore.map(String.init) ?? "—"
                    )
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
