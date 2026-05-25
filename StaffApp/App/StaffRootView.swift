import SwiftUI

struct StaffRootView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var appEnvironment

    var body: some View {
        if let role = session.role {
            switch role {
            case .loanOfficer:
                OfficerTabView()
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
