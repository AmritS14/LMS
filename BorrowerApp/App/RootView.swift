import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    var body: some View {
        Group {
            if session.isAuthenticated {
                BorrowerTabView()
                    .task {
                        if let env = env {
                            _ = try? await env.notifications.requestAuthorization()
                            if let deviceToken = "mock_device_token".data(using: .utf8) {
                                try? await env.notifications.registerDeviceToken(deviceToken)
                            }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.97)),
                        removal: .opacity
                    ))
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: session.isAuthenticated)
    }
}

struct BorrowerTabView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "house") {
                HomeDashboardView()
            }
            Tab("Apply", systemImage: "plus.circle") {
                NewLoanApplicationView()
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
