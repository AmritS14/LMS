import SwiftUI
import Charts

struct MonthlyReportPreviewView: View {
    let report: ReportItem
    let data: MonthlyReportData

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
                    Text("Generated \(report.dateText) • Business Performance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Spacing.m)

                Divider().padding(.horizontal, Spacing.m)

                // Main KPIs
                HStack(spacing: Spacing.m) {
                    ReportKPICard(title: "Interest Earned", value: Formatting.currency(data.interestEarned), icon: "indianrupeesign.circle.fill", color: .lmsSuccess)
                    ReportKPICard(title: "Total Profit", value: Formatting.currency(data.totalProfit), icon: "chart.line.uptrend.xyaxis", color: .lmsAccent)
                }
                .padding(.horizontal, Spacing.m)

                // Revenue / Profit Report
                ReportSectionCard(title: "Revenue & Profit") {
                    ReportDetailRow(title: "Interest Earned", value: Formatting.currency(data.interestEarned))
                    ReportDetailRow(title: "Processing Fees", value: Formatting.currency(data.processingFees))
                    ReportDetailRow(title: "Penalties Collected", value: Formatting.currency(data.penaltyCollected), isLast: true)
                }

                // Loan Performance
                ReportSectionCard(title: "Loan Performance") {
                    ReportDetailRow(title: "Total Distributed", value: Formatting.currency(data.totalDistributed))
                    ReportDetailRow(title: "Loan Recovery Rate", value: String(format: "%.1f%%", data.loanRecoveryRate))
                    ReportDetailRow(title: "Best Category", value: data.bestPerformingCategory, isLast: true)
                }

                // Loan Type Analytics (Charts)
                if !data.loanTypeAnalytics.isEmpty {
                    ReportSectionCard(title: "Loan Type Analytics") {
                        VStack(alignment: .leading, spacing: Spacing.l) {
                            Chart(data.loanTypeAnalytics) { item in
                                SectorMark(
                                    angle: .value("Percentage", item.percentage),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(item.color)
                                .annotation(position: .overlay) {
                                    Text("\(Int(item.percentage))%")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(height: 200)

                            VStack(alignment: .leading, spacing: Spacing.s) {
                                ForEach(data.loanTypeAnalytics) { item in
                                    HStack {
                                        Circle()
                                            .fill(item.color)
                                            .frame(width: 8, height: 8)
                                        Text(item.typeName)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(String(format: "%.0f%%", item.percentage))
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                            .padding(.top, Spacing.s)
                        }
                        .padding(Spacing.m)
                    }
                }
            }
            .padding(.vertical, Spacing.m)
        }
        .background(Color.lmsBackground)
        .navigationTitle("Monthly Report")
        .navigationBarTitleDisplayMode(.inline)
    }
}
