import Foundation
import Supabase

/// Central manager for the Supabase SDK client
public struct SupabaseManager: Sendable {
    public static let shared = SupabaseManager()
    
    public let client: SupabaseClient
    
    public let decoder: JSONDecoder
    
    private init() {
        let customDecoder = JSONDecoder()
        customDecoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateStr) { return date }
            
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateStr) { return date }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateStr)")
        }
        self.decoder = customDecoder

        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://kezcsrprvhzysftopjqd.supabase.co")!,
            supabaseKey: "sb_publishable_kVi_Wh86_lesAuTm6f7kxw_8xshrFgQ",
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(decoder: customDecoder)
            )
        )
    }
}
