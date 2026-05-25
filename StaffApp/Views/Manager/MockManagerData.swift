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
        return [
            ManagerRecentAction(kind: .approve, name: "Sarah Jenkins",
                                amount: Formatting.currency(450_000),
                                date: now.addingTimeInterval(-60 * 2)),
            ManagerRecentAction(kind: .approve, name: "Jonathan Aris",
                                amount: Formatting.currency(210_000),
                                date: now.addingTimeInterval(-60 * 60 * 3)),
            ManagerRecentAction(kind: .reject, name: "David Chen",
                                amount: Formatting.currency(125_000),
                                date: now.addingTimeInterval(-60 * 60 * 6)),
            ManagerRecentAction(kind: .sendBack, name: "Michael Scott",
                                amount: Formatting.currency(500_000),
                                date: now.addingTimeInterval(-60 * 60 * 26))
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
}
