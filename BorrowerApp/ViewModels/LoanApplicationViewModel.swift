import Foundation
import Observation

@MainActor
@Observable
final class LoanApplicationViewModel {
    var draft: LoanApplication?
    var isSubmitting: Bool = false

    // TODO: inject LoanService
    func submit() async { /* TODO */ }
}
