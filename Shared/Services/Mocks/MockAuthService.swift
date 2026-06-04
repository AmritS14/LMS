import Foundation

/// Mock implementation of `AuthService` for development.
/// OTP is always "123456". Any identifier is accepted.
actor MockAuthService: AuthService {
    private var _currentUser: User?

    // Seed borrower
    static let seedBorrower = User(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        fullName: "Naman Gupta",
        email: "naman@example.com",
        phone: "+91 98765 43210",
        role: .borrower
    )

    static let seedBorrowerProfile = BorrowerProfile(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        dateOfBirth: Calendar.current.date(from: DateComponents(year: 1998, month: 6, day: 15))!,
        address: PostalAddress(
            line1: "42 MG Road", line2: "Sector 14",
            city: "Gurugram", state: "Haryana",
            pinCode: 122001, country: "India"
        ),
        panNumber: "ABCDE1234F",
        aadhaarLast4: "6789",
        employmentType: .salaried,
        monthlyIncome: 120_000,
        kycStatus: .verified,
        creditScore: 780
    )

    var currentUser: User? {
        get async {
            return _currentUser
        }
    }

    func signIn(email: String, password: String) async throws -> User {
        try await Task.sleep(for: .seconds(1))
        return Self.seedBorrower
    }

    func signUp(email: String, password: String, fullName: String, phone: String, dob: Date) async throws {
        try await Task.sleep(for: .seconds(0.8))
        if email.contains("fail") {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Registration failed"])
        }
    }

    func verifyEmailOTP(email: String, code: String) async throws -> User {
        try await Task.sleep(for: .seconds(1))
        if code == "123456" {
            return Self.seedBorrower
        }
        throw URLError(.userAuthenticationRequired)
    }

    func requestOTP(identifier: String) async throws {
        try await Task.sleep(for: .milliseconds(500))
    }

    func verifyOTP(identifier: String, code: String) async throws -> User {
        try await Task.sleep(for: .milliseconds(400))
        guard code == "123456" else {
            throw NSError(domain: "Auth", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid OTP. Use 123456."])
        }
        let user = Self.seedBorrower
        _currentUser = user
        return user
    }

    func signInWithPasskey() async throws -> User {
        try await Task.sleep(for: .milliseconds(300))
        let user = Self.seedBorrower
        _currentUser = user
        return user
    }

    func signOut() async throws {
        _currentUser = nil
    }
    
    private var mockBorrowerProfile: BorrowerProfile? = seedBorrowerProfile

    func fetchBorrowerProfile(userID: UUID) async throws -> BorrowerProfile? {
        return mockBorrowerProfile
    }

    func saveBorrowerProfile(_ profile: BorrowerProfile) async throws {
        mockBorrowerProfile = profile
    }
}
