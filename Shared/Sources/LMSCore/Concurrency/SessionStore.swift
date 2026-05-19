import Foundation
import SwiftUI

@MainActor
@Observable
public final class SessionStore {
    public var currentUser: User?
    public var isAuthenticating: Bool = false

    public init(currentUser: User? = nil) {
        self.currentUser = currentUser
    }

    public var isAuthenticated: Bool { currentUser != nil }
    public var role: UserRole? { currentUser?.role }
}
