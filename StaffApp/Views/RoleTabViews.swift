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
            Tab("Profile", systemImage: "person.crop.circle") {
                NavigationStack { StaffProfileView() }
            }
        }
    }
}

// Wraps a tab root in a NavigationStack that knows how to resolve every
// OfficerRoute. Centralising destinations keeps each view free of
// `navigationDestination` boilerplate.
struct OfficerNavigationStack<Root: View>: View {
    @ViewBuilder var root: () -> Root

    var body: some View {
        NavigationStack {
            root()
                .navigationDestination(for: OfficerRoute.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func destination(for route: OfficerRoute) -> some View {
        switch route {
        case .allApplications: AllApplicationsView()
        case .review(let id): LoanReviewView(applicationID: id)
        case .communications: CommunicationsMainView()
        case .conversation(let id): ChatView(conversationID: id)
        case .notifications: NotificationsTabView()
        case .recovery: RecoveryManagementMainView()
        case .recoveryDetail: RecoveryVerificationView()
        case .documents: DocumentsView()
        }
    }
}

struct ManagerTabView: View {
    var body: some View {
        TabView {
            Tab("Portfolio", systemImage: "chart.pie") { PortfolioDashboardView() }
            Tab("Approvals", systemImage: "checkmark.seal") { ApprovalsQueueView() }
            Tab("Reports", systemImage: "doc.text.magnifyingglass") { ReportsView() }
            Tab("Products", systemImage: "slider.horizontal.3") { ProductConfigView() }
            Tab("Profile", systemImage: "person.crop.circle") { StaffProfileView() }
        }
    }
}

struct AdminTabView: View {
    var body: some View {
        TabView {
            Tab("Users", systemImage: "person.3") { UserManagementView() }
            Tab("Settings", systemImage: "gearshape.2") { SystemSettingsView() }
            Tab("Audit", systemImage: "list.clipboard") { AuditTrailView() }
            Tab("Profile", systemImage: "person.crop.circle") { StaffProfileView() }
        }
    }
}

#Preview {
    OfficerTabView()
        .environment(LoanOfficerStore())
}
