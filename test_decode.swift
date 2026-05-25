import Foundation

let json = "[]".data(using: .utf8)!
struct DBLoanApplication: Decodable {
    let id: UUID
    let requested_amount: Decimal
}

do {
    let result = try JSONDecoder().decode([DBLoanApplication].self, from: json)
    print("Success: \(result)")
} catch {
    print("Error: \(error)")
}
