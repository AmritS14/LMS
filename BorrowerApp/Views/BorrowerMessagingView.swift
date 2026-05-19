import SwiftUI

struct BorrowerMessagingView: View {
    var body: some View {
        NavigationStack {
            List {
                // TODO: bind to MessagingService.threads
                Text("No conversations yet").foregroundStyle(.secondary)
            }
            .navigationTitle("Messages")
        }
    }
}

#Preview { BorrowerMessagingView() }
