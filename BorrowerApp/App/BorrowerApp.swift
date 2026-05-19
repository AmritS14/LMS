import SwiftUI
import LMSCore
import LMSDesignSystem

@main
struct BorrowerApp: App {
    @State private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
    }
}
