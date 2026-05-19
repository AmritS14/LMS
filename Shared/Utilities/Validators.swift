import Foundation

enum Validators {
    static func isValidEmail(_ value: String) -> Bool {
        value.contains("@") && value.contains(".")
    }

    static func isValidPhone(_ value: String) -> Bool {
        let digits = value.filter(\.isNumber)
        return digits.count >= 10 && digits.count <= 15
    }

    static func isValidPAN(_ value: String) -> Bool {
        value.range(of: #"^[A-Z]{5}[0-9]{4}[A-Z]$"#, options: .regularExpression) != nil
    }
}
