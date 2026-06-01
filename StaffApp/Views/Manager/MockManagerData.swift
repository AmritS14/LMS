import Foundation

// Manager-only seed data. Reuses the shared `MockOfficerData` borrower roster
// and application set so the same files appear consistently across the
// Officer and Manager apps, then layers on the manager-facing context
// (originating officer, recommendation, evaluation note) and branch metrics.
enum MockManagerData {
    static let managerProfile = OfficerProfileSummary(
        name: "Aditi Rao",
        employeeID: "BM-1187",
        branch: "Bengaluru — MG Road"
    )

    static let branchName = "Bengaluru — MG Road"

    // Loan officers who originated the applications in the queue.
    private static let officerNames = [
        "Sarah Mehta",
        "Marcus Reed",
        "Jane Doe",
        "Sarah Mehta",
        "Marcus Reed"
    ]

    private static let evaluationNotes = [
        "Strong collateral position with a debt-to-income ratio well below the risk threshold. Stable employment history. Recommend approval for the requested amount.",
        "Income documentation is solid and consistent. Credit profile is acceptable but advise a closer look at existing liabilities before disbursal.",
        "Self-employed applicant with variable cash flow. Business expansion case is reasonable but verification of the latest filings is still pending.",
        "Education loan with a co-applicant guarantee. KYC is incomplete — flagged for additional verification before any decision.",
        "Excellent credit profile and high collateral coverage. Low-risk home loan; recommend immediate approval."
    ]

    // MARK: Applications shown in the manager queue

    static func applications() -> [ManagerApplication] {
        let apps = MockOfficerData.assignedApplications()
        return apps.enumerated().compactMap { index, app in
            guard let seed = MockOfficerData.seedBorrowers.first(where: { $0.user.id == app.borrowerID }) else {
                return nil
            }
            let base = OfficerApplication(
                application: app,
                borrower: seed.user,
                profile: seed.profile,
                employer: seed.employer,
                existingLiabilities: seed.existingLiabilities,
                purpose: seed.purpose,
                fraudFlag: seed.fraudFlag
            )
            return ManagerApplication(
                base: base,
                officerName: officerNames[index % officerNames.count],
                recommendation: .from(risk: base.riskLevel),
                evaluationNote: evaluationNotes[index % evaluationNotes.count]
            )
        }
    }

    // MARK: Recent decisions (dashboard feed)

    static func recentActions() -> [ManagerRecentAction] {
        let now = Date.now
        let apps = MockOfficerData.assignedApplications()
        let app0 = apps.count > 0 ? apps[0].id : nil
        let app1 = apps.count > 1 ? apps[1].id : nil
        let app2 = apps.count > 2 ? apps[2].id : nil
        let app3 = apps.count > 3 ? apps[3].id : nil

        return [
            ManagerRecentAction(kind: .approve, name: "Sarah Jenkins",
                                amount: Formatting.currency(450_000),
                                date: now.addingTimeInterval(-60 * 2),
                                applicationID: app0),
            ManagerRecentAction(kind: .approve, name: "Jonathan Aris",
                                amount: Formatting.currency(210_000),
                                date: now.addingTimeInterval(-60 * 60 * 3),
                                applicationID: app1),
            ManagerRecentAction(kind: .reject, name: "David Chen",
                                amount: Formatting.currency(125_000),
                                date: now.addingTimeInterval(-60 * 60 * 6),
                                applicationID: app2),
            ManagerRecentAction(kind: .sendBack, name: "Michael Scott",
                                amount: Formatting.currency(500_000),
                                date: now.addingTimeInterval(-60 * 60 * 26),
                                applicationID: app3)
        ]
    }

    // MARK: Notifications feed

    static func notifications() -> [OfficerNotification] {
        let now = Date.now
        return [
            OfficerNotification(
                title: "3 applications need urgent review",
                message: "Personal loan decisions are due before EOD today.",
                timestamp: now.addingTimeInterval(-60 * 20),
                type: .pendingApproval,
                priority: 1,
                isRead: false
            ),
            OfficerNotification(
                title: "Fraud signal on Anita Desai",
                message: "Document forensics flagged tampering on a bank statement.",
                timestamp: now.addingTimeInterval(-60 * 55),
                type: .fraudAlert,
                priority: 1,
                isRead: false
            ),
            OfficerNotification(
                title: "Officer escalation — Rahul Sharma",
                message: "Marcus Reed requested a second opinion on a business loan.",
                timestamp: now.addingTimeInterval(-60 * 60 * 4),
                type: .escalation,
                priority: 2,
                isRead: false
            ),
            OfficerNotification(
                title: "Branch performance report ready",
                message: "April approval-rate summary is available in Reports.",
                timestamp: now.addingTimeInterval(-60 * 60 * 28),
                type: .system,
                priority: 2,
                isRead: true
            )
        ]
    }

    // MARK: Portfolio

    static func portfolioSummary() -> PortfolioSummaryData {
        PortfolioSummaryData(
            totalLoans: 347,
            totalDisbursement: 42_850_000,
            collectionEfficiency: 0.924,
            npaRatio: 0.034,
            activeLoans: 298,
            overdueLoans: 18,
            recoveryRate: 0.871,
            paidEMIPercent: 0.946
        )
    }

    static func loanCategories() -> [LoanCategoryBreakdown] {
        [
            LoanCategoryBreakdown(loanType: .home, count: 89, amount: 18_500_000, percentage: 0.43),
            LoanCategoryBreakdown(loanType: .personal, count: 112, amount: 8_960_000, percentage: 0.21),
            LoanCategoryBreakdown(loanType: .business, count: 56, amount: 9_240_000, percentage: 0.22),
            LoanCategoryBreakdown(loanType: .vehicle, count: 48, amount: 3_840_000, percentage: 0.09),
            LoanCategoryBreakdown(loanType: .education, count: 42, amount: 2_310_000, percentage: 0.05)
        ]
    }

    static func branchPerformance() -> [BranchPerformanceItem] {
        [
            BranchPerformanceItem(branchName: "MG Road", approvalRate: 0.84, avgDecisionTime: "4.1h", totalApplications: 156, npaRatio: 0.034)
        ]
    }

    // MARK: Officer Performance

    static func officerPerformance() -> [OfficerPerformanceData] {
        let now = Date.now
        return [
            OfficerPerformanceData(
                name: "Sarah Mehta", initials: "SM",
                applicationsProcessed: 48, approvalRate: 0.86,
                avgDecisionTime: "3.2h", recoveryRate: 0.92,
                recentDecisions: [
                    OfficerDecisionRecord(applicantName: "Priya Sharma", amount: Formatting.currency(2_500_000), action: .approve, date: now.addingTimeInterval(-60 * 30)),
                    OfficerDecisionRecord(applicantName: "Vikram Patel", amount: Formatting.currency(800_000), action: .approve, date: now.addingTimeInterval(-60 * 60 * 2)),
                    OfficerDecisionRecord(applicantName: "Neha Singh", amount: Formatting.currency(150_000), action: .reject, date: now.addingTimeInterval(-60 * 60 * 5))
                ]
            ),
            OfficerPerformanceData(
                name: "Marcus Reed", initials: "MR",
                applicationsProcessed: 35, approvalRate: 0.74,
                avgDecisionTime: "4.8h", recoveryRate: 0.85,
                recentDecisions: [
                    OfficerDecisionRecord(applicantName: "Arjun Mehta", amount: Formatting.currency(300_000), action: .sendBack, date: now.addingTimeInterval(-60 * 60)),
                    OfficerDecisionRecord(applicantName: "David Chen", amount: Formatting.currency(125_000), action: .reject, date: now.addingTimeInterval(-60 * 60 * 6))
                ]
            ),
            OfficerPerformanceData(
                name: "Jane Doe", initials: "JD",
                applicationsProcessed: 42, approvalRate: 0.81,
                avgDecisionTime: "3.9h", recoveryRate: 0.89,
                recentDecisions: [
                    OfficerDecisionRecord(applicantName: "Anita Desai", amount: Formatting.currency(1_200_000), action: .sendBack, date: now.addingTimeInterval(-60 * 60 * 3)),
                    OfficerDecisionRecord(applicantName: "Jonathan Aris", amount: Formatting.currency(210_000), action: .approve, date: now.addingTimeInterval(-60 * 60 * 8))
                ]
            ),
            OfficerPerformanceData(
                name: "Ravi Kumar", initials: "RK",
                applicationsProcessed: 29, approvalRate: 0.69,
                avgDecisionTime: "5.5h", recoveryRate: 0.78,
                recentDecisions: [
                    OfficerDecisionRecord(applicantName: "Michael Scott", amount: Formatting.currency(500_000), action: .reject, date: now.addingTimeInterval(-60 * 60 * 12))
                ]
            )
        ]
    }

    // MARK: Audit Logs

    static func auditLogs() -> [ManagerAuditLogEntry] {
        let now = Date.now
        return [
            ManagerAuditLogEntry(loanReferenceCode: "LN-BBBBBB", action: "Approved", managerName: "Aditi Rao", timestamp: now.addingTimeInterval(-60 * 15), status: .completed),
            ManagerAuditLogEntry(loanReferenceCode: "LN-CCCCCC", action: "Sent Back", managerName: "Aditi Rao", timestamp: now.addingTimeInterval(-60 * 60 * 2), status: .completed),
            ManagerAuditLogEntry(loanReferenceCode: "LN-DDDDDD", action: "Rejected", managerName: "Aditi Rao", timestamp: now.addingTimeInterval(-60 * 60 * 6), status: .completed),
            ManagerAuditLogEntry(loanReferenceCode: "LN-EEEEEE", action: "Escalated", managerName: "Aditi Rao", timestamp: now.addingTimeInterval(-60 * 60 * 12), status: .pending),
            ManagerAuditLogEntry(loanReferenceCode: "LN-FF1234", action: "Policy Updated", managerName: "Aditi Rao", timestamp: now.addingTimeInterval(-60 * 60 * 24), status: .completed),
            ManagerAuditLogEntry(loanReferenceCode: "LN-GG5678", action: "Approved", managerName: "Rajesh Iyer", timestamp: now.addingTimeInterval(-60 * 60 * 26), status: .completed),
            ManagerAuditLogEntry(loanReferenceCode: "LN-HH9012", action: "Rejected", managerName: "Rajesh Iyer", timestamp: now.addingTimeInterval(-60 * 60 * 30), status: .failed),
            ManagerAuditLogEntry(loanReferenceCode: "LN-II3456", action: "Approved", managerName: "Aditi Rao", timestamp: now.addingTimeInterval(-60 * 60 * 48), status: .completed)
        ]
    }

    // MARK: Report History

    static func reportHistory() -> [ReportItem] {
        let now = Date.now
        return [
            ReportItem(name: "Daily Report — May 27", type: .daily, format: .pdf, size: "1.2 MB", generatedAt: now.addingTimeInterval(-60 * 30), status: .completed),
            ReportItem(name: "Weekly Report — W21", type: .weekly, format: .csv, size: "340 KB", generatedAt: now.addingTimeInterval(-60 * 60 * 24), status: .completed),
            ReportItem(name: "Monthly Report — April", type: .monthly, format: .pdf, size: "4.8 MB", generatedAt: now.addingTimeInterval(-60 * 60 * 72), status: .completed),
            ReportItem(name: "NPA Analysis — Q1 2026", type: .npa, format: .pdf, size: "2.1 MB", generatedAt: now.addingTimeInterval(-60 * 60 * 168), status: .completed),
            ReportItem(name: "Daily Report — May 26", type: .daily, format: .pdf, size: "1.1 MB", generatedAt: now.addingTimeInterval(-60 * 60 * 48), status: .completed)
        ]
    }

    // MARK: Risk Alerts

    static func riskAlerts() -> [RiskAlert] {
        let now = Date.now
        return [
            RiskAlert(title: "Critical NPA Risk — Anita Desai", message: "Business loan ₹12,00,000 has 3 consecutive missed EMIs. Immediate action required.", severity: .critical, loanReferenceCode: "LN-DDDDDD", timestamp: now.addingTimeInterval(-60 * 10), isRead: false),
            RiskAlert(title: "High DTI Ratio Detected", message: "Arjun Mehta's debt-to-income ratio exceeds 50%. Review collateral adequacy.", severity: .high, loanReferenceCode: "LN-CCCCCC", timestamp: now.addingTimeInterval(-60 * 60 * 3), isRead: false),
            RiskAlert(title: "Document Fraud Flagged", message: "Income certificate for Anita Desai flagged by automated forensics.", severity: .critical, loanReferenceCode: "LN-DDDDDD", timestamp: now.addingTimeInterval(-60 * 60 * 5), isRead: false),
            RiskAlert(title: "Overdue EMI Escalation", message: "Rahul Sharma's education loan has 1 overdue EMI. Officer notified.", severity: .medium, loanReferenceCode: "LN-EEEEEE", timestamp: now.addingTimeInterval(-60 * 60 * 24), isRead: true),
            RiskAlert(title: "Credit Score Decline", message: "Priya Sharma's credit score dropped from 782 to 745. Monitor closely.", severity: .medium, loanReferenceCode: "LN-BBBBBB", timestamp: now.addingTimeInterval(-60 * 60 * 48), isRead: true)
        ]
    }

    // MARK: Loan Policies

    static func loanPolicies() -> [LoanPolicyConfig] {
        [
            LoanPolicyConfig(loanType: .home, interestRateMin: 7.5, interestRateMax: 9.5, maxTenureMonths: 360, maxAmount: 10_000_000, minCreditScore: 700, maxDTIRatio: 0.50, isActive: true),
            LoanPolicyConfig(loanType: .personal, interestRateMin: 10.0, interestRateMax: 14.0, maxTenureMonths: 60, maxAmount: 2_000_000, minCreditScore: 650, maxDTIRatio: 0.40, isActive: true),
            LoanPolicyConfig(loanType: .business, interestRateMin: 11.0, interestRateMax: 16.0, maxTenureMonths: 84, maxAmount: 5_000_000, minCreditScore: 680, maxDTIRatio: 0.55, isActive: true),
            LoanPolicyConfig(loanType: .vehicle, interestRateMin: 8.5, interestRateMax: 12.0, maxTenureMonths: 84, maxAmount: 3_000_000, minCreditScore: 660, maxDTIRatio: 0.45, isActive: true),
            LoanPolicyConfig(loanType: .education, interestRateMin: 8.0, interestRateMax: 11.0, maxTenureMonths: 120, maxAmount: 4_000_000, minCreditScore: 600, maxDTIRatio: 0.60, isActive: true)
        ]
    }

    // MARK: Detailed Reports

    static func overdueCustomers() -> [OverdueCustomer] {
        [
            OverdueCustomer(name: "Rahul Sharma", daysLate: 10, pendingAmount: 5_000),
            OverdueCustomer(name: "Neha Singh", daysLate: 45, pendingAmount: 12_500),
            OverdueCustomer(name: "Amit Patel", daysLate: 90, pendingAmount: 45_000)
        ]
    }

    static func dailyReportData() -> DailyReportData {
        DailyReportData(
            loansApproved: 25,
            totalAmount: 2_50_000,
            activeLoans: 120,
            emiCollected: 45_000,
            pendingCollections: 10_000,
            newCustomers: 12,
            missedPayments: 4
        )
    }

    static func weeklyReportData() -> WeeklyReportData {
        WeeklyReportData(
            weeklyLoanGrowth: 5.2,
            totalRepaymentCollected: 3_20_000,
            numberOfDefaults: 8,
            recoveryPerformance: 88.5,
            topPayingCustomers: 15
        )
    }

    static func monthlyReportData() -> MonthlyReportData {
        MonthlyReportData(
            monthlyRevenue: 15_00_000,
            totalDistributed: 42_850_000,
            loanRecoveryRate: 92.4,
            totalProfit: 4_50_000,
            interestEarned: 30_000,
            penaltyCollected: 2_000,
            processingFees: 15_000,
            bestPerformingCategory: "Personal Loans",
            loanTypeAnalytics: [
                LoanTypeAnalytics(type: "Personal", percentage: 40, color: .lmsAccent),
                LoanTypeAnalytics(type: "Business", percentage: 35, color: .lmsSuccess),
                LoanTypeAnalytics(type: "Education", percentage: 25, color: .lmsWarning)
            ]
        )
    }
}

