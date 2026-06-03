import SwiftUI

struct NotificationsView: View {
    @Environment(\.appEnvironment) private var env

    @State private var notifications: [PushNotification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if isLoading && notifications.isEmpty {
                Section {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .listRowBackground(Color.clear)
                }
            } else if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.lmsDanger)
                }
            } else if notifications.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Notifications",
                        systemImage: "bell.slash",
                        description: Text("You'll see updates about your loans and applications here.")
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    ForEach(notifications) { notif in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(notif.title)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(Formatting.date(notif.receivedAt, style: .long))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Text(notif.body)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await fetchNotifications() }
        .task { await fetchNotifications() }
    }

    private func fetchNotifications() async {
        guard let env else { return }
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
                keychain: MockKeychainService(),
            admin: MockAdminService(),
            aadhaarKYC: MockAadhaarKYCService()
            ))
    }
}
