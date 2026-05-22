//
//  AdminTabView.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI

// MARK: - Admin Tab Enum

/// Represents the four main navigation tabs in the Admin Module.
enum AdminTab: String, CaseIterable, Identifiable {
    case overview = "Dashboard"
    case users = "Users"
    case loanConfig = "Loans"
    case notifications = "Templates"

    var id: String { rawValue }

    /// SF Symbol for the tab icon.
    var systemImage: String {
        switch self {
        case .overview: "square.grid.2x2.fill"
        case .users: "person.2.fill"
        case .loanConfig: "chart.bar.fill" // From screenshot Loans icon
        case .notifications: "folder.fill" // From screenshot Templates icon
        }
    }
}

// MARK: - Admin Tab View

/// The root view of the Admin Module.
/// Uses a TabView containing four NavigationStacks,
/// one for each feature module.
struct AdminTabView: View {
    @State private var selectedTab: AdminTab = .overview
    @State private var dashboardVM = DashboardViewModel()
    @State private var userVM = UserManagementViewModel()
    @State private var loanConfigVM = LoanConfigViewModel()
    @State private var templateVM = TemplateViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Overview Tab (Dashboard)
            Tab(AdminTab.overview.rawValue, systemImage: AdminTab.overview.systemImage, value: .overview) {
                NavigationStack {
                    DashboardView(viewModel: dashboardVM, userVM: userVM)
                }
                .tint(AdminColor.accent)
                .accentColor(AdminColor.accent)
            }

            // MARK: - Users Tab
            Tab(AdminTab.users.rawValue, systemImage: AdminTab.users.systemImage, value: .users) {
                NavigationStack {
                    UserListView(viewModel: userVM)
                }
                .tint(AdminColor.accent)
                .accentColor(AdminColor.accent)
            }

            // MARK: - Loans Tab
            Tab(AdminTab.loanConfig.rawValue, systemImage: AdminTab.loanConfig.systemImage, value: .loanConfig) {
                NavigationStack {
                    LoanConfigFormView(viewModel: loanConfigVM)
                }
                .tint(AdminColor.accent)
                .accentColor(AdminColor.accent)
            }

            // MARK: - Templates Tab
            Tab(AdminTab.notifications.rawValue, systemImage: AdminTab.notifications.systemImage, value: .notifications) {
                NavigationStack {
                    TemplateListView(viewModel: templateVM)
                        .navigationDestination(for: NotificationTemplate.self) { template in
                            TemplateEditorView(viewModel: templateVM)
                                .onAppear {
                                    templateVM.selectTemplate(template)
                                }
                        }
                }
                .tint(AdminColor.accent)
                .accentColor(AdminColor.accent)
            }
        }
        .tint(AdminColor.accent)
        .accentColor(AdminColor.accent)
    }
}

#Preview {
    AdminTabView()
}
