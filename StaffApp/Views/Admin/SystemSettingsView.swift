import SwiftUI

struct SystemSettingsView: View {
    @Bindable var templateViewModel: TemplateViewModel
    @Bindable var loanConfigViewModel: LoanConfigViewModel
    
    var body: some View {
        Form {
            Section {
                NavigationLink {
                    LoanConfigFormView(viewModel: loanConfigViewModel)
                } label: {
                    settingsRow(title: "Loan Configurations", subtitle: "Adjust products and repayment terms")
                }
                NavigationLink {
                    ArchiveListView()
                } label: {
                    settingsRow(title: "Loan Archives", subtitle: "Manage historical and closed loan records")
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
