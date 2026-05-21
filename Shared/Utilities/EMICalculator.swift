import Foundation

enum EMICalculator {
    struct Result: Sendable, Hashable {
        let monthlyInstallment: Decimal
        let totalInterest: Decimal
        let totalPayable: Decimal
        let schedule: [EMI]
    }

    /// Standard reducing-balance (equated monthly instalment) with full amortisation schedule.
    /// - Parameters:
    ///   - principal: Loan principal amount.
    ///   - annualInterestRate: Annual interest rate as a percentage (e.g. 8.5 for 8.5%).
    ///   - tenureMonths: Total number of monthly instalments.
    ///   - startDate: Date of first EMI payment (defaults to next month from today).
    static func calculate(
        principal: Decimal,
        annualInterestRate: Double,
        tenureMonths: Int,
        startDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    ) -> Result {
        guard tenureMonths > 0, annualInterestRate >= 0, principal > 0 else {
            return Result(monthlyInstallment: 0, totalInterest: 0, totalPayable: 0, schedule: [])
        }

        let monthlyRate = annualInterestRate / 12.0 / 100.0

        // EMI = P * r * (1+r)^n / ((1+r)^n - 1)
        let emi: Double
        if monthlyRate == 0 {
            emi = (principal as NSDecimalNumber).doubleValue / Double(tenureMonths)
        } else {
            let pow = Foundation.pow(1.0 + monthlyRate, Double(tenureMonths))
            emi = (principal as NSDecimalNumber).doubleValue * monthlyRate * pow / (pow - 1.0)
        }

        let emiDecimal = Decimal(emi).rounded(2)
        var balance = principal
        var schedule: [EMI] = []
        let calendar = Calendar.current

        for i in 1...tenureMonths {
            let dueDate = calendar.date(byAdding: .month, value: i - 1, to: startDate) ?? startDate
            let interestComponent = (balance * Decimal(monthlyRate)).rounded(2)
            var principalComponent = emiDecimal - interestComponent
            // Last instalment: pay whatever is left to handle rounding
            if i == tenureMonths {
                principalComponent = balance
            }
            let instalment = EMI(
                installmentNumber: i,
                dueDate: dueDate,
                principalComponent: principalComponent,
                interestComponent: interestComponent,
                totalAmount: principalComponent + interestComponent,
                status: dueDate < .now ? (Bool.random() ? .paid : .overdue) : .upcoming
            )
            schedule.append(instalment)
            balance -= principalComponent
        }

        let totalPayable = schedule.reduce(Decimal(0)) { $0 + $1.totalAmount }
        let totalInterest = totalPayable - principal

        return Result(
            monthlyInstallment: emiDecimal,
            totalInterest: totalInterest,
            totalPayable: totalPayable,
            schedule: schedule
        )
    }
}

private extension Decimal {
    func rounded(_ scale: Int) -> Decimal {
        var result = Decimal()
        var value = self
        NSDecimalRound(&result, &value, scale, .plain)
        return result
    }
}
