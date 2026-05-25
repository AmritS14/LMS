import SwiftUI

@main
struct StaffApp: App {
    @State private var session = SessionStore()

    private let appEnvironment = AppEnvironment(
        auth: SupabaseAuthService(),
        loans: MockLoanService(),
        documents: MockDocumentService(),
        notifications: MockNotificationService(),
        messaging: MockMessagingService(),
        keychain: MockKeychainService()
    )

    var body: some Scene {
        WindowGroup {
            StaffRootView()
                .environment(session)
                .environment(\.appEnvironment, appEnvironment)
        }
    }
}
