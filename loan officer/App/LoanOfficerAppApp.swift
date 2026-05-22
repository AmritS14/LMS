import SwiftUI

@main
struct LoanOfficerApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .preferredColorScheme(nil) // Supports both light and dark
        }
    }
}
