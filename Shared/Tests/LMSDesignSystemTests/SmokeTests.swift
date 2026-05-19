import Testing
@testable import LMSDesignSystem

@Suite("LMSDesignSystem")
struct DesignSystemSmokeTests {
    @Test("spacing tokens are defined")
    func spacingTokens() {
        #expect(Spacing.m == 16)
        #expect(CornerRadius.medium == 12)
    }
}
