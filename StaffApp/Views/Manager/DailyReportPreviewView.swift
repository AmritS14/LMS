import SwiftUI

struct DailyReportPreviewView: View {
    let report: ReportItem
    let data: DailyReportData

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
                    Text("Generated \(report.dateText) • Operations Focus")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Spacing.m)

                Divider().padding(.horizontal, Spacing.m)

                // KPI Grid
                HStack(spacing: Spacing.m) {
                    ReportKPICard(title: "Loans Disbursed", value: "\(data.loansApproved)", icon: "doc.text.fill", color: .lmsAccent)
                    ReportKPICard(title: "Amount Disbursed", value: Formatting.currency(data.totalDisbursedToday), icon: "indianrupeesign.circle.fill", color: .lmsSuccess)
                }
                .padding(.horizontal, Spacing.m)

                HStack(spacing: Spacing.m) {
                    ReportKPICard(title: "EMI Collected", value: Formatting.currency(data.emiCollected), icon: "arrow.down.circle.fill", color: .lmsSuccess)
                    ReportKPICard(title: "Pending Collections", value: Formatting.currency(data.pendingCollections), icon: "clock.fill", color: .lmsWarning)
                }
                .padding(.horizontal, Spacing.m)

                // Loan Summary
                ReportSectionCard(title: "Loan Summary") {
                    ReportDetailRow(title: "Loans Disbursed Today", value: "\(data.loansApproved)")
                    ReportDetailRow(title: "Amount Disbursed Today", value: Formatting.currency(data.totalDisbursedToday))
                    ReportDetailRow(title: "Total Active Loans", value: "\(data.activeLoans)", isLast: true)
                }

                // Customer Activity
                ReportSectionCard(title: "Customer Activity") {
                    ReportDetailRow(title: "New Customers Today", value: "\(data.newCustomers)")
                    ReportDetailRow(title: "Missed Payments Today", value: "\(data.missedPayments)", isLast: true)
                }
            }
            .padding(.vertical, Spacing.m)
        }
        .background(Color.lmsBackground)
        .navigationTitle("Daily Report")
        .navigationBarTitleDisplayMode(.inline)
    }
}
