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
            
            // ISO8601 with fractional seconds: 2026-05-25T17:58:34.981323+00:00
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateStr) { return date }
            
            // ISO8601 without fractional seconds: 2026-05-25T17:58:34+00:00
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateStr) { return date }
            
            // Plain date from Postgres `date` columns: 2026-05-22
            let plainDateFormatter = DateFormatter()
            plainDateFormatter.dateFormat = "yyyy-MM-dd"
            plainDateFormatter.locale = Locale(identifier: "en_US_POSIX")
            plainDateFormatter.timeZone = TimeZone(identifier: "UTC")
            if let date = plainDateFormatter.date(from: dateStr) { return date }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateStr)")
        }
        self.decoder = customDecoder

        let isBorrowerApp = Bundle.main.bundleIdentifier?.contains("BorrowerApp") == true
        let authStorage: any AuthLocalStorage = isBorrowerApp ? KeychainAuthStorage() : MemoryAuthStorage()

        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://kezcsrprvhzysftopjqd.supabase.co")!,
            supabaseKey: "sb_publishable_kVi_Wh86_lesAuTm6f7kxw_8xshrFgQ",
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(decoder: customDecoder),
                auth: SupabaseClientOptions.AuthOptions(storage: authStorage)
            )
        )
    }

    func logAuditEvent(action: String, entityType: String, entityID: UUID, metadata: [String: AnyJSON]) async {
        do {
            struct RPCArgs: Encodable {
                let p_action: String
                let p_entity_type: String
                let p_entity_id: UUID
                let p_metadata: [String: AnyJSON]
            }
            let args = RPCArgs(
                p_action: action,
                p_entity_type: entityType,
                p_entity_id: entityID,
                p_metadata: metadata
            )
            _ = try await client
                .rpc("log_audit_event", params: args)
                .execute()
        } catch {
            print("Failed to log audit event via RPC: \(error)")
        }
    }
}
