import re

with open('/Users/shailesh99394gmail.com/Downloads/LMS/StaffApp/Views/Admin/Dashboard/View/DistributionDetailsView.swift', 'r') as f:
    content = f.read()

# Replace body structure
body_old = """    var body: some View {
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                // Main Highlight Header Card
                mainHeaderCard

                // 1. Loan Type Distribution breakdown
                loanDistributionSection

                // 3. Application Status summary
                applicationStatusSection
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.xl)
        }
        .background(AdminColor.background)"""

body_new = """    var body: some View {
        List {
            mainHeaderCard
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.bottom, Spacing.m)

            loanDistributionSection
            applicationStatusSection
        }
        .listStyle(.insetGrouped)"""
content = content.replace(body_old, body_new)

# Replace loanDistributionSection
loan_old = """    private var loanDistributionSection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            SectionHeaderView(title: "Loan Portfolio Breakdown", systemImage: "chart.bar.fill")
            
            Chart(viewModel.snapshot.loanDistribution) { item in
                BarMark(
                    x: .value("Category", item.category),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(by: .value("Category", item.category))
                .cornerRadius(4)
                .annotation(position: .top, alignment: .center) {
                    VStack(spacing: 2) {
                        Text(item.amount.formattedLakhs)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(String(format: "%.1f%%", item.percentage))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 220)
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel() {
                        if let category = value.as(String.self) {
                            Text(category)
                                .font(.caption2)
                        }
                    }
                }
            }
            .padding(AdminSpacing.cardPadding)
            .padding(.top, Spacing.m)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
    }"""
loan_new = """    private var loanDistributionSection: some View {
        Section {
            Chart(viewModel.snapshot.loanDistribution) { item in
                BarMark(
                    x: .value("Category", item.category),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(by: .value("Category", item.category))
                .cornerRadius(4)
                .annotation(position: .top, alignment: .center) {
                    VStack(spacing: 2) {
                        Text(item.amount.formattedLakhs)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(String(format: "%.1f%%", item.percentage))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 220)
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel() {
                        if let category = value.as(String.self) {
                            Text(category)
                                .font(.caption2)
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.m)
        } header: {
            Text("Loan Portfolio Breakdown").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
        }
    }"""
content = content.replace(loan_old, loan_new)

# Replace applicationStatusSection
app_old = """    private var applicationStatusSection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            SectionHeaderView(title: "Active Loans & Applications", systemImage: "folder.badge.gearshape")
            
            VStack(spacing: Spacing.s) {
                NavigationLink(destination: DemographicUserListView(role: nil, viewModel: userVM)) {
                    statRow(title: "Total Users", count: viewModel.snapshot.stats.totalUser, systemImage: "")
                }
                .buttonStyle(.plain)
                
                Divider()
                
                NavigationLink(destination: DashboardLoansListView(title: "Active Loans", applications: viewModel.snapshot.recentApplications.filter { $0.status == .approved })) {
                    statRow(title: "Active Loans", count: viewModel.snapshot.stats.activeLoans, systemImage: "")
                }
                .buttonStyle(.plain)
                
                Divider()
                
                NavigationLink(destination: DashboardLoansListView(title: "Applications", applications: viewModel.snapshot.recentApplications)) {
                    statRow(title: "Applications", count: viewModel.snapshot.stats.applications, systemImage: "")
                }
                .buttonStyle(.plain)
            }
            .padding(AdminSpacing.cardPadding)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
    }"""
app_new = """    private var applicationStatusSection: some View {
        Section {
            NavigationLink(destination: DemographicUserListView(role: nil, viewModel: userVM)) {
                statRow(title: "Total Users", count: viewModel.snapshot.stats.totalUser, systemImage: "")
            }
            
            NavigationLink(destination: DashboardLoansListView(title: "Active Loans", applications: viewModel.snapshot.recentApplications.filter { $0.status == .approved })) {
                statRow(title: "Active Loans", count: viewModel.snapshot.stats.activeLoans, systemImage: "")
            }
            
            NavigationLink(destination: DashboardLoansListView(title: "Applications", applications: viewModel.snapshot.recentApplications)) {
                statRow(title: "Applications", count: viewModel.snapshot.stats.applications, systemImage: "")
            }
        } header: {
            Text("Active Loans & Applications").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
        }
    }"""
content = content.replace(app_old, app_new)

# Replace DemographicUserListView body
demo_old = """    var body: some View {
        ScrollView {
            LazyVStack(spacing: AdminSpacing.cardGap) {
                if filteredUsers.isEmpty {
                    Text("No users found.")
                        .font(.lmsSubheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 20)
                } else {
                    ForEach(filteredUsers) { user in
                        NavigationLink(destination: UserDetailView(user: user, viewModel: viewModel)) {
                            UserRowView(user: user, userVM: viewModel)
                                .padding(AdminSpacing.cardPadding)
                                .background(
                                    AdminColor.cardBackground,
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.xl)
        }
        .background(AdminColor.background)
        .navigationTitle(role?.displayName ?? "Users")
        .navigationBarTitleDisplayMode(.inline)
    }"""
demo_new = """    var body: some View {
        List {
            if filteredUsers.isEmpty {
                Text("No users found.")
                    .font(.lmsSubheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            } else {
                ForEach(filteredUsers) { user in
                    NavigationLink(destination: UserDetailView(user: user, viewModel: viewModel)) {
                        UserRowView(user: user, userVM: viewModel)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(role?.displayName ?? "Users")
        .navigationBarTitleDisplayMode(.inline)
    }"""
content = content.replace(demo_old, demo_new)


with open('/Users/shailesh99394gmail.com/Downloads/LMS/StaffApp/Views/Admin/Dashboard/View/DistributionDetailsView.swift', 'w') as f:
    f.write(content)

