import Foundation

enum Formatting {
    static func currency(_ amount: Decimal, code: String = "INR") -> String {
        let val = NSDecimalNumber(decimal: amount).doubleValue
        let absVal = abs(val)
        let isNegative = val < 0
        let symbol = code == "INR" ? "₹" : "\(code) "

        let formatShorthand: (Double, String) -> String = { value, suffix in
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            formatter.numberStyle = .decimal
            let numStr = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
            return "\(isNegative ? "-" : "")\(symbol)\(numStr) \(suffix)"
        }

        if absVal >= 10_000_000 {
            return formatShorthand(absVal / 10_000_000, "Cr")
        } else if absVal >= 100_000 {
            return formatShorthand(absVal / 100_000, "L")
        } else if absVal >= 1_000 {
            return formatShorthand(absVal / 1_000, "K")
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = code
            formatter.maximumFractionDigits = 0
            if code == "INR" {
                formatter.currencySymbol = "₹"
                formatter.locale = Locale(identifier: "en_IN")
            }
            return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? amount.formatted(.currency(code: code))
        }
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
