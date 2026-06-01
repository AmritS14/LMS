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
            } header: {
                Text("Catalog")
                    .font(.lmsTitle3)
                    .textCase(nil)
            }
            
            Section {
                NavigationLink {
                    LoanConfigFormView(viewModel: loanConfigViewModel)
                } label: {
                    settingsRow(title: "Loan Configurations", subtitle: "Adjust products and repayment terms")
                }
            }

            Section {
                NavigationLink {
                    EMISchedulerView()
                } label: {
                    settingsRow(title: "EMI Reminder Schedules", subtitle: "Manage timing and templates for reminders")
                }
            }

            Section {
                NavigationLink {
                    ArchiveListView()
                } label: {
                    settingsRow(title: "Loan Archives", subtitle: "Manage historical and closed loan records")
                }
            }
            
            Section {
                NavigationLink {
                    AuditListView()
                } label: {
                    settingsRow(title: "Audit Trail", subtitle: "View system-wide compliance logs")
                }
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
