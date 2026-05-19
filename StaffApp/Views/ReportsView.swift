import SwiftUI

struct ReportsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Generate") {
                    Button("Daily Report (PDF)") { /* TODO */ }
                    Button("Weekly Report (CSV)") { /* TODO */ }
                    Button("Monthly Report (PDF)") { /* TODO */ }
                    Button("NPA Analysis") { /* TODO */ }
                }
                Section("Recent") {
                    Text("No reports yet").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Reports")
        }
    }
}
