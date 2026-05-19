import Foundation
import SwiftUI

@MainActor
@Observable
final class SessionStore {
    var currentUser: User?
    var borrowerProfile: BorrowerProfile?
    var staffProfile: StaffProfile?
    var isAuthenticating: Bool = false

    init(
        currentUser: User? = nil,
        borrowerProfile: BorrowerProfile? = nil,
        staffProfile: StaffProfile? = nil
    ) {
        self.currentUser = currentUser
        self.borrowerProfile = borrowerProfile
        self.staffProfile = staffProfile
    }

    var isAuthenticated: Bool { currentUser != nil }
    var role: UserRole? { currentUser?.role }
}
