import Foundation

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

let dateStr = "2026-05-25T15:24:08.123456+00:00"
let formatter = ISO8601DateFormatter()
formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
if let date = formatter.date(from: dateStr) { 
    print("Format 1 works")
} else {
    print("Format 1 fails")
}

let dateStr2 = "2026-05-25T15:24:08+00:00"
formatter.formatOptions = [.withInternetDateTime]
if let date = formatter.date(from: dateStr2) { 
    print("Format 2 works")
} else {
    print("Format 2 fails")
}
