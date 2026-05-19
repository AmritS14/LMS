import Foundation
import SwiftUI

/// Container for service dependencies. Inject at the app root and read via @Environment.
struct AppEnvironment: Sendable {
    var auth: any AuthService
    var loans: any LoanService
    var documents: any DocumentService
    var notifications: any NotificationService
    var messaging: any MessagingService
    var keychain: any KeychainService

    init(
        auth: any AuthService,
        loans: any LoanService,
        documents: any DocumentService,
        notifications: any NotificationService,
        messaging: any MessagingService,
        keychain: any KeychainService
    ) {
        self.auth = auth
        self.loans = loans
        self.documents = documents
        self.notifications = notifications
        self.messaging = messaging
        self.keychain = keychain
    }
}

extension EnvironmentValues {
    @Entry var appEnvironment: AppEnvironment? = nil
}
