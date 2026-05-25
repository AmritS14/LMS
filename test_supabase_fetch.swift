import Foundation
import Supabase

let customDecoder = JSONDecoder()
customDecoder.dateDecodingStrategy = .custom { decoder in
    let container = try decoder.singleValueContainer()
    let dateStr = try container.decode(String.self)
    
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: dateStr) { return date }
    
    formatter.formatOptions = [.withInternetDateTime]
    if let date = formatter.date(from: dateStr) { return date }
    
    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
}

let client = SupabaseClient(
    supabaseURL: URL(string: "https://kezcsrprvhzysftopjqd.supabase.co")!,
    supabaseKey: "sb_publishable_kVi_Wh86_lesAuTm6f7kxw_8xshrFgQ",
    options: SupabaseClientOptions(
        db: SupabaseClientOptions.DatabaseOptions(decoder: customDecoder)
    )
)

struct DBLoanProduct: Decodable {
    let id: UUID
    let name: String
}

Task {
    do {
        let products: [DBLoanProduct] = try await client
            .from("loan_products")
            .select()
            .execute()
            .value
        print("Products: \(products)")
    } catch {
        print("Error: \(error)")
    }
    exit(0)
}

RunLoop.main.run()
