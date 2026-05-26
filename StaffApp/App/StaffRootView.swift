import SwiftUI

struct StaffRootView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var appEnvironment

    @State private var officerStore = LoanOfficerStore()
    @State private var managerStore = ManagerStore()

    var body: some View {
        if let role = session.role {
            switch role {
            case .loanOfficer:
                OfficerTabView()
                    .environment(officerStore)
                    .task {
                        if let appEnvironment {
                            officerStore.configure(environment: appEnvironment, officerID: session.currentUser?.id)
                        }
                    }
            case .manager:
                ManagerTabView()
                    .environment(managerStore)
                    .task {
                        if let appEnvironment {
                            managerStore.configure(environment: appEnvironment)
                        }
                    }
            case .admin: AdminTabView()
            case .borrower: UnsupportedRoleView()
            }
        } else {
            StaffLoginView()
                .task {
                    if let appEnvironment {
                        if let user = await appEnvironment.auth.currentUser {
                            withAnimation {
                                session.currentUser = user
                            }
                        }
                    }
                }
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
