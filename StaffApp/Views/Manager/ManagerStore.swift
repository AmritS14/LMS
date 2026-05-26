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
    // MARK: State

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
    }

    func refreshAll() async {
        guard let environment else { return }
        do {
            // Managers review escalated applications. RLS scopes this to the
            // manager's own team, so a direct query is safe.
            let server = try await environment.loans.fetchApplications(
                statuses: ["manager_review", "approved", "disbursed", "rejected"]
            )
            guard !server.isEmpty else { return }
            applications = server.map(Self.makeManagerApplication)
        } catch {
            // Seed data already populates the UI; ignore transient failures.
        }
    }

    private static func makeManagerApplication(from app: LoanApplication) -> ManagerApplication {
        let name = app.borrowerName ?? "Borrower"
        let borrower = User(
            id: app.borrowerID,
            fullName: name,
            email: app.borrowerEmail ?? "",
            phone: "",
            role: .borrower
        )
        let profile = BorrowerProfile(
            id: app.borrowerID,
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now,
            address: nil,
            panNumber: nil,
            aadhaarLast4: nil,
            employmentType: nil,
            monthlyIncome: nil,
            kycStatus: .pending,
            creditScore: nil
        )
        let base = OfficerApplication(
            application: app,
            borrower: borrower,
            profile: profile,
            employer: "—",
            existingLiabilities: 0,
            purpose: "—",
            fraudFlag: false
        )
        return ManagerApplication(
            base: base,
            officerName: "",
            recommendation: OfficerRecommendation.from(risk: base.riskLevel),
            evaluationNote: ""
        )
    }

    // MARK: Derived

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

    // MARK: Mutations

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
                                amount: existing.amountText, date: .now),
            at: 0
        )
        switch action {
        case .approve: approvedToday += 1
        case .reject: rejectedToday += 1
        case .sendBack: break
        }

        if let environment {
            let appID = updatedApp.id
            switch action {
            case .approve:
                Task { try? await environment.loans.approveApplication(applicationID: appID, remark: remarks) }
            case .reject:
                Task { try? await environment.loans.rejectApplication(applicationID: appID, remark: remarks) }
            case .sendBack:
                // No manager-facing "send back" endpoint exists; this stays a local-only decision.
                break
            }
        }
    }

    // Disburse an approved application: creates the loan + EMI schedule on the backend.
    func disburse(_ application: ManagerApplication) async throws {
        guard let environment else { return }
        try await environment.loans.disburseLoan(applicationID: application.id)
        if let idx = applications.firstIndex(where: { $0.id == application.id }) {
            let existing = applications[idx]
            var updatedApp = existing.base.application
            updatedApp.status = .disbursed
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
        }
    }

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

#if DEBUG
    // Hydrated from mock data so SwiftUI previews show content without an
    // AppEnvironment. refreshAll()/decide() service calls no-op when the
    // environment is nil, so previews stay safe.
    static var preview: ManagerStore {
        let store = ManagerStore()
        store.applications = MockManagerData.applications()
        store.recentActions = MockManagerData.recentActions()
        store.notifications = MockManagerData.notifications()
        return store
    }
#endif
}
