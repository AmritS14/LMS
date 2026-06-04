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

    func signIn(authService: any AuthService, password: String) async -> Bool {
        isBusy = true
        errorMessage = nil
        do {
            _ = try await authService.signIn(email: identifier, password: password)
            try await authService.requestOTP(identifier: identifier)
            isBusy = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isBusy = false
            return false
        }
    }

    func signUp(authService: any AuthService, password: String, fullName: String, phone: String, dob: Date) async -> Bool {
        isBusy = true
        errorMessage = nil
        do {
            try await authService.signUp(email: identifier, password: password, fullName: fullName, phone: phone, dob: dob)
            isBusy = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isBusy = false
            return false
        }
    }

    func verifyEmailOTP(authService: any AuthService) async -> User? {
        isBusy = true
        errorMessage = nil
        do {
            let user = try await authService.verifyEmailOTP(email: identifier, code: otp)
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
