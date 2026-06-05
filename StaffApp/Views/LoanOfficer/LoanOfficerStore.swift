import Foundation
import SwiftUI

// The loan officer screens still render through the legacy AppViewModel API,
// but the app root now refers to it as a store so it matches the manager stack.
typealias LoanOfficerStore = AppViewModel
