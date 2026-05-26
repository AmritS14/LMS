import SwiftUI

@main
struct StaffApp: App {
    @State private var session = SessionStore()

    private let appEnvironment = AppEnvironment(
        auth: SupabaseAuthService(),
        loans: SupabaseLoanService(client: SupabaseManager.shared.client),
        documents: SupabaseDocumentService(client: SupabaseManager.shared.client),
        notifications: MockNotificationService(),
        messaging: SupabaseMessagingService(client: SupabaseManager.shared.client),
        keychain: MockKeychainService(),
        admin: SupabaseAdminService(client: SupabaseManager.shared.client)
    )

    var body: some Scene {
        WindowGroup {
            StaffRootView()
                .environment(session)
                .environment(\.appEnvironment, appEnvironment)
        }
    }
}
