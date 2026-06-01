import SwiftUI

struct OfficerTabView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "rectangle.grid.2x2.fill") {
                OfficerNavigationStack { DashboardView() }
            }
            Tab("Applications", systemImage: "tray.full.fill") {
                OfficerNavigationStack { AllApplicationsView() }
            }
            Tab("Recovery", systemImage: "arrow.clockwise.circle.fill") {
                OfficerNavigationStack { RecoveryVerificationView() }
            }
        }
    }
}

// Wraps each tab root in the shared loan-officer navigation path so every
// screen resolves the same destination enum.
struct OfficerNavigationStack<Root: View>: View {
    @Environment(AppViewModel.self) private var viewModel

    @ViewBuilder var root: () -> Root

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        NavigationStack(path: $bindableViewModel.navigationPath) {
            root()
                .navigationDestination(for: AppDestination.self) { destination in
                    destinationView(for: destination)
                }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
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

struct ManagerTabView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "rectangle.grid.2x2.fill") {
                ManagerNavigationStack { ManagerPortfolioView() }
            }
            Tab("Applications", systemImage: "doc.text") {
                ManagerNavigationStack { ManagerApplicationsView() }
            }
            Tab("Reports", systemImage: "doc.text.magnifyingglass") {
                ManagerNavigationStack { ManagerReportsView() }
            }
        }
    }
}

struct AdminTabView: View {
    @Environment(\.appEnvironment) private var env

    @State private var userManagementViewModel = UserManagementViewModel()
    @State private var templateViewModel = TemplateViewModel()
    @State private var loanConfigViewModel = LoanConfigViewModel()
    @State private var dashboardViewModel = DashboardViewModel()

    var body: some View {
        TabView {
            Tab("Overview", systemImage: "rectangle.grid.2x2.fill") {
                NavigationStack {
                    AdminDashboardView(viewModel: dashboardViewModel, userVM: userManagementViewModel)
                }
            }
            Tab("Users", systemImage: "person.2.fill") {
                NavigationStack {
                    UserListView(viewModel: userManagementViewModel)
                }
            }

            Tab("Configure", systemImage: "command.circle") {
                NavigationStack {
                    SystemSettingsView(
                        templateViewModel: templateViewModel,
                        loanConfigViewModel: loanConfigViewModel
                    )
                }
            }
        }
        .task {
            userManagementViewModel.configure(environment: env)
            await userManagementViewModel.load()
            loanConfigViewModel.configure(environment: env)
            await loanConfigViewModel.load()
        }
    }
}

#Preview("Manager") {
    ManagerTabView()
        .environment(ManagerStore.preview)
        .environment(SessionStore())
}

#Preview("Officer") {
    OfficerTabView()
        .environment(LoanOfficerStore())
        .environment(SessionStore())
}

#Preview("Admin") {
    AdminTabView()
        .environment(LoanOfficerStore())
        .environment(SessionStore())
}
