import SwiftUI

struct SystemSettingsView: View {
    @Bindable var templateViewModel: TemplateViewModel
    @Bindable var loanConfigViewModel: LoanConfigViewModel
    
    var body: some View {
        Form {
            Section {
                NavigationLink {
                    TemplateListView(viewModel: templateViewModel)
                } label: {
                    settingsRow(title: "Notification Templates", subtitle: "Edit borrower-facing message content")
                }
                NavigationLink {
                    LoanConfigFormView(viewModel: loanConfigViewModel)
                } label: {
                    settingsRow(title: "Loan Configurations", subtitle: "Adjust products and repayment terms")
                }
                NavigationLink {
                    EMISchedulerView()
                } label: {
                    settingsRow(title: "EMI Reminder Schedules", subtitle: "Manage timing and templates for reminders")
                }


            } header: {
                Text("Catalog")
                    .font(.adminSectionHeader)
                    .foregroundStyle(Color.secondary)
                    .textCase(.uppercase)
                    .padding(.leading, 8)
            }
        }
        .navigationTitle("Configure")
        .background(AdminColor.background)
    }
    
    private func settingsRow(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(.lmsHeadline)
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.lmsCaption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.xs)
    }
}
