import SwiftUI
import LMSCore

struct SystemSettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Catalog") {
                    NavigationLink("Loan Types") { Text("TODO") }
                    NavigationLink("Document Checklists") { Text("TODO") }
                }
                Section("Communications") {
                    NavigationLink("Notification Templates") { Text("TODO") }
                    NavigationLink("Email Templates") { Text("TODO") }
                }
                Section("Compliance") {
                    NavigationLink("GDPR / Data Retention") { Text("TODO") }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
