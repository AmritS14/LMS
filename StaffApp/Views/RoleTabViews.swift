import SwiftUI

struct RoleTabViews_Preview: PreviewProvider {
    static var previews: some View {
        OfficerTabView()
    }
}

struct OfficerTabView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "squareshape.2x2.fill") { LODashboardView() }
            Tab("Queue", systemImage: "tray.full.fill") { LOApplicationsListView() }
            Tab("Collections", systemImage: "exclamationmark.arrow.circlepath") { LOCollectionsView() }
            Tab("Messages", systemImage: "bubble.left.and.bubble.right.fill") { StaffMessagingView() }
            Tab("Alerts", systemImage: "bell.fill") { LONotificationsView() }
            Tab("Profile", systemImage: "person.crop.circle.fill") { StaffProfileView() }
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
        .environment(SessionStore())
}
