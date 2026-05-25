import Foundation
import SwiftUI

// Central data store for every Loan Officer screen. Reads from the shared
// AppEnvironment services where possible (loans, messaging, notifications,
// documents); supplements with officer-only seed data for fields the
// shared services don't yet expose.
@MainActor
@Observable
final class LoanOfficerStore {
    // MARK: State

    var officerProfile: OfficerProfileSummary = MockOfficerData.officerProfile
    var applications: [OfficerApplication] = []
    var notifications: [OfficerNotification] = []
    var conversations: [OfficerConversation] = []
    var reviewDocuments: [ReviewDocument] = []
    var generatedDocuments: [GeneratedDocument] = []
    var overdueBorrowers: [OverdueBorrower] = []
    var collateral: LoanCollateral = MockOfficerData.collateral()

    var selectedApplicationID: UUID?
    var isLoading: Bool = false
    var loadError: String?

    private var environment: AppEnvironment?

    // MARK: Bootstrap

    func configure(environment: AppEnvironment) {
        self.environment = environment
        // Hydrate from mock data immediately so the UI has content before
        // async fetches resolve.
        if applications.isEmpty {
            applications = buildOfficerApplications(
                from: MockOfficerData.assignedApplications()
            )
        }
        if notifications.isEmpty {
            notifications = MockOfficerData.notifications()
        }
        if reviewDocuments.isEmpty {
            reviewDocuments = MockOfficerData.reviewDocuments()
        }
        if generatedDocuments.isEmpty {
            generatedDocuments = MockOfficerData.generatedDocuments()
        }
        if overdueBorrowers.isEmpty {
            overdueBorrowers = MockOfficerData.overdueBorrowers()
        }
    }

    func refreshAll() async {
        guard let environment else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            async let serverApps = environment.loans.fetchAssignedApplications(
                officerID: MockOfficerData.officerUserID
            )
            async let serverThreads = environment.messaging.threads(
                for: MockOfficerData.officerUserID
            )
            async let serverNotifications = environment.notifications.fetchHistory(limit: 30)

            let (apps, threads, notifs) = try await (serverApps, serverThreads, serverNotifications)

            // Merge server-side applications onto the seed roster.
            let serverByID = Dictionary(uniqueKeysWithValues: apps.map { ($0.id, $0) })
            applications = applications.map { existing in
                if let server = serverByID[existing.application.id] {
                    return OfficerApplication(
                        application: server,
                        borrower: existing.borrower,
                        profile: existing.profile,
                        employer: existing.employer,
                        existingLiabilities: existing.existingLiabilities,
                        purpose: existing.purpose,
                        fraudFlag: existing.fraudFlag
                    )
                }
                return existing
            }

            conversations = await buildConversations(threads: threads)
            mergeNotifications(server: notifs)
        } catch {
            loadError = error.localizedDescription
        }
    }

    // MARK: Derived

    func application(id: UUID) -> OfficerApplication? {
        applications.first { $0.id == id }
    }

    var selectedApplication: OfficerApplication? {
        guard let id = selectedApplicationID else { return applications.first }
        return application(id: id) ?? applications.first
    }

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var urgentNotifications: [OfficerNotification] {
        notifications.filter { $0.priority == 1 && !$0.isRead }
    }

    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Working late"
        }
    }

    var kpiTiles: [OfficerKPI] {
        let pending = applications.filter { $0.status == .underReview || $0.status == .submitted }.count
        let approved = applications.filter { $0.status == .approved || $0.status == .recommended || $0.status == .disbursed }.count
        let fraud = applications.filter { $0.fraudFlag }.count
        let overdue = overdueBorrowers.count
        return [
            OfficerKPI(title: "Pending Reviews", value: "\(pending)",
                       icon: "tray.full.fill", tint: .lmsInfo),
            OfficerKPI(title: "Approved Today", value: "\(approved)",
                       icon: "checkmark.seal.fill", tint: .lmsSuccess),
            OfficerKPI(title: "Fraud Signals", value: "\(fraud)",
                       icon: "exclamationmark.shield.fill", tint: .lmsDanger),
            OfficerKPI(title: "Overdue Accounts", value: "\(overdue)",
                       icon: "clock.badge.exclamationmark.fill", tint: .lmsWarning)
        ]
    }

    // MARK: Mutations

    func markNotificationRead(_ notification: OfficerNotification) {
        guard let idx = notifications.firstIndex(of: notification) else { return }
        notifications[idx].isRead = true
    }

    func markAllNotificationsRead() {
        for i in notifications.indices { notifications[i].isRead = true }
    }

    func dismissNotification(_ notification: OfficerNotification) {
        notifications.removeAll { $0.id == notification.id }
    }

    func approveApplication(_ application: OfficerApplication) {
        updateStatus(for: application, to: .approved)
    }

    func rejectApplication(_ application: OfficerApplication) {
        updateStatus(for: application, to: .rejected)
    }

    func recommendApplication(_ application: OfficerApplication) {
        updateStatus(for: application, to: .recommended)
    }

    func requestAdditionalInfo(for application: OfficerApplication) {
        updateStatus(for: application, to: .additionalInfoRequired)
    }

    func escalateApplication(_ application: OfficerApplication, note: String?) {
        updateStatus(for: application, to: .escalated, note: note)
    }

    func markBorrowerContacted(_ borrower: OverdueBorrower) {
        guard let idx = overdueBorrowers.firstIndex(of: borrower) else { return }
        overdueBorrowers[idx].contacted = true
    }

    func sendMessage(_ text: String, in conversationID: UUID) async {
        guard let environment,
              let idx = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        let conversation = conversations[idx]
        let outgoing = ConversationMessage(
            id: UUID(),
            sender: .officer,
            text: text,
            sentAt: .now
        )
        conversations[idx].messages.append(outgoing)

        let chat = ChatMessage(
            id: outgoing.id,
            threadID: conversation.id,
            senderID: MockOfficerData.officerUserID,
            body: text,
            sentAt: outgoing.sentAt
        )
        _ = try? await environment.messaging.send(chat)
    }

    // MARK: Helpers

    private func updateStatus(for application: OfficerApplication,
                              to status: ApplicationStatus,
                              note: String? = nil) {
        guard let idx = applications.firstIndex(of: application) else { return }
        var updated = applications[idx].application
        updated.status = status
        updated.updatedAt = .now
        applications[idx] = OfficerApplication(
            application: updated,
            borrower: applications[idx].borrower,
            profile: applications[idx].profile,
            employer: applications[idx].employer,
            existingLiabilities: applications[idx].existingLiabilities,
            purpose: applications[idx].purpose,
            fraudFlag: applications[idx].fraudFlag
        )

        if let environment {
            Task {
                try? await environment.loans.updateStatus(
                    applicationID: updated.id,
                    to: status,
                    note: note
                )
            }
        }
    }

    private func buildOfficerApplications(from apps: [LoanApplication]) -> [OfficerApplication] {
        apps.compactMap { app in
            guard let seed = MockOfficerData.seedBorrowers.first(where: { $0.user.id == app.borrowerID }) else {
                return nil
            }
            return OfficerApplication(
                application: app,
                borrower: seed.user,
                profile: seed.profile,
                employer: seed.employer,
                existingLiabilities: seed.existingLiabilities,
                purpose: seed.purpose,
                fraudFlag: seed.fraudFlag
            )
        }
    }

    private func buildConversations(threads: [MessageThread]) async -> [OfficerConversation] {
        guard let environment else { return [] }
        var result: [OfficerConversation] = []
        for thread in threads {
            // The borrower is whichever participant isn't the officer.
            let borrowerID = thread.participantIDs.first { $0 != MockOfficerData.officerUserID } ?? thread.participantIDs.first ?? UUID()
            let borrowerName = MockOfficerData.seedBorrowers.first { $0.user.id == borrowerID }?.user.fullName ?? "Borrower"

            let serverMessages = (try? await environment.messaging.messages(threadID: thread.id)) ?? []
            let messages = serverMessages.map { msg in
                ConversationMessage(
                    id: msg.id,
                    sender: msg.senderID == MockOfficerData.officerUserID ? .officer : .borrower,
                    text: msg.body,
                    sentAt: msg.sentAt
                )
            }

            let unread = serverMessages.filter { $0.readAt == nil && $0.senderID != MockOfficerData.officerUserID }.count

            result.append(
                OfficerConversation(
                    id: thread.id,
                    borrowerID: borrowerID,
                    borrowerName: borrowerName,
                    isOnline: Bool.random(),
                    messages: messages,
                    unreadCount: unread
                )
            )
        }
        return result.sorted { $0.lastMessageTime > $1.lastMessageTime }
    }

    private func mergeNotifications(server: [PushNotification]) {
        let mapped = server.map { push in
            OfficerNotification(
                title: push.title,
                message: push.body,
                timestamp: push.receivedAt,
                type: mapTopic(push.topic),
                priority: push.topic == .emiOverdue ? 1 : 2,
                isRead: false
            )
        }
        let merged = (mapped + notifications)
            .reduce(into: [OfficerNotification]()) { acc, item in
                if !acc.contains(where: { $0.title == item.title && $0.message == item.message }) {
                    acc.append(item)
                }
            }
        notifications = merged.sorted { $0.timestamp > $1.timestamp }
    }

    private func mapTopic(_ topic: NotificationTopic) -> OfficerNotificationType {
        switch topic {
        case .emiDue, .emiOverdue: .overdueReminder
        case .applicationStatus: .pendingApproval
        case .disbursement: .system
        case .message: .assignedApplication
        case .system: .system
        }
    }
}

// MARK: - Environment plumbing

extension EnvironmentValues {
    @Entry var loanOfficerStore: LoanOfficerStore? = nil
}
