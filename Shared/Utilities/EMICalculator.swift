import Foundation

enum EMICalculator {
    struct Result: Sendable, Hashable {
        let monthlyInstallment: Decimal
        let totalInterest: Decimal
        let totalPayable: Decimal
        let schedule: [EMI]
    }

    /// Standard reducing-balance EMI. Inputs: principal, annual interest %, tenure in months.
    /// TODO: implement amortisation schedule.
    static func calculate(
        principal: Decimal,
        annualInterestRate: Double,
        tenureMonths: Int,
        startDate: Date = .now
    ) -> Result {
        Result(
            monthlyInstallment: 0,
            totalInterest: 0,
            totalPayable: 0,
            schedule: []
        )
    }
}
