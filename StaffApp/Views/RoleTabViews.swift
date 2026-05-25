import SwiftUI

struct OfficerTabView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "rectangle.grid.2x2.fill") {
                OfficerNavigationStack { DashboardView() }
            }
            Tab("Queue", systemImage: "tray.full") {
                OfficerNavigationStack { AllApplicationsView() }
            }
            Tab("Documents", systemImage: "doc.richtext") {
                OfficerNavigationStack { DocumentsView() }
            }
            Tab("Messages", systemImage: "bubble.left.and.bubble.right") {
                OfficerNavigationStack { CommunicationsMainView() }
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
            ChatView(conversation: SampleData.conversations[0])
                .environment(viewModel)
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
                ManagerNavigationStack { ManagerDashboardView() }
            }
//            Tab("Applications", systemImage: "tray.full") {
//                ManagerNavigationStack { ManagerApplicationsView() }
//            }
            Tab("Reports", systemImage: "doc.text.magnifyingglass") { ReportsView() }
            Tab("Profile", systemImage: "person.crop.circle") {
                NavigationStack { StaffProfileView() }
            }
        }
    }
}

struct AdminTabView: View {
    @State private var userManagementViewModel = UserManagementViewModel()
    @State private var templateViewModel = TemplateViewModel()
    @State private var loanConfigViewModel = LoanConfigViewModel()
    @State private var dashboardViewModel = DashboardViewModel()

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "rectangle.grid.2x2.fill") {
                NavigationStack {
                    AdminDashboardView(viewModel: dashboardViewModel, userVM: userManagementViewModel)
                }
            }
            Tab("Users", systemImage: "person.3") {
                NavigationStack {
                    UserListView(viewModel: userManagementViewModel)
                }
            }
            Tab("Settings", systemImage: "gearshape.2") {
                NavigationStack {
                    SystemSettingsView(
                        templateViewModel: templateViewModel,
                        loanConfigViewModel: loanConfigViewModel
                    )
                }
            }
            Tab("Audit", systemImage: "list.clipboard") {
                NavigationStack {
                    AuditTrailView()
                }
            }
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
