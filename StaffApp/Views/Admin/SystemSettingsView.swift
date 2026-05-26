import SwiftUI

struct SystemSettingsView: View {
    @Bindable var templateViewModel: TemplateViewModel
    @Bindable var loanConfigViewModel: LoanConfigViewModel

    @State private var enableFraudAlerts = true
    @State private var enableAutoEscalation = true
    @State private var enableRetentionLock = true

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
            } header: {
                Text("Catalog")
                    .font(.lmsTitle3)
                    .textCase(nil)
            }

            Section {
                Toggle("Fraud alerts", isOn: $enableFraudAlerts)
                Toggle("Auto escalation", isOn: $enableAutoEscalation)
                Toggle("Retention lock", isOn: $enableRetentionLock)
            } header: {
                Text("Automation")
                    .font(.lmsTitle3)
                    .textCase(nil)
            }

            Section {
                NavigationLink("GDPR / Data Retention") { Text("Coming soon") }
                NavigationLink("Audit Policy") { Text("Coming soon") }
            } header: {
                Text("Compliance")
                    .font(.lmsTitle3)
                    .textCase(nil)
            }
        }
        .navigationTitle("Settings")
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
