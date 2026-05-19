import SwiftUI
import LMSCore
import LMSDesignSystem

struct KYCView: View {
    var body: some View {
        List {
            Section("Identity") {
                Label("Upload ID Proof", systemImage: "person.text.rectangle")
            }
            Section("Address") {
                Label("Upload Address Proof", systemImage: "house")
            }
            Section("Income") {
                Label("Upload Salary Slips", systemImage: "doc.text")
                Label("Upload Bank Statement", systemImage: "building.columns")
            }
        }
        .navigationTitle("KYC")
    }
}

#Preview { NavigationStack { KYCView() } }
