import Foundation
import Observation

@MainActor
@Observable
final class AuthViewModel {
    var identifier: String = ""
    var otp: String = ""
    var isBusy: Bool = false
    var errorMessage: String?
    var showOTPField: Bool = false

    func requestOTP(authService: any AuthService) async {
        isBusy = true
        errorMessage = nil
        do {
            try await authService.requestOTP(identifier: identifier)
            showOTPField = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isBusy = false
    }

    func verifyOTP(authService: any AuthService) async -> User? {
        isBusy = true
        errorMessage = nil
        do {
            let user = try await authService.verifyOTP(identifier: identifier, code: otp)
            isBusy = false
            return user
        } catch {
            errorMessage = error.localizedDescription
            isBusy = false
            return nil
        }
    }

    func signInWithPasskey(authService: any AuthService) async -> User? {
        isBusy = true
        errorMessage = nil
        do {
            let user = try await authService.signInWithPasskey()
            isBusy = false
            return user
        } catch {
            errorMessage = error.localizedDescription
            isBusy = false
            return nil
        }
    }
}
