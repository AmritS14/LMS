import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) var viewModel

    var body: some View {
        @Bindable var bindableViewModel = viewModel
        NavigationStack(path: $bindableViewModel.navigationPath) {
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
                        CommunicationsMainView()
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
                        LoanOfficerProfileView()
                    case .chat(let conversation):
                        ChatView(conversation: conversation, isPushed: true)
                    }
                }
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
}
