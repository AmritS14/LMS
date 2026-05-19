import Foundation

protocol AuthService: Sendable {
    func requestOTP(identifier: String) async throws
    func verifyOTP(identifier: String, code: String) async throws -> User
    func signInWithPasskey() async throws -> User
    func signOut() async throws
    var currentUser: User? { get async }
}
