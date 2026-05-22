import SwiftUI

struct StaffRootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        if let role = session.role {
            switch role {
            case .loanOfficer: OfficerTabView()
            case .manager: ManagerTabView()
            case .admin: AdminTabView()
            case .borrower: UnsupportedRoleView()
            }
        } else {
            StaffLoginView()
        }
    }
}

struct UnsupportedRoleView: View {
    var body: some View {
        ContentUnavailableView(
            "Unsupported Role",
            systemImage: "person.crop.circle.badge.exclamationmark",
            description: Text("This app is for Loan Officers, Managers, and Admins.")
        )
    }
}

struct OfficerTabView: View {

    @StateObject private var viewModel = AppViewModel()

    var body: some View {

        NavigationStack(path: $viewModel.navigationPath) {

            TabView {

                // MARK: Dashboard

                DashboardView()
                    .environmentObject(viewModel)
                    .tabItem {
                        Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
                    }

                // MARK: Applications

                AllApplicationsView()
                    .environmentObject(viewModel)
                    .tabItem {
                        Label("Applications", systemImage: "doc.text.fill")
                    }

                // MARK: Communications

                CommunicationsMainView()
                    .environmentObject(viewModel)
                    .tabItem {
                        Label("Messages", systemImage: "message.fill")
                    }

                // MARK: Recovery

                RecoveryManagementView()
                    .environmentObject(viewModel)
                    .tabItem {
                        Label("Recovery", systemImage: "arrow.uturn.backward.circle.fill")
                    }

                // MARK: Notifications

                NotificationsView()
                    .environmentObject(viewModel)
                    .tabItem {
                        Label("Alerts", systemImage: "bell.badge.fill")
                    }
            }
            .tint(.blue)
            .navigationDestination(for: AppDestination.self) { destination in

                switch destination {

                case .loanReview:

                    LoanReviewView()
                        .environmentObject(viewModel)

                case .recovery,
                     .recoveryManagement:

                    RecoveryManagementView()
                        .environmentObject(viewModel)

                case .communications,
                     .messages:

                    CommunicationsMainView()
                        .environmentObject(viewModel)

                case .notifications:

                    NotificationsView()
                        .environmentObject(viewModel)

                case .allapplications:

                    AllApplicationsView()
                        .environmentObject(viewModel)

                case .documents:

                    DocumentsView()
                        .environmentObject(viewModel)

                case .fraudAlerts:

                    FraudAlertsView()
                        .environmentObject(viewModel)
                }
            }
        }
    }
}

// MARK: - Placeholder Screens

struct RecoveryManagementView: View {

    var body: some View {

        NavigationView {

            VStack(spacing: 16) {

                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)

                Text("Recovery Management")
                    .font(.title2.bold())

                Text("Manage overdue borrowers and collections.")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Recovery")
        }
    }
}

struct NotificationsView: View {

    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {

        NavigationView {

            List(viewModel.notifications) { notification in

                VStack(alignment: .leading, spacing: 6) {

                    HStack {

                        Image(systemName: notification.type.icon)
                            .foregroundStyle(notification.type.color)

                        Text(notification.title)
                            .font(.headline)

                        Spacer()

                        Text(
                            AppFormatters.timeAgo(
                                notification.timestamp
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Text(notification.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Notifications")
        }
    }
}

struct DocumentsView: View {

    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {

        NavigationView {

            List(viewModel.digitalDocuments) { document in

                HStack(spacing: 14) {

                    Image(systemName: document.icon)
                        .font(.title2)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 4) {

                        Text(document.title)
                            .font(.headline)

                        Text(document.fileSize)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if document.isSigned {

                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Documents")
        }
    }
}

struct FraudAlertsView: View {

    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {

        NavigationView {

            List {

                ForEach(
                    viewModel.filteredApplications.filter {
                        $0.fraudFlag
                    }
                ) { application in

                    VStack(alignment: .leading, spacing: 8) {

                        HStack {

                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundStyle(.red)

                            Text(application.borrowerName)
                                .font(.headline)
                        }

                        Text(application.loanType)
                            .foregroundStyle(.secondary)

                        Text(
                            "Credit Score: \(application.creditScore)"
                        )
                        .font(.caption)
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Fraud Alerts")
        }
    }
}
struct ManagerTabView : View {
    var body: some View {
        Text("Officer Tab View")
    }
}
struct AdminTabView : View {
    var body: some View {
        Text("Officer Tab View")
    }
}
struct StaffLoginView : View {
    var body: some View {
        Text("Officer Tab View")
    }
}
