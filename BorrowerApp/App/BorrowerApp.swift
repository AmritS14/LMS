import SwiftUI
import UIKit

@main
struct BorrowerApp: App {
    @State private var session = SessionStore(
//        currentUser: MockAuthService.seedBorrower,
//        borrowerProfile: MockAuthService.seedBorrowerProfile
    )

    private let appEnvironment = AppEnvironment(
        auth: SupabaseAuthService(),
        loans: SupabaseLoanService(client: SupabaseManager.shared.client),
        documents: SupabaseDocumentService(client: SupabaseManager.shared.client),
        notifications: NoOpNotificationService(),
        messaging: SupabaseMessagingService(client: SupabaseManager.shared.client),
        keychain: SecureKeychainService(),
        admin: SupabaseAdminService(client: SupabaseManager.shared.client),
        aadhaarKYC: SupabaseAadhaarKYCService(client: SupabaseManager.shared.client)
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
