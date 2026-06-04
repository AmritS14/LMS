import Foundation

protocol AuthService: Sendable {
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, fullName: String, phone: String, dob: Date) async throws
    func verifyEmailOTP(email: String, code: String) async throws -> User
    func requestOTP(identifier: String) async throws
    func verifyOTP(identifier: String, code: String) async throws -> User
    func signInWithPasskey() async throws -> User
    func signOut() async throws
    func updatePassword(password: String) async throws -> User
    var currentUser: User? { get async }
    
    func fetchBorrowerProfile(userID: UUID) async throws -> BorrowerProfile?
    func saveBorrowerProfile(_ profile: BorrowerProfile) async throws
}
