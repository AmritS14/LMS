import Foundation
import Supabase

struct SupabaseAuthService: AuthService {
    
    func requestOTP(identifier: String) async throws {
        // Assumes identifier is an email. You can configure Supabase to use phone as well.
        try await supabase.auth.signInWithOTP(email: identifier)
    }
    
    func verifyOTP(identifier: String, code: String) async throws -> User {
        let session = try await supabase.auth.verifyOTP(
            email: identifier,
            token: code,
            type: .magiclink // Use .email for a numeric OTP instead of a magic link depending on Supabase settings
        )
        
        return try await fetchCustomUser(id: session.user.id)
    }
    
    func signInWithPasskey() async throws -> User {
        // Supabase passkey integration typically requires using a web view or native ASAuthorization setup
        // and passing the asserted credential to Supabase Auth. 
        fatalError("Passkey signIn is not fully implemented in this Supabase configuration yet.")
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
    }
    
    var currentUser: User? {
        get async {
            guard let session = try? await supabase.auth.session else { return nil }
            return try? await fetchCustomUser(id: session.user.id)
        }
    }
    
    private func fetchCustomUser(id: UUID) async throws -> User {
        let user: User = try await supabase
            .from("users")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
            
        return user
    }
}
