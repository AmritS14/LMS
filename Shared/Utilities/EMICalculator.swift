import Foundation

enum EMICalculator {
    struct Result: Sendable, Hashable {
        let monthlyInstallment: Decimal
        let totalInterest: Decimal
        let totalPayable: Decimal
        let schedule: [EMI]
    }

    /// Standard reducing-balance EMI calculation.
    /// Formula: EMI = P × r × (1+r)^n / ((1+r)^n − 1)
    /// where P = principal, r = monthly rate, n = tenure in months.
    static func calculate(
        principal: Decimal,
        annualInterestRate: Double,
        tenureMonths: Int,
        startDate: Date = .now
    ) -> Result {
        guard tenureMonths > 0, principal > 0 else {
            return Result(monthlyInstallment: 0, totalInterest: 0, totalPayable: 0, schedule: [])
        }

        let p = Double(truncating: principal as NSDecimalNumber)
        let monthlyRate = annualInterestRate / 12.0 / 100.0
        let n = Double(tenureMonths)

        // EMI formula (reducing balance)
        let emi: Double
        if monthlyRate > 0 {
            let factor = pow(1 + monthlyRate, n)
            emi = p * monthlyRate * factor / (factor - 1)
        } else {
            emi = p / n
        }

        let emiDecimal = Decimal(emi.rounded(.toNearestOrAwayFromZero))

        // Build amortisation schedule
        var outstanding = p
        var schedule: [EMI] = []
        let calendar = Calendar.current
        let today = Date.now

        for i in 1...tenureMonths {
            let interestComponent = outstanding * monthlyRate
            let principalComponent = emi - interestComponent
            outstanding = max(0, outstanding - principalComponent)

            let dueDate = calendar.date(byAdding: .month, value: i, to: startDate) ?? startDate

            // Determine status based on due date vs today
            let status: EMIStatus
            if dueDate < today {
                status = .paid   // Past EMIs treated as paid in mock
            } else if calendar.isDate(dueDate, equalTo: today, toGranularity: .month) {
                status = .upcoming
            } else {
                status = .upcoming
            }

            schedule.append(EMI(
                installmentNumber: i,
                dueDate: dueDate,
                principalComponent: Decimal(principalComponent.rounded()),
                interestComponent: Decimal(interestComponent.rounded()),
                totalAmount: emiDecimal,
                status: status,
                paidAt: status == .paid ? dueDate : nil
            ))
        }

        let totalPayable = emiDecimal * Decimal(tenureMonths)
        let totalInterest = totalPayable - principal

        return Result(
            monthlyInstallment: emiDecimal,
            totalInterest: totalInterest,
            totalPayable: totalPayable,
            schedule: schedule
        )
    }
}
