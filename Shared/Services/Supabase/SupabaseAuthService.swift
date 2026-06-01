import Foundation
import Supabase

actor SupabaseAuthService: AuthService {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let session = try await client.auth.signIn(email: email, password: password)
        return try await mapSupabaseUserToLocalUser(session.user)
    }
    
    func signUp(email: String, password: String, fullName: String, phone: String) async throws {
        // According to supabase-swift v2, signUp with userMetadata can be passed via SignUpOptions
        let meta: [String: AnyJSON] = [
            "full_name": .string(fullName),
            "contact_phone": .string(phone) // Using 'contact_phone' because Supabase drops 'phone' in metadata
        ]
        _ = try await client.auth.signUp(
            email: email, 
            password: password, 
            data: meta
        )
    }
    
    func verifyEmailOTP(email: String, code: String) async throws -> User {
        let session = try await client.auth.verifyOTP(
            email: email,
            token: code,
            type: .signup
        )
        return try await mapSupabaseUserToLocalUser(session.user)
    }
    
    func requestOTP(identifier: String) async throws {
        // Not used in email/password flow
        throw NSError(domain: "Auth", code: 501, userInfo: [NSLocalizedDescriptionKey: "Use email/password sign-in instead."])
    }
    
    func verifyOTP(identifier: String, code: String) async throws -> User {
        // Not used in email/password flow
        throw NSError(domain: "Auth", code: 501, userInfo: [NSLocalizedDescriptionKey: "Use verifyEmailOTP instead."])
    }
    
    func signInWithPasskey() async throws -> User {
        // Not implemented in this basic Supabase setup
        throw URLError(.unsupportedURL)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    var currentUser: User? {
        get async {
            guard let session = try? await client.auth.session else { return nil }
            return try? await mapSupabaseUserToLocalUser(session.user)
        }
    }
    
    private struct DBUserProfile: Decodable {
        let id: UUID
        let email: String?
        let role: String
        let full_name: String?
        let phone: String?
        let is_active: Bool?
    }

    private func mapRole(_ raw: String) -> UserRole {
        switch raw.lowercased() {
        case "loan_officer", "loanofficer": return .loanOfficer
        case "manager": return .manager
        case "admin": return .admin
        default: return .borrower
        }
    }

    private func mapSupabaseUserToLocalUser(_ sbUser: Supabase.User) async throws -> User {
        var name = "Supabase User"
        var contactPhone = sbUser.phone ?? ""

        let meta = sbUser.userMetadata

        // Check full_name
        if case .string(let n) = meta["full_name"] {
            name = n
        } else if let n = meta["full_name"]?.value as? String {
            name = n // Fallback just in case AnyJSON exposes .value
        }

        // Check contact_phone if native phone is empty
        if contactPhone.isEmpty {
            if case .string(let p) = meta["contact_phone"] {
                contactPhone = p
            } else if let p = meta["contact_phone"]?.value as? String {
                contactPhone = p
            }
        }

        // The real role lives in public.users. RLS lets a user read their own row.
        // Fall back to borrower if the profile row isn't available yet.
        var role: UserRole = .borrower
        var isActive = true
        if let profile = try? await fetchUserProfile(id: sbUser.id) {
            role = mapRole(profile.role)
            if let n = profile.full_name, !n.isEmpty { name = n }
            if let p = profile.phone, !p.isEmpty, contactPhone.isEmpty { contactPhone = p }
            isActive = profile.is_active ?? true
        }

        return User(
            id: sbUser.id,
            fullName: name,
            email: sbUser.email ?? "",
            phone: contactPhone,
            role: role,
            isActive: isActive
        )
    }

    private func fetchUserProfile(id: UUID) async throws -> DBUserProfile {
        let response = try await client
            .from("users")
            .select("id, email, role, full_name, phone, is_active")
            .eq("id", value: id)
            .single()
            .execute()
        return try SupabaseManager.shared.decoder.decode(DBUserProfile.self, from: response.data)
    }
    
    // MARK: - Borrower Profile DB Models

    private struct DBBorrowerProfile: Decodable {
        let id: UUID
        let date_of_birth: Date?
        let address_line1: String?
        let address_line2: String?
        let city: String?
        let state: String?
        let pin_code: Int?
        let country: String?
        let pan_number: String?
        let aadhaar_last4: String?
        let employment_type: String?
        let monthly_income: Decimal?
        let kyc_status: String?
        let credit_score: Int?
    }

    private struct DBEncodableBorrowerProfile: Encodable {
        let id: UUID
        let date_of_birth: String
        let address_line1: String?
        let address_line2: String?
        let city: String?
        let state: String?
        let pin_code: Int?
        let country: String?
        let pan_number: String?
        let aadhaar_last4: String?
        let employment_type: String?
        let monthly_income: Decimal?
        let kyc_status: String
        let credit_score: Int?
    }

    private func mapDBBorrowerProfileToLocal(_ db: DBBorrowerProfile) -> BorrowerProfile {
        var address: PostalAddress? = nil
        if let line1 = db.address_line1,
           let city = db.city,
           let state = db.state,
           let pin = db.pin_code,
           let country = db.country {
            address = PostalAddress(
                line1: line1,
                line2: db.address_line2,
                city: city,
                state: state,
                pinCode: pin,
                country: country
            )
        }
        
        let kyc: KYCStatus
        if let kycStr = db.kyc_status {
            kyc = KYCStatus(rawValue: kycStr.lowercased()) ?? .pending
        } else {
            kyc = .pending
        }
        
        let emp: EmploymentType?
        if let empStr = db.employment_type {
            emp = EmploymentType(rawValue: empStr) ?? EmploymentType(rawValue: empStr.lowercased())
        } else {
            emp = nil
        }
        
        return BorrowerProfile(
            id: db.id,
            dateOfBirth: db.date_of_birth ?? Date(),
            address: address,
            panNumber: db.pan_number,
            aadhaarLast4: db.aadhaar_last4,
            employmentType: emp,
            monthlyIncome: db.monthly_income,
            kycStatus: kyc,
            creditScore: db.credit_score
        )
    }

    func fetchBorrowerProfile(userID: UUID) async throws -> BorrowerProfile? {
        do {
            let response = try await client
                .from("borrower_profiles")
                .select("*")
                .eq("id", value: userID)
                .single()
                .execute()
            
            let dbProfile = try SupabaseManager.shared.decoder.decode(DBBorrowerProfile.self, from: response.data)
            return mapDBBorrowerProfileToLocal(dbProfile)
        } catch {
            let nsError = error as NSError
            let errorMsg = error.localizedDescription.lowercased()
            if nsError.domain == "PostgREST" || errorMsg.contains("empty") || errorMsg.contains("0 rows") || errorMsg.contains("decoding") || errorMsg.contains("json") || errorMsg.contains("406") {
                return nil
            }
            throw error
        }
    }

    func saveBorrowerProfile(_ profile: BorrowerProfile) async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        let encodable = DBEncodableBorrowerProfile(
            id: profile.id,
            date_of_birth: formatter.string(from: profile.dateOfBirth),
            address_line1: profile.address?.line1,
            address_line2: profile.address?.line2,
            city: profile.address?.city,
            state: profile.address?.state,
            pin_code: profile.address?.pinCode,
            country: profile.address?.country,
            pan_number: profile.panNumber,
            aadhaar_last4: profile.aadhaarLast4,
            employment_type: profile.employmentType?.rawValue,
            monthly_income: profile.monthlyIncome,
            kyc_status: profile.kycStatus.rawValue,
            credit_score: profile.creditScore
        )
        
        try await client
            .from("borrower_profiles")
            .upsert(encodable)
            .execute()
    }
}
