import SwiftUI

@main
struct BorrowerApp: App {
    @State private var session = SessionStore(
        currentUser: MockAuthService.seedBorrower,
        borrowerProfile: MockAuthService.seedBorrowerProfile
    )

    private let appEnvironment = AppEnvironment(
        auth: MockAuthService(),
        loans: MockLoanService(),
        documents: MockDocumentService(),
        notifications: MockNotificationService(),
        messaging: MockMessagingService(),
        keychain: MockKeychainService()
    )

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(\.appEnvironment, appEnvironment)
        }
    }
}
