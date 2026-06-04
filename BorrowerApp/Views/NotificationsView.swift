import SwiftUI

struct NotificationsView: View {
    @Environment(\.appEnvironment) private var env

    @State private var notifications: [PushNotification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if isLoading && notifications.isEmpty {
                Section {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .listRowBackground(Color.clear)
                }
            } else if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.lmsDanger)
                }
            } else if notifications.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Notifications",
                        systemImage: "bell.slash",
                        description: Text("You'll see updates about your loans and applications here.")
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    ForEach(notifications) { notif in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(notif.title)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(Formatting.date(notif.receivedAt, style: .long))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Text(notif.body)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await fetchNotifications() }
        .task { await fetchNotifications() }
    }

    private func fetchNotifications() async {
        guard let env else { return }
        if notifications.isEmpty { isLoading = true }
        do {
            guard let user = await env.auth.currentUser else {
                isLoading = false
                return
            }
            
            async let appsReq = env.loans.fetchApplications(for: user.id)
            async let loansReq = env.loans.fetchActiveLoans(borrowerID: user.id)
            
            let fetchedApps = try await appsReq
            let fetchedLoans = try await loansReq
            
            var generatedNotifs: [PushNotification] = []
            
            // Notifications from Applications
            for app in fetchedApps {
                generatedNotifs.append(PushNotification(
                    topic: .applicationStatus,
                    title: "Application \(app.status.rawValue.capitalized)",
                    body: "Your application for \(Formatting.currency(app.requestedAmount)) is currently \(app.status.rawValue).",
                    receivedAt: app.updatedAt
                ))
                
                if app.status == .additionalInfoRequired {
                    generatedNotifs.append(PushNotification(
                        topic: .applicationStatus,
                        title: "Action Required",
                        body: "Please provide the requested documents for your \(Formatting.currency(app.requestedAmount)) application.",
                        receivedAt: app.updatedAt
                    ))
                }
            }
            
            // Notifications from Active Loans and EMIs
            try await withThrowingTaskGroup(of: [PushNotification].self) { group in
                for loan in fetchedLoans where loan.status == .active {
                    group.addTask {
                        var loanNotifs: [PushNotification] = []
                        let emiSchedule = try await env.loans.fetchEMISchedule(loanID: loan.id)
                        
                        if let overdueEMI = emiSchedule.first(where: { $0.status == .overdue }) {
                            loanNotifs.append(PushNotification(
                                topic: .emiOverdue,
                                title: "Overdue EMI",
                                body: "You have an overdue EMI of \(Formatting.currency(overdueEMI.totalAmount)) that was due on \(Formatting.date(overdueEMI.dueDate, style: .numeric)).",
                                receivedAt: Date().addingTimeInterval(-86400) // Yesterday
                            ))
                        } else if let upcomingEMI = emiSchedule.first(where: { $0.status == .upcoming }) {
                            if upcomingEMI.dueDate.timeIntervalSinceNow < 7 * 24 * 3600 {
                                loanNotifs.append(PushNotification(
                                    topic: .emiDue,
                                    title: "Upcoming Payment",
                                    body: "Your next EMI of \(Formatting.currency(upcomingEMI.totalAmount)) is due on \(Formatting.date(upcomingEMI.dueDate, style: .numeric)).",
                                    receivedAt: Date()
                                ))
                            }
                        }
                        return loanNotifs
                    }
                }
                
                for try await notifs in group {
                    generatedNotifs.append(contentsOf: notifs)
                }
            }
            
            // System Welcome Notification
            generatedNotifs.append(PushNotification(
                topic: .system,
                title: "Welcome to Infosys LMS",
                body: "Thanks for joining us! We're here to help you manage your loans seamlessly.",
                receivedAt: Date().addingTimeInterval(-30 * 24 * 3600) // Last month
            ))
            
            self.notifications = generatedNotifs.sorted { $0.receivedAt > $1.receivedAt }
            self.errorMessage = nil
            
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
            .environment(\.appEnvironment, AppEnvironment(
                auth: MockAuthService(),
                loans: MockLoanService(),
                documents: MockDocumentService(),
                notifications: MockNotificationService(),
                messaging: MockMessagingService(),
                keychain: MockKeychainService()
            ))
    }
}
