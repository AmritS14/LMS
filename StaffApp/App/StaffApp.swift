import SwiftUI

@main
struct StaffApp: App {
    @State private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            StaffRootView()
                .environment(session)
        }
    }
}
