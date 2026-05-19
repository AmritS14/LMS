import Foundation
import Observation
import LMSCore

@MainActor
@Observable
final class LoanApplicationViewModel {
    var draft: LoanApplication?
    var isSubmitting: Bool = false

    // TODO: inject LoanService
    func submit() async { /* TODO */ }
}
