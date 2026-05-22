import SwiftUI

struct NotificationsView: View {
    @Environment(\.appEnvironment) private var env
    
    @State private var notifications: [PushNotification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else if let error = errorMessage {
                Text(error).foregroundStyle(Color.lmsDanger)
            } else if notifications.isEmpty {
                Text("No notifications").foregroundStyle(.secondary)
            } else {
                ForEach(notifications) { notif in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(notif.title).font(.lmsHeadline)
                            Spacer()
                            Text(Formatting.date(notif.receivedAt, style: .long)).font(.lmsCaption).foregroundStyle(.secondary)
                        }
                        Text(notif.body).font(.lmsBody)
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
        }
        .navigationTitle("Notifications")
        .task {
            await fetchNotifications()
        }
    }
    
    private func fetchNotifications() async {
        guard let env = env else { return }
        isLoading = true
        do {
            notifications = try await env.notifications.fetchHistory(limit: 50)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview { 
    NavigationStack {
        NotificationsView()
            .environment(\.appEnvironment, AppEnvironment(
                auth: MockAuthService(),
                loans: MockLoanService(),
                documents: MockDocumentService(),
                notifications: MockNotificationService(),
                messaging: MockMessagingService(),
                keychain: MockKeychainService()
            ))
    }
}
