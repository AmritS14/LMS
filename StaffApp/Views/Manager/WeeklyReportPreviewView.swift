import SwiftUI

struct WeeklyReportPreviewView: View {
    let report: ReportItem
    let data: WeeklyReportData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                // Header
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack {
                        StatusBadge(report.format.rawValue.uppercased(), tone: report.format == .pdf ? .danger : .success, size: .medium)
                        StatusBadge(report.status.rawValue, tone: report.status.tone, icon: report.status.icon, size: .medium)
                    }
                    Text(report.name)
                        .font(.lmsTitle2)
                    Text("Generated \(report.dateText) • Trends Focus")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Spacing.m)

                Divider().padding(.horizontal, Spacing.m)

                // KPI Grid
                HStack(spacing: Spacing.m) {
                    ReportKPICard(title: "Loan Growth", value: String(format: "%+.1f%%", data.weeklyLoanGrowth), icon: "chart.line.uptrend.xyaxis", color: data.weeklyLoanGrowth >= 0 ? .lmsSuccess : .lmsDanger)
                    ReportKPICard(title: "Recovery Perf.", value: String(format: "%.1f%%", data.recoveryPerformance), icon: "arrow.triangle.2.circlepath", color: .lmsSuccess)
                }
                .padding(.horizontal, Spacing.m)

                // Repayment Collection Report
                ReportSectionCard(title: "Repayment Collection Report") {
                    ReportDetailRow(title: "Total Repayment Collected", value: Formatting.currency(data.totalRepaymentCollected))
                    ReportDetailRow(title: "Number of Defaults", value: "\(data.numberOfDefaults)")
                    ReportDetailRow(title: "Top Paying Borrowers", value: "\(data.topPayingCustomers)", isLast: true)
                }

                // Overdue / Defaulters — snapshotted at generation time
                ReportSectionCard(title: "Overdue / Defaulters") {
                    if data.overdueAccounts.isEmpty {
                        ReportDetailRow(title: "No overdue accounts", value: "—", isLast: true)
                    } else {
                        ForEach(Array(data.overdueAccounts.enumerated()), id: \.element.id) { index, acct in
                            ReportDetailRow(
                                title: acct.title,
                                value: acct.loanReferenceCode,
                                isLast: index == data.overdueAccounts.count - 1
                            )
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.m)
        }
        .background(Color.lmsBackground)
        .navigationTitle("Weekly Report")
        .navigationBarTitleDisplayMode(.inline)
    }
}
