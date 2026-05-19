import Foundation
import SwiftUI

@MainActor
@Observable
public final class SessionStore {
    public var currentUser: User?
    public var borrowerProfile: BorrowerProfile?
    public var staffProfile: StaffProfile?
    public var isAuthenticating: Bool = false

    public init(
        currentUser: User? = nil,
        borrowerProfile: BorrowerProfile? = nil,
        staffProfile: StaffProfile? = nil
    ) {
        self.currentUser = currentUser
        self.borrowerProfile = borrowerProfile
        self.staffProfile = staffProfile
    }

    public var isAuthenticated: Bool { currentUser != nil }
    public var role: UserRole? { currentUser?.role }
}
