import Foundation
import SwiftUI

/// Container for service dependencies. Inject at the app root and read via @Environment.
public struct AppEnvironment: Sendable {
    public var auth: any AuthService
    public var loans: any LoanService
    public var documents: any DocumentService
    public var notifications: any NotificationService
    public var messaging: any MessagingService
    public var keychain: any KeychainService

    public init(
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

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment? = nil
}

public extension EnvironmentValues {
    var appEnvironment: AppEnvironment? {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
