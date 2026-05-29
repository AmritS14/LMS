import Foundation
import SwiftUI

// Central data store for every Branch Manager screen. Mirrors
// `LoanOfficerStore`: hydrates from `MockManagerData` immediately, then
// reconciles with the shared `AppEnvironment` services. Decisions
// (approve / reject / send back) are reflected locally and pushed to the
// LoanService.
@MainActor
@Observable
final class ManagerStore {
    // MARK: State — Applications

    var managerProfile: OfficerProfileSummary = MockManagerData.managerProfile
    var branchName: String = MockManagerData.branchName
    var applications: [ManagerApplication] = []
    var recentActions: [ManagerRecentAction] = []
    var notifications: [OfficerNotification] = []

    // Seeded headline metrics; decisions bump these so the dashboard reacts.
    var approvedToday: Int = 13
    var rejectedToday: Int = 2
    var approvalRate: Double = 0.84
    var avgDecisionTime: String = "4.1h"

    var selectedApplicationID: UUID?

    // MARK: State — Portfolio

    var portfolioSummary: PortfolioSummaryData = MockManagerData.portfolioSummary()
    var loanCategories: [LoanCategoryBreakdown] = MockManagerData.loanCategories()
    var branchPerformanceItems: [BranchPerformanceItem] = MockManagerData.branchPerformance()

    // Portfolio filters
    var selectedBranch: String? = nil
    var selectedRegion: String? = nil
    var selectedLoanTypeFilter: LoanType? = nil
    var selectedRiskFilter: String? = nil

    // MARK: State — Officers

    var officerPerformance: [OfficerPerformanceData] = []

    // MARK: State — Audit

    var auditLogs: [ManagerAuditLogEntry] = []

    // MARK: State — Reports

    var reportHistory: [ReportItem] = []

    // MARK: State — Risk Alerts

    var riskAlerts: [RiskAlert] = []

    // MARK: State — Loan Policies

    var loanPolicies: [LoanPolicyConfig] = []

    private var environment: AppEnvironment?

    // MARK: Bootstrap

    func configure(environment: AppEnvironment) {
        self.environment = environment
        if applications.isEmpty {
            applications = MockManagerData.applications()
        }
        if recentActions.isEmpty {
            recentActions = MockManagerData.recentActions()
        }
        if notifications.isEmpty {
            notifications = MockManagerData.notifications()
        }
        if officerPerformance.isEmpty {
            officerPerformance = MockManagerData.officerPerformance()
        }
        if auditLogs.isEmpty {
            auditLogs = MockManagerData.auditLogs()
        }
        if reportHistory.isEmpty {
            reportHistory = MockManagerData.reportHistory()
        }
        if riskAlerts.isEmpty {
            riskAlerts = MockManagerData.riskAlerts()
        }
        if loanPolicies.isEmpty {
            loanPolicies = MockManagerData.loanPolicies()
        }
    }

    func refreshAll() async {
        guard let environment else { return }
        do {
            // Reconcile statuses against the shared service while keeping the
            // manager-only context (officer, recommendation, note) intact.
            let server = try await environment.loans.fetchAssignedApplications(
                officerID: MockOfficerData.officerUserID
            )
            let serverByID = Dictionary(server.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            applications = applications.map { existing in
                guard let updated = serverByID[existing.id] else { return existing }
                let rebased = OfficerApplication(
                    application: updated,
                    borrower: existing.base.borrower,
                    profile: existing.base.profile,
                    employer: existing.base.employer,
                    existingLiabilities: existing.base.existingLiabilities,
                    purpose: existing.base.purpose,
                    fraudFlag: existing.base.fraudFlag
                )
                return ManagerApplication(
                    base: rebased,
                    officerName: existing.officerName,
                    recommendation: existing.recommendation,
                    evaluationNote: existing.evaluationNote
                )
            }
        } catch {
            // Seed data already populates the UI; ignore transient failures.
        }
    }

    // MARK: Derived — Applications

    func application(id: UUID) -> ManagerApplication? {
        applications.first { $0.id == id }
    }

    var pendingReviewCount: Int {
        applications.filter { $0.status == .submitted || $0.status == .underReview }.count
    }

    var sentBackCount: Int {
        applications.filter { $0.status == .additionalInfoRequired }.count
    }

    var highRiskCount: Int {
        applications.filter { $0.riskLevel == .high }.count
    }

    var escalatedCount: Int {
        applications.filter { $0.status == .escalated }.count
    }

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var urgentNotifications: [OfficerNotification] {
        notifications.filter { $0.priority == 1 && !$0.isRead }
    }

    var approvalRateText: String { Formatting.percent(approvalRate, fractionDigits: 0) }

    var greetingDateText: String {
        "Today, " + Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    // MARK: Derived — Risk Alerts

    var unreadRiskAlertCount: Int {
        riskAlerts.filter { !$0.isRead }.count
    }

    // MARK: Mutations — Decisions

    func decide(_ action: ApplicationActionType, on application: ManagerApplication, remarks: String?) {
        guard let idx = applications.firstIndex(where: { $0.id == application.id }) else { return }
        let existing = applications[idx]
        var updatedApp = existing.base.application
        updatedApp.status = action.resultStatus
        updatedApp.updatedAt = .now

        let rebased = OfficerApplication(
            application: updatedApp,
            borrower: existing.base.borrower,
            profile: existing.base.profile,
            employer: existing.base.employer,
            existingLiabilities: existing.base.existingLiabilities,
            purpose: existing.base.purpose,
            fraudFlag: existing.base.fraudFlag
        )
        applications[idx] = ManagerApplication(
            base: rebased,
            officerName: existing.officerName,
            recommendation: existing.recommendation,
            evaluationNote: existing.evaluationNote
        )

        // Reflect on the dashboard.
        recentActions.insert(
            ManagerRecentAction(kind: action, name: existing.borrowerName,
                                amount: existing.amountText, date: .now,
                                applicationID: existing.id),
            at: 0
        )
        switch action {
        case .approve: approvedToday += 1
        case .reject: rejectedToday += 1
        case .sendBack: break
        }

        // Append to audit log
        auditLogs.insert(
            ManagerAuditLogEntry(
                loanReferenceCode: existing.referenceCode,
                action: action.verb,
                managerName: managerProfile.name,
                timestamp: .now,
                status: .completed
            ),
            at: 0
        )

        if let environment {
            Task {
                try? await environment.loans.updateStatus(
                    applicationID: updatedApp.id,
                    to: action.resultStatus,
                    note: remarks
                )
            }
        }
    }

    // MARK: Mutations — Notifications

    func markAllNotificationsRead() {
        for i in notifications.indices { notifications[i].isRead = true }
    }

    func markNotificationRead(_ notification: OfficerNotification) {
        guard let idx = notifications.firstIndex(of: notification) else { return }
        notifications[idx].isRead = true
    }

    func dismissNotification(_ notification: OfficerNotification) {
        notifications.removeAll { $0.id == notification.id }
    }

    // MARK: Mutations — Reports

    func generateReport(type: ReportKind, format: ReportFormat) {
        let name: String
        switch type {
        case .daily: name = "Daily Report — \(Date.now.formatted(.dateTime.month().day()))"
        case .weekly: name = "Weekly Report — W\(Calendar.current.component(.weekOfYear, from: .now))"
        case .monthly: name = "Monthly Report — \(Date.now.formatted(.dateTime.month(.wide)))"
        case .npa: name = "NPA Analysis — \(Date.now.formatted(.dateTime.month(.abbreviated).year()))"
        case .collectionEfficiency: name = "Collection Report — \(Date.now.formatted(.dateTime.month(.abbreviated)))"
        }

        let report = ReportItem(
            name: name, type: type, format: format,
            size: "—", generatedAt: .now, status: .generating
        )
        reportHistory.insert(report, at: 0)

        // Simulate generation completing after a delay
        let reportID = report.id
        Task {
            try? await Task.sleep(for: .seconds(2))
            if let idx = reportHistory.firstIndex(where: { $0.id == reportID }) {
                reportHistory[idx] = ReportItem(
                    name: name, type: type, format: format,
                    size: format == .pdf ? "1.4 MB" : "280 KB",
                    generatedAt: .now, status: .completed
                )
            }
        }
    }

    func deleteReport(_ report: ReportItem) {
        reportHistory.removeAll { $0.id == report.id }
    }

    // MARK: Mutations — Risk Alerts

    func markRiskAlertRead(_ alert: RiskAlert) {
        guard let idx = riskAlerts.firstIndex(where: { $0.id == alert.id }) else { return }
        riskAlerts[idx].isRead = true
    }

    func dismissRiskAlert(_ alert: RiskAlert) {
        riskAlerts.removeAll { $0.id == alert.id }
    }

    // MARK: Mutations — Loan Policies

    func updatePolicy(_ policy: LoanPolicyConfig) {
        guard let idx = loanPolicies.firstIndex(where: { $0.id == policy.id }) else { return }
        loanPolicies[idx] = policy

        // Audit the change
        auditLogs.insert(
            ManagerAuditLogEntry(
                loanReferenceCode: "POLICY-\(policy.loanType.rawValue.uppercased())",
                action: "Policy Updated",
                managerName: managerProfile.name,
                timestamp: .now,
                status: .completed
            ),
            at: 0
        )
    }

#if DEBUG
    // Hydrated from mock data so SwiftUI previews show content without an
    // AppEnvironment. refreshAll()/decide() service calls no-op when the
    // environment is nil, so previews stay safe.
    static var preview: ManagerStore {
        let store = ManagerStore()
        store.applications = MockManagerData.applications()
        store.recentActions = MockManagerData.recentActions()
        store.notifications = MockManagerData.notifications()
        store.officerPerformance = MockManagerData.officerPerformance()
        store.auditLogs = MockManagerData.auditLogs()
        store.reportHistory = MockManagerData.reportHistory()
        store.riskAlerts = MockManagerData.riskAlerts()
        store.loanPolicies = MockManagerData.loanPolicies()
        return store
    }
#endif
}
