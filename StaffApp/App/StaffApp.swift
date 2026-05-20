import SwiftUI

@main
struct StaffApp: App {
    @State private var session = SessionStore(
        currentUser: nil,
        borrowerProfile: nil,
        staffProfile: nil
    )
    private let env = MockData.makeMockEnvironment()

    var body: some Scene {
        WindowGroup {
            StaffRootView()
                .environment(session)
                .environment(\.appEnvironment, env)
        }
    }
}
