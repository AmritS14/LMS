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

    static func compactIndianRupee(_ amount: Decimal) -> String {
        let crore: Decimal = 10_000_000
        let lakh: Decimal = 100_000
        
        let absAmount = abs(amount)
        let sign = amount < 0 ? "-" : ""
        
        if absAmount >= crore {
            let val = absAmount / crore
            return sign + "₹" + formatDecimal(val) + "Cr"
        } else if absAmount >= lakh {
            let val = absAmount / lakh
            return sign + "₹" + formatDecimal(val) + "L"
        } else {
            return Formatting.currency(amount)
        }
    }

    private static func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}
