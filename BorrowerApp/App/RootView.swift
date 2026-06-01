import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    var body: some View {
        Group {
            if session.isAuthenticated {
                BorrowerTabView()
                    .task {
                        if let env {
                            _ = try? await env.notifications.requestAuthorization()
                            if let deviceToken = "mock_device_token".data(using: .utf8) {
                                try? await env.notifications.registerDeviceToken(deviceToken)
                            }
                        }
                    }
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: session.isAuthenticated)
        .task {
            if let env = env {
                if let user = await env.auth.currentUser {
                    let profile = try? await env.auth.fetchBorrowerProfile(userID: user.id)
                    withAnimation {
                        session.currentUser = user
                        session.borrowerProfile = profile
                    }
                }
            }
        }
    }
}

struct BorrowerTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                NavigationStack { HomeDashboardView() }
            }
            Tab("Apply", systemImage: "plus.circle.fill", value: 1) {
                NavigationStack {
                    NewLoanApplicationView(onComplete: {
                        withAnimation { selectedTab = 0 }
                    })
                }
            }
            Tab("Messages", systemImage: "bubble.left.and.bubble.right.fill", value: 2) {
                NavigationStack { BorrowerMessagingView() }
            }
        }
    }
}

#Preview {
    BorrowerTabView()
        .environment(SessionStore(
            currentUser: MockAuthService.seedBorrower,
            borrowerProfile: MockAuthService.seedBorrowerProfile
        ))
        .environment(\.appEnvironment, AppEnvironment(
            auth: MockAuthService(),
            loans: MockLoanService(),
            documents: MockDocumentService(),
            notifications: MockNotificationService(),
            messaging: MockMessagingService(),
            keychain: MockKeychainService()
        ))
}
