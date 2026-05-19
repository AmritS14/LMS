import Foundation

enum Formatting {
    static func currency(_ amount: Decimal, code: String = "INR") -> String {
        amount.formatted(.currency(code: code))
    }

    static func percent(_ value: Double, fractionDigits: Int = 2) -> String {
        value.formatted(.percent.precision(.fractionLength(fractionDigits)))
    }

    static func date(_ date: Date, style: Date.FormatStyle.DateStyle = .abbreviated) -> String {
        date.formatted(date: style, time: .omitted)
    }
}
