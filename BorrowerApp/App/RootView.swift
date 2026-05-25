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
                    withAnimation {
                        session.currentUser = user
                    }
                }
            }
        }
    }
}

struct BorrowerTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                NavigationStack { HomeDashboardView() }
            }
            Tab("Apply", systemImage: "plus.circle.fill") {
                NavigationStack { NewLoanApplicationView() }
            }
            Tab("Messages", systemImage: "bubble.left.and.bubble.right.fill") {
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
