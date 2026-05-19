import Foundation

public enum EMICalculator {
    public struct Result: Sendable, Hashable {
        public let monthlyInstallment: Decimal
        public let totalInterest: Decimal
        public let totalPayable: Decimal
        public let schedule: [EMI]
    }

    /// Standard reducing-balance EMI. Inputs: principal, annual interest %, tenure in months.
    /// TODO: implement amortisation schedule.
    public static func calculate(
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
