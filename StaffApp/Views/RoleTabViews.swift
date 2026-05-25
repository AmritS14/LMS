import SwiftUI

// MARK: - Loan Officer Root View
// Mirrors the standalone loan-officer app: a single NavigationStack with
// DashboardView as root. All screens are pushed, no tab bar.

struct OfficerTabView: View {
    @State private var viewModel = AppViewModel()

    var body: some View {
        ContentView()
            .environment(viewModel)
        
    }
}
//#Preview {
//       ContentView()
//           .environment(AppViewModel())
//   }

// MARK: - Manager Tab View

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

// MARK: - Admin Tab View

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
