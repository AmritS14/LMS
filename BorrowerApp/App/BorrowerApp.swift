import SwiftUI
import UIKit

@main
struct BorrowerApp: App {
    @State private var session = SessionStore()

    private let appEnvironment = AppEnvironment(
        auth: SupabaseAuthService(),
        loans: SupabaseLoanService(client: SupabaseManager.shared.client),
        documents: MockDocumentService(),
        notifications: MockNotificationService(),
        messaging: MockMessagingService(),
        keychain: MockKeychainService()
    )

    init() {
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.systemGray3
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.label
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(\.appEnvironment, appEnvironment)
        }
    }
}
