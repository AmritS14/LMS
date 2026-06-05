import UIKit
import Foundation

enum ReportGenerator {

    // MARK: Directory

    static var reportsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("LMSReports", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func formatFileSize(_ bytes: Int) -> String {
        if bytes >= 1_048_576 { return String(format: "%.1f MB", Double(bytes) / 1_048_576) }
        if bytes >= 1_024 { return "\(bytes / 1_024) KB" }
        return "\(bytes) B"
    }

    // MARK: PDF

    static func generatePDF(snapshot: ReportSnapshot, name: String) throws -> URL {
        let safe = sanitize(name)
        let url = reportsDirectory.appendingPathComponent("\(safe)_\(timestamp()).pdf")

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = drawHeader(name: name, pageRect: pageRect)
            switch snapshot {
            case .daily(let d):   y = drawDaily(d, y: y, pageRect: pageRect)
            case .weekly(let d):  y = drawWeekly(d, y: y, pageRect: pageRect)
            case .monthly(let d): y = drawMonthly(d, y: y, pageRect: pageRect)
            case .npa(let d):     y = drawNPA(d, y: y, pageRect: pageRect)
            }
            drawFooter(y: y, pageRect: pageRect)
        }
        try data.write(to: url)
        return url
    }

    // MARK: CSV

    static func generateCSV(snapshot: ReportSnapshot, name: String) throws -> URL {
        let safe = sanitize(name)
        let url = reportsDirectory.appendingPathComponent("\(safe)_\(timestamp()).csv")
        let csv: String
        switch snapshot {
        case .daily(let d):   csv = dailyCSV(d, name: name)
        case .weekly(let d):  csv = weeklyCSV(d, name: name)
        case .monthly(let d): csv = monthlyCSV(d, name: name)
        case .npa(let d):     csv = npaCSV(d, name: name)
        }
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: PDF — Drawing Helpers

    private static let margin: CGFloat = 40
    private static let lineHeight: CGFloat = 22
    private static let sectionSpacing: CGFloat = 16

    private static func drawHeader(name: String, pageRect: CGRect) -> CGFloat {
        let w = pageRect.width
        // Blue banner
        let bannerRect = CGRect(x: 0, y: 0, width: w, height: 80)
        UIColor(red: 0.13, green: 0.35, blue: 0.73, alpha: 1).setFill()
        UIBezierPath(rect: bannerRect).fill()

        "LMS BRANCH MANAGER".draw(
            in: CGRect(x: margin, y: 12, width: w - margin * 2, height: 28),
            withAttributes: attr(.white, size: 18, weight: .bold))
        name.draw(
            in: CGRect(x: margin, y: 44, width: w - margin * 2, height: 22),
            withAttributes: attr(.white, size: 13, weight: .regular))

        return 96
    }

    private static func drawFooter(y: CGFloat, pageRect: CGRect) {
        let footerY = pageRect.height - 32
        UIColor.lightGray.setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin, y: footerY))
        line.addLine(to: CGPoint(x: pageRect.width - margin, y: footerY))
        line.lineWidth = 0.5
        line.stroke()

        let text = "Generated \(Date.now.formatted(.dateTime.day().month().year().hour().minute())) • LMS System"
        text.draw(in: CGRect(x: margin, y: footerY + 6, width: pageRect.width - margin * 2, height: 18),
                  withAttributes: attr(.gray, size: 9))
    }

    @discardableResult
    private static func drawSectionHeader(_ title: String, y: CGFloat, pageRect: CGRect) -> CGFloat {
        let rect = CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: 26)
        UIColor(red: 0.93, green: 0.95, blue: 0.99, alpha: 1).setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 4).fill()
        title.uppercased().draw(in: rect.insetBy(dx: 8, dy: 4),
                                withAttributes: attr(UIColor(red: 0.13, green: 0.35, blue: 0.73, alpha: 1), size: 10, weight: .semibold))
        return y + 26 + 6
    }

    @discardableResult
    private static func drawRow(label: String, value: String, y: CGFloat, pageRect: CGRect, alternate: Bool = false) -> CGFloat {
        let rowRect = CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: lineHeight)
        if alternate {
            UIColor(white: 0.97, alpha: 1).setFill()
            UIBezierPath(rect: rowRect).fill()
        }
        label.draw(in: CGRect(x: margin + 8, y: y + 3, width: 240, height: 18),
                   withAttributes: attr(.darkGray, size: 11))
        value.draw(in: CGRect(x: pageRect.width - margin - 160, y: y + 3, width: 152, height: 18),
                   withAttributes: attr(.black, size: 11, weight: .semibold, alignment: .right))
        return y + lineHeight
    }

    // MARK: PDF — Per-Report Drawing

    @discardableResult
    private static func drawDaily(_ d: DailyReportData, y: CGFloat, pageRect: CGRect) -> CGFloat {
        var y = y + sectionSpacing
        y = drawSectionHeader("Key Performance Indicators", y: y, pageRect: pageRect)
        y = drawRow(label: "Loans Disbursed Today", value: "\(d.loansApproved)", y: y, pageRect: pageRect)
        y = drawRow(label: "Amount Disbursed Today", value: inr(d.totalDisbursedToday), y: y, pageRect: pageRect, alternate: true)
        y = drawRow(label: "EMI Collected Today", value: inr(d.emiCollected), y: y, pageRect: pageRect)
        y = drawRow(label: "Pending Collections", value: inr(d.pendingCollections), y: y, pageRect: pageRect, alternate: true)

        y += sectionSpacing
        y = drawSectionHeader("Activity Summary", y: y, pageRect: pageRect)
        y = drawRow(label: "Active Loans (Total)", value: "\(d.activeLoans)", y: y, pageRect: pageRect)
        y = drawRow(label: "New Customers Today", value: "\(d.newCustomers)", y: y, pageRect: pageRect, alternate: true)
        y = drawRow(label: "Missed Payments Today", value: "\(d.missedPayments)", y: y, pageRect: pageRect)
        return y
    }

    @discardableResult
    private static func drawWeekly(_ d: WeeklyReportData, y: CGFloat, pageRect: CGRect) -> CGFloat {
        var y = y + sectionSpacing
        y = drawSectionHeader("Weekly Performance", y: y, pageRect: pageRect)
        let growthStr = String(format: "%+.1f%%", d.weeklyLoanGrowth)
        y = drawRow(label: "Loan Growth (WoW)", value: growthStr, y: y, pageRect: pageRect)
        y = drawRow(label: "Recovery Performance", value: pct(d.recoveryPerformance), y: y, pageRect: pageRect, alternate: true)

        y += sectionSpacing
        y = drawSectionHeader("Repayment Collection", y: y, pageRect: pageRect)
        y = drawRow(label: "Total Collected", value: inr(d.totalRepaymentCollected), y: y, pageRect: pageRect)
        y = drawRow(label: "Number of Defaults", value: "\(d.numberOfDefaults)", y: y, pageRect: pageRect, alternate: true)
        y = drawRow(label: "Top Paying Borrowers", value: "\(d.topPayingCustomers)", y: y, pageRect: pageRect)

        if !d.overdueAccounts.isEmpty {
            y += sectionSpacing
            y = drawSectionHeader("Overdue / Defaulters", y: y, pageRect: pageRect)
            for (i, acct) in d.overdueAccounts.enumerated() {
                y = drawRow(label: acct.title, value: acct.loanReferenceCode, y: y, pageRect: pageRect, alternate: i.isMultiple(of: 2))
            }
        }
        return y
    }

    @discardableResult
    private static func drawMonthly(_ d: MonthlyReportData, y: CGFloat, pageRect: CGRect) -> CGFloat {
        var y = y + sectionSpacing
        y = drawSectionHeader("Revenue & Profit", y: y, pageRect: pageRect)
        y = drawRow(label: "Interest Earned", value: inr(d.interestEarned), y: y, pageRect: pageRect)
        y = drawRow(label: "Total Revenue", value: inr(d.monthlyRevenue), y: y, pageRect: pageRect, alternate: true)
        y = drawRow(label: "Total Profit", value: inr(d.totalProfit), y: y, pageRect: pageRect)
        y = drawRow(label: "Penalties Collected", value: inr(d.penaltyCollected), y: y, pageRect: pageRect, alternate: true)
        y = drawRow(label: "Processing Fees", value: inr(d.processingFees), y: y, pageRect: pageRect)

        y += sectionSpacing
        y = drawSectionHeader("Loan Performance", y: y, pageRect: pageRect)
        y = drawRow(label: "Total Distributed", value: inr(d.totalDistributed), y: y, pageRect: pageRect)
        y = drawRow(label: "Recovery Rate", value: pct(d.loanRecoveryRate), y: y, pageRect: pageRect, alternate: true)
        y = drawRow(label: "Best Category", value: d.bestPerformingCategory, y: y, pageRect: pageRect)

        if !d.loanTypeAnalytics.isEmpty {
            y += sectionSpacing
            y = drawSectionHeader("Loan Type Breakdown", y: y, pageRect: pageRect)
            for (i, item) in d.loanTypeAnalytics.enumerated() {
                y = drawRow(label: item.typeName, value: String(format: "%.0f%%", item.percentage),
                            y: y, pageRect: pageRect, alternate: i.isMultiple(of: 2))
            }
        }
        return y
    }

    @discardableResult
    private static func drawNPA(_ d: NPAReportData, y: CGFloat, pageRect: CGRect) -> CGFloat {
        var y = y + sectionSpacing
        y = drawSectionHeader("NPA Overview", y: y, pageRect: pageRect)
        y = drawRow(label: "Total NPA Loans", value: "\(d.totalNPALoans)", y: y, pageRect: pageRect)
        y = drawRow(label: "NPA Ratio", value: pct(d.npaRatio * 100), y: y, pageRect: pageRect, alternate: true)
        y = drawRow(label: "Total NPA Amount", value: inr(d.totalNPAAmount), y: y, pageRect: pageRect)

        y += sectionSpacing
        y = drawSectionHeader("Overdue EMI Breakdown", y: y, pageRect: pageRect)
        y = drawRow(label: "Total Overdue EMIs", value: "\(d.totalOverdueEMIs)", y: y, pageRect: pageRect)
        y = drawRow(label: "Overdue Amount", value: inr(d.overdueAmount), y: y, pageRect: pageRect, alternate: true)

        y += sectionSpacing
        y = drawSectionHeader("Risk Segmentation", y: y, pageRect: pageRect)
        y = drawRow(label: "Critical (> 90 days)", value: "\(d.criticalAccounts)", y: y, pageRect: pageRect)
        y = drawRow(label: "High Risk (30–90 days)", value: "\(d.highRiskAccounts)", y: y, pageRect: pageRect, alternate: true)
        y = drawRow(label: "Medium Risk (< 30 days)", value: "\(d.mediumRiskAccounts)", y: y, pageRect: pageRect)
        return y
    }

    // MARK: CSV Builders

    private static func csvHeader(_ name: String) -> String {
        "LMS Branch Manager Report\n\"\(name)\"\nGenerated,\"\(Date.now.formatted())\"\n\n"
    }

    private static func dailyCSV(_ d: DailyReportData, name: String) -> String {
        var s = csvHeader(name)
        s += "KEY PERFORMANCE INDICATORS\nMetric,Value\n"
        s += "Loans Disbursed Today,\(d.loansApproved)\n"
        s += "Amount Disbursed Today,\"\(inr(d.totalDisbursedToday))\"\n"
        s += "EMI Collected Today,\"\(inr(d.emiCollected))\"\n"
        s += "Pending Collections,\"\(inr(d.pendingCollections))\"\n\n"
        s += "ACTIVITY SUMMARY\nMetric,Value\n"
        s += "Active Loans (Total),\(d.activeLoans)\n"
        s += "New Customers Today,\(d.newCustomers)\n"
        s += "Missed Payments Today,\(d.missedPayments)\n"
        return s
    }

    private static func weeklyCSV(_ d: WeeklyReportData, name: String) -> String {
        var s = csvHeader(name)
        s += "WEEKLY PERFORMANCE\nMetric,Value\n"
        s += "Loan Growth (WoW),\"\(String(format: "%+.1f%%", d.weeklyLoanGrowth))\"\n"
        s += "Recovery Performance,\"\(pct(d.recoveryPerformance))\"\n\n"
        s += "REPAYMENT COLLECTION\nMetric,Value\n"
        s += "Total Collected,\"\(inr(d.totalRepaymentCollected))\"\n"
        s += "Number of Defaults,\(d.numberOfDefaults)\n"
        s += "Top Paying Borrowers,\(d.topPayingCustomers)\n"
        if !d.overdueAccounts.isEmpty {
            s += "\nOVERDUE ACCOUNTS\nAccount,Reference\n"
            for acct in d.overdueAccounts {
                s += "\"\(acct.title)\",\(acct.loanReferenceCode)\n"
            }
        }
        return s
    }

    private static func monthlyCSV(_ d: MonthlyReportData, name: String) -> String {
        var s = csvHeader(name)
        s += "REVENUE & PROFIT\nMetric,Value\n"
        s += "Interest Earned,\"\(inr(d.interestEarned))\"\n"
        s += "Total Revenue,\"\(inr(d.monthlyRevenue))\"\n"
        s += "Total Profit,\"\(inr(d.totalProfit))\"\n"
        s += "Penalties Collected,\"\(inr(d.penaltyCollected))\"\n"
        s += "Processing Fees,\"\(inr(d.processingFees))\"\n\n"
        s += "LOAN PERFORMANCE\nMetric,Value\n"
        s += "Total Distributed,\"\(inr(d.totalDistributed))\"\n"
        s += "Recovery Rate,\"\(pct(d.loanRecoveryRate))\"\n"
        s += "Best Category,\(d.bestPerformingCategory)\n"
        if !d.loanTypeAnalytics.isEmpty {
            s += "\nLOAN TYPE BREAKDOWN\nType,Percentage\n"
            for item in d.loanTypeAnalytics {
                s += "\(item.typeName),\"\(String(format: "%.0f%%", item.percentage))\"\n"
            }
        }
        return s
    }

    private static func npaCSV(_ d: NPAReportData, name: String) -> String {
        var s = csvHeader(name)
        s += "NPA OVERVIEW\nMetric,Value\n"
        s += "Total NPA Loans,\(d.totalNPALoans)\n"
        s += "NPA Ratio,\"\(pct(d.npaRatio * 100))\"\n"
        s += "Total NPA Amount,\"\(inr(d.totalNPAAmount))\"\n\n"
        s += "OVERDUE EMI BREAKDOWN\nMetric,Value\n"
        s += "Total Overdue EMIs,\(d.totalOverdueEMIs)\n"
        s += "Overdue Amount,\"\(inr(d.overdueAmount))\"\n\n"
        s += "RISK SEGMENTATION\nSegment,Count\n"
        s += "Critical (> 90 days),\(d.criticalAccounts)\n"
        s += "High Risk (30–90 days),\(d.highRiskAccounts)\n"
        s += "Medium Risk (< 30 days),\(d.mediumRiskAccounts)\n"
        return s
    }

    // MARK: Formatting Helpers

    private static func inr(_ value: Decimal) -> String { Formatting.currency(value) }
    private static func pct(_ value: Double) -> String { String(format: "%.1f%%", value) }

    private static func attr(_ color: UIColor, size: CGFloat, weight: UIFont.Weight = .regular,
                              alignment: NSTextAlignment = .left) -> [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        return [.font: font, .foregroundColor: color, .paragraphStyle: style]
    }

    private static func sanitize(_ name: String) -> String {
        name.components(separatedBy: .init(charactersIn: "/\\:*?\"<>|")).joined(separator: "-")
            .replacingOccurrences(of: " ", with: "_")
    }

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f.string(from: Date.now)
    }
}
