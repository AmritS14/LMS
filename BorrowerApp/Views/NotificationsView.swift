import SwiftUI
import LMSCore

struct NotificationsView: View {
    var body: some View {
        NavigationStack {
            List {
                // TODO: bind to NotificationService.fetchHistory
                Text("No notifications").foregroundStyle(.secondary)
            }
            .navigationTitle("Notifications")
        }
    }
}

#Preview { NotificationsView() }
