import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            if session.isAuthenticated {
                BorrowerTabView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            Task {
                await testDatabaseConnection()
            }
        }
    }
    
    private func testDatabaseConnection() async {
        do {
            // We just fetch 0 rows from users table to see if it connects without network errors
            let _ = try await supabase
                .from("users")
                .select()
                .limit(1)
                .execute()
            print("✅ Supabase connection successful!")
        } catch {
            print("❌ Supabase connection failed: \(error)")
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
