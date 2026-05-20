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
            Tab("Portfolio", systemImage: "chart.pie") { PortfolioDashboardView() }
            Tab("Approvals", systemImage: "checkmark.seal") { ApprovalsQueueView() }
            Tab("Reports", systemImage: "doc.text.magnifyingglass") { ReportsView() }
            Tab("Products", systemImage: "slider.horizontal.3") { ProductConfigView() }
            Tab("Profile", systemImage: "person.crop.circle") { StaffProfileView() }
        }
    }
}



#Preview {
    AdminTabView()
        .environment(SessionStore())
}
