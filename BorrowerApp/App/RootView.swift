import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    @Environment(UnreadMessageStore.self) private var unreadStore

    @State private var showUpdatePassword = false
    @State private var showStartupAnimation = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if showStartupAnimation {
                StartupAnimationView(isPresented: $showStartupAnimation)
                    .transition(.opacity)
            } else if session.isAuthenticated {
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
        .animation(.easeInOut(duration: 0.3), value: showStartupAnimation)
        .animation(.easeInOut(duration: 0.3), value: session.isAuthenticated)
        // Start / stop badge polling based on auth state
        .onChange(of: session.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                startPollingIfNeeded()
            } else {
                unreadStore.reset()
            }
        }
        // Pause polling when app moves to background; resume in foreground
        .onChange(of: scenePhase) { _, phase in
            guard session.isAuthenticated else { return }
            switch phase {
            case .active:
                startPollingIfNeeded()
            case .background, .inactive:
                unreadStore.stopPolling()
            @unknown default:
                break
            }
        }
        .task {
            if let env = env {
                if let user = await env.auth.currentUser {
                    let profile = try? await env.auth.fetchBorrowerProfile(userID: user.id)
                    withAnimation {
                        session.currentUser = user
                        session.borrowerProfile = profile
                    }
                    // Kick off initial badge load once the user is resolved
                    startPollingIfNeeded()
                }
            }
        }
        .onOpenURL { url in
            if url.scheme == "lms" && url.host == "reset-password" {
                showUpdatePassword = true
            }
        }
        .sheet(isPresented: $showUpdatePassword) {
            UpdatePasswordView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Helpers

    private func startPollingIfNeeded() {
        guard let env, let userID = session.currentUser?.id else { return }
        unreadStore.startPolling(
            messagingService: env.messaging,
            currentUserID: userID
        )
    }
}

struct BorrowerTabView: View {
    @Environment(UnreadMessageStore.self) private var unreadStore

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
            .badge(unreadStore.totalUnread)
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
        .environment(UnreadMessageStore())
}

