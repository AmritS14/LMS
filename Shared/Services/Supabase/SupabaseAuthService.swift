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
        
        return User(
            id: sbUser.id,
            fullName: name,
            email: sbUser.email ?? "",
            phone: contactPhone,
            role: .borrower, // Ideally we query public.users for the real role in the future
            isActive: true
        )
    }
}
