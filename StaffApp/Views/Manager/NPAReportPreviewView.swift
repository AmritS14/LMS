import SwiftUI

struct NPAReportPreviewView: View {
    let report: ReportItem
    let data: NPAReportData

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
                    Text("Generated \(report.dateText) • NPA & Risk Analysis")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Spacing.m)

                Divider().padding(.horizontal, Spacing.m)

                // KPI Grid
                HStack(spacing: Spacing.m) {
                    ReportKPICard(title: "NPA Loans", value: "\(data.totalNPALoans)", icon: "exclamationmark.triangle.fill", color: .lmsDanger)
                    ReportKPICard(title: "NPA Ratio", value: String(format: "%.1f%%", data.npaRatio * 100), icon: "chart.pie.fill", color: .lmsWarning)
                }
                .padding(.horizontal, Spacing.m)

                HStack(spacing: Spacing.m) {
                    ReportKPICard(title: "NPA Amount", value: Formatting.currency(data.totalNPAAmount), icon: "indianrupeesign.circle.fill", color: .lmsDanger)
                    ReportKPICard(title: "Overdue EMIs", value: "\(data.totalOverdueEMIs)", icon: "clock.badge.exclamationmark.fill", color: .lmsWarning)
                }
                .padding(.horizontal, Spacing.m)

                // NPA Overview
                ReportSectionCard(title: "NPA Overview") {
                    ReportDetailRow(title: "Total NPA Loans", value: "\(data.totalNPALoans)")
                    ReportDetailRow(title: "NPA Ratio", value: String(format: "%.2f%%", data.npaRatio * 100))
                    ReportDetailRow(title: "Total NPA Outstanding", value: Formatting.currency(data.totalNPAAmount))
                    ReportDetailRow(title: "Total Overdue EMIs", value: "\(data.totalOverdueEMIs)")
                    ReportDetailRow(title: "Total Overdue Amount", value: Formatting.currency(data.overdueAmount), isLast: true)
                }

                // Risk Segmentation
                ReportSectionCard(title: "Risk Segmentation") {
                    riskRow(label: "Critical — > 90 days overdue", count: data.criticalAccounts, tone: .danger)
                    riskRow(label: "High Risk — 30 to 90 days", count: data.highRiskAccounts, tone: .warning)
                    riskRow(label: "Medium Risk — < 30 days", count: data.mediumRiskAccounts, tone: .info, isLast: true)
                }
            }
            .padding(.vertical, Spacing.m)
        }
        .background(Color.lmsBackground)
        .navigationTitle("NPA Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func riskRow(label: String, count: Int, tone: StatusBadge.Tone, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                StatusBadge("\(count) accounts", tone: tone, size: .small)
            }
            .padding(Spacing.m)
            if !isLast { Divider().padding(.leading, Spacing.m) }
        }
    }
}
