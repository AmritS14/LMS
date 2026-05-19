import Testing
@testable import LMSCore

@Suite("EMICalculator")
struct EMICalculatorTests {
    @Test("returns zero result for unimplemented stub")
    func placeholder() {
        let result = EMICalculator.calculate(
            principal: 100_000,
            annualInterestRate: 10,
            tenureMonths: 12
        )
        #expect(result.schedule.isEmpty)
    }
}
