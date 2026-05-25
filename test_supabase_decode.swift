import Foundation

let jsonLoans = "[]".data(using: .utf8)!
let jsonApps = "[]".data(using: .utf8)!

struct DBLoanProduct: Decodable {
    let id: UUID
    let name: String
}

struct DBLoanApplication: Decodable {
    let id: UUID
    let borrower_id: UUID
    let assigned_officer_id: UUID?
    let loan_product_id: UUID
    let requested_amount: Decimal
    let tenure_months: Int
    let interest_rate: Double
    let status: String
    let created_at: Date
    let updated_at: Date
}

struct DBLoan: Decodable {
    let id: UUID
    let application_id: UUID
    let borrower_id: UUID
    let principal: Decimal
    let interest_rate: Double
    let tenure_months: Int
    let disbursement_date: Date
    let outstanding_balance: Decimal
    let status: String
}

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

do {
    let loans = try customDecoder.decode([DBLoan].self, from: jsonLoans)
    print("Loans decoded: \(loans)")
} catch {
    print("Loans error: \(error)")
}

do {
    let apps = try customDecoder.decode([DBLoanApplication].self, from: jsonApps)
    print("Apps decoded: \(apps)")
} catch {
    print("Apps error: \(error)")
}
