import Foundation
import Observation
import LMSCore

@MainActor
@Observable
final class AuthViewModel {
    var identifier: String = ""
    var otp: String = ""
    var isBusy: Bool = false
    var errorMessage: String?

    // TODO: inject AuthService via AppEnvironment
    func requestOTP() async { /* TODO */ }
    func verifyOTP() async -> User? { nil /* TODO */ }
    func signInWithPasskey() async -> User? { nil /* TODO */ }
}
