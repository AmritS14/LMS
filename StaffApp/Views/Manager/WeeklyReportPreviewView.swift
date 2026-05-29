import SwiftUI

struct WeeklyReportPreviewView: View {
    let report: ReportItem
    let data = MockManagerData.weeklyReportData()

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
                    ReportKPICard(title: "Loan Growth", value: "+\(String(format: "%.1f", data.weeklyLoanGrowth))%", icon: "chart.line.uptrend.xyaxis", color: .lmsAccent)
                    ReportKPICard(title: "Recovery Perf.", value: "\(String(format: "%.1f", data.recoveryPerformance))%", icon: "arrow.triangle.2.circlepath", color: .lmsSuccess)
                }
                .padding(.horizontal, Spacing.m)

                // Repayment Collection Report
                ReportSectionCard(title: "Repayment Collection Report") {
                    ReportDetailRow(title: "Total Repayment Collected", value: Formatting.currency(data.totalRepaymentCollected))
                    ReportDetailRow(title: "Number of Defaults", value: "\(data.numberOfDefaults)")
                    ReportDetailRow(title: "Top Paying Customers", value: "\(data.topPayingCustomers)", isLast: true)
                }

                // Overdue / Defaulters Report
                ReportSectionCard(title: "Overdue / Defaulters") {
                    let customers = MockManagerData.overdueCustomers()
                    ForEach(Array(customers.enumerated()), id: \.element.id) { index, customer in
                        OverdueCustomerRow(customer: customer, isLast: index == customers.count - 1)
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
