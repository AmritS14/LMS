import Foundation

let json = """
[{"id":"4729dc69-309f-43d7-9441-21a5f4f4982d","name":"Personal Loan","description":"General personal financing","minimum_amount":10000,"maximum_amount":1000000,"minimum_tenure_months":6,"maximum_tenure_months":60,"minimum_interest_rate":10,"maximum_interest_rate":24,"is_active":true,"created_at":"2026-05-21T13:11:14.743135+00:00"}]
""".data(using: .utf8)!

struct DBLoanProduct: Decodable {
    let id: UUID
    let name: String
}

do {
    let result = try JSONDecoder().decode([DBLoanProduct].self, from: json)
    print("Success: \(result)")
} catch {
    print("Error: \(error)")
}
