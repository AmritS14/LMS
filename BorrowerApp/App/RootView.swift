import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        if session.isAuthenticated {
            BorrowerTabView()
        } else {
            LoginView()
        }
    }
}

struct BorrowerTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeDashboardView()
            }
            Tab("Apply", systemImage: "plus.app") {
                NewLoanApplicationView()
            }
            Tab("EMI", systemImage: "calendar") {
                RepaymentDashboardView()
            }
            Tab("Messages", systemImage: "bubble.left.and.bubble.right") {
                BorrowerMessagingView()
            }
            Tab("Profile", systemImage: "person.crop.circle") {
                BorrowerProfileView()
            }
        }
    }
}

#Preview {
    BorrowerTabView()
        .environment(SessionStore())
}
