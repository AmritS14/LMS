import SwiftUI

@main
struct StaffApp: App {
    @State private var session = SessionStore()
    
    // Wire up Supabase Client and mock services
    let environment = AppEnvironment(
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
                .environment(\.appEnvironment, environment)
        }
    }
}
