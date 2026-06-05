import re

with open('StaffApp/Views/LoanOfficer/LOAppViewModel.swift', 'r') as f:
    content = f.read()

# 1. Replace overdueBorrowers initialization
content = content.replace(
    'var overdueBorrowers: [OverdueBorrower] = SampleRecoveryData.overdueBorrowers',
    'var overdueBorrowers: [OverdueBorrower] = []'
)

# 2. Replace refreshFromService
new_refresh = """    private func refreshFromService() async {
        guard let environment else { return }

        do {
            let sharedApplications = try await environment.loans.fetchAssignedApplications(
                officerID: officerID ?? MockOfficerData.officerUserID // fallback UUID for offline testing
            )

            // Build real officer rows
            var rows: [LOLoanApplication] = []
            for app in sharedApplications {
                let events = (try? await environment.loans.fetchApplicationEvents(applicationID: app.id)) ?? []
                let docs = (try? await environment.documents.documents(forApplication: app.id)) ?? []
                rows.append(Self.makeOfficerApplication(from: app, events: events, documents: docs))
            }

            recentApplications = rows
            if let selectedID = selectedApplication?.sourceApplicationID {
                selectedApplication = rows.first { $0.sourceApplicationID == selectedID }
            }
            
            // Build Activity Feed
            var feed: [ActivityItem] = []
            for app in rows {
                for event in app.timeline {
                    let type: ActivityType = event.status == .approved ? .approved : (event.status == .escalated ? .escalation : .assignedApplication)
                    feed.append(ActivityItem(title: event.title, subtitle: "\\(app.borrowerName) — \\(event.description)", type: type, timestamp: event.timestamp))
                }
            }
            self.activityFeed = Array(feed.sorted { $0.timestamp > $1.timestamp }.prefix(20))
            
            // Fetch Overdue Borrowers
            var overdue: [OverdueBorrower] = []
            for app in rows where app.status == .disbursed || app.status == .approved {
                if let sourceID = app.sourceApplicationID, let borrowerID = app.borrowerID {
                    if let loans = try? await environment.loans.fetchActiveLoans(borrowerID: borrowerID) {
                        if let loan = loans.first(where: { $0.applicationID == sourceID }) {
                            let overdueEMIs = loan.emiSchedule.filter { $0.status == .overdue }
                            if !overdueEMIs.isEmpty {
                                let totalOverdue = overdueEMIs.reduce(0) { $0 + NSDecimalNumber(decimal: $1.totalAmount).doubleValue }
                                let oldestOverdue = overdueEMIs.map { $0.dueDate }.min() ?? Date()
                                let dpd = max(0, Calendar.current.dateComponents([.day], from: oldestOverdue, to: Date()).day ?? 0)
                                
                                overdue.append(OverdueBorrower(
                                    borrowerName: app.borrowerName,
                                    borrowerInitials: app.borrowerInitials,
                                    loanId: "LN-\\(sourceID.uuidString.prefix(6).uppercased())",
                                    dpdDays: dpd,
                                    outstandingEMI: NSDecimalNumber(decimal: overdueEMIs.first!.totalAmount).doubleValue,
                                    totalOutstanding: NSDecimalNumber(decimal: loan.outstandingBalance).doubleValue,
                                    priority: dpd > 30 ? .urgent : (dpd > 15 ? .high : .normal),
                                    lastContactDate: nil,
                                    phoneNumber: app.phoneNumber,
                                    collectionEfficiency: 0.0,
                                    contactAttempts: 0
                                ))
                            }
                        }
                    }
                }
            }
            self.overdueBorrowers = overdue

            // Fetch User/Profile & Conversations
            if let user = await environment.auth.currentUser {
                var branch = "Main Branch"
                var empId = "EMP-\\(user.uniqueID)"
                if let profiles = try? await environment.admin.listStaffProfiles(),
                   let staff = profiles.first(where: { $0.id == user.id }) {
                    empId = staff.employeeID
                    if staff.branchID != nil { branch = "Assigned Branch" }
                }
                let initials = user.fullName.split(separator: " ").compactMap { $0.first.map(String.init) }.prefix(2).joined().uppercased()
                
                let total = recentApplications.count
                let approved = recentApplications.filter { $0.status == .approved || $0.status == .disbursed }.count
                let pending = recentApplications.filter { $0.status == .pending || $0.status == .underReview }.count
                let rate = total > 0 ? (Double(approved) / Double(total) * 100.0) : 0.0
                
                self.officerProfile = LoanOfficerProfile(
                    name: user.fullName,
                    designation: "Loan Officer",
                    branch: branch,
                    employeeId: empId,
                    avatarInitials: initials.isEmpty ? "U" : initials,
                    pendingTasks: pending,
                    totalApproved: approved,
                    approvalRate: rate
                )
                
                // Conversations
                if let threads = try? await environment.messaging.threads(for: user.id) {
                    var newConvos: [BorrowerConversation] = []
                    for thread in threads {
                        let msgs = (try? await environment.messaging.messages(threadID: thread.id)) ?? []
                        let loMsgs = msgs.map { m in
                            LOChatMessage(text: m.body, sender: m.senderID == user.id ? .officer : .borrower, timestamp: m.sentAt, isRead: m.readAt != nil)
                        }
                        let app = rows.first { $0.sourceApplicationID == thread.applicationID }
                        let bName = app?.borrowerName ?? "Borrower"
                        let bInitials = app?.borrowerInitials ?? "B"
                        let unread = msgs.filter { $0.readAt == nil && $0.senderID != user.id }.count
                        
                        newConvos.append(BorrowerConversation(
                            borrowerName: bName,
                            borrowerInitials: bInitials,
                            lastMessage: thread.lastMessagePreview ?? "",
                            lastMessageTime: thread.updatedAt,
                            unreadCount: unread,
                            applicationId: app?.sourceApplicationID?.uuidString ?? "",
                            messages: loMsgs.sorted { $0.timestamp < $1.timestamp },
                            isOnline: false
                        ))
                    }
                    self.conversations = newConvos.sorted { $0.lastMessageTime > $1.lastMessageTime }
                }
            }
            
            // Notifications
            if let notifs = try? await environment.notifications.fetchHistory(limit: 20) {
                self.notifications = notifs.map { n in
                    AppNotification(
                        title: n.title,
                        message: n.body,
                        type: .systemUpdate,
                        timestamp: n.receivedAt,
                        isRead: false,
                        priority: 2
                    )
                }
            }

            recalculateKPIs()
        } catch {
            // Keep the seeded sample data if the backend is unavailable.
        }
    }"""

# Need to replace the whole `private func refreshFromService() async { ... }` block
# using regex or string splitting
pattern = re.compile(r'    private func refreshFromService\(\) async \{.*?(?=    private static func makeOfficerApplication)', re.DOTALL)
content = pattern.sub(new_refresh + '\n\n', content)

with open('StaffApp/Views/LoanOfficer/LOAppViewModel.swift', 'w') as f:
    f.write(content)
