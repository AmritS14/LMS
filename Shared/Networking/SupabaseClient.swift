import Foundation
import Supabase

/// A global shared instance of the Supabase client.
/// In a real production app, you might want to inject this via AppEnvironment
/// rather than using a singleton, but this is a convenient starting point.
public let supabase: SupabaseClient = {
    // TODO: Replace with your actual Supabase URL and Anon Key
    let supabaseURL = URL(string: "https://your-project.supabase.co")!
    let supabaseKey = "your-anon-key"
    
    // Customize the client if needed (e.g., using snake_case decoding)
    var options = SupabaseClientOptions(
        db: .init(
            encoder: {
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                return encoder
            }(),
            decoder: {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                // Optional: handle dates
                decoder.dateDecodingStrategy = .iso8601
                return decoder
            }()
        )
    )
    
    return SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseKey,
        options: options
    )
}()
