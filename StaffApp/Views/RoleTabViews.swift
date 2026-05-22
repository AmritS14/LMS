import SwiftUI

struct OfficerTabView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "squareshape.2x2") { LODashboardView() }
            Tab("Queue", systemImage: "tray.full") { LOApplicationsListView() }
            Tab("Alerts", systemImage: "bell") { LONotificationsView() }
            Tab("Profile", systemImage: "person.crop.circle") { StaffProfileView() }
        }
    }
}

struct ManagerTabView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "house.fill") { ManagerDashboardView() }
            Tab("Applications", systemImage: "doc.text") { ManagerApplicationsView() }
            Tab("Analytics", systemImage: "chart.bar.fill") { ReportsView() }
            Tab("Profile", systemImage: "person.circle") { StaffProfileView() }
        }
        .tint(.lmsNavyBlue)
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
}
