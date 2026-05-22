import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            DashboardView()
                .navigationDestination(for: AppDestination.self) { destination in
                    switch destination {
                    case .loanReview:
                        LoanReviewView()
                    case .recovery:
                        RecoveryVerificationView()
                    case .fraudAlerts:
                        LoanReviewView()
                    case .messages:
                        ChatView(
                            conversation: SampleData.conversations[0]
                        )
                        .environmentObject(AppViewModel())
                    case .notifications:
                        NotificationsTabView()
                    case .documents:
                        DocumentsView()
                    case .communications:
                        CommunicationsMainView()
                    case .recoveryManagement:
                        RecoveryManagementMainView()
                    case .allapplications:
                        AllApplicationsView()
                    case .profile:
                        ProfileView()
                    }
                }
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
