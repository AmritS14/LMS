import SwiftUI

struct StaffMessagingView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("No conversations").foregroundStyle(.secondary)
            }
            .navigationTitle("Messages")
        }
    }
}
