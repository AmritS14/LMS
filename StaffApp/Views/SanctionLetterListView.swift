import SwiftUI
import LMSCore

struct SanctionLetterListView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("No sanction letters yet").foregroundStyle(.secondary)
            }
            .navigationTitle("Sanction Letters")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New", systemImage: "plus") { /* TODO */ }
                }
            }
        }
    }
}
