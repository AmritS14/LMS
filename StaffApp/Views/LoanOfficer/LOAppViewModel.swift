import SwiftUI
import Combine

// MARK: - App View Model
@MainActor
@Observable class AppViewModel {
    // Navigation state
    var navigationPath = NavigationPath()
    var selectedApplication: LOLoanApplication?
    var highlightMessageButton: Bool = false
    var showSideMenu: Bool = false
    var searchText: String = ""
    var selectedBranch: String = ""

    // Data — starts empty; populated by refreshFromService() from backend
    var officerProfile = LoanOfficerProfile(
        name: "",
        designation: "",
        branch: "",
        employeeId: "",
        avatarInitials: "",
        pendingTasks: 0,
        totalApproved: 0,
        approvalRate: 0
    )
    var kpiData: [KPIData] = [
        KPIData(title: "Pending\nApplications",  value: 0, trend: 0, trendUp: true,  icon: "doc.text.fill",                               color: .orange, chartData: [0, 0, 0, 0, 0, 0, 0]),
        KPIData(title: "Approved\nLoans",         value: 0, trend: 0, trendUp: true,  icon: "checkmark.circle.fill",                       color: .green,  chartData: [0, 0, 0, 0, 0, 0, 0]),
        KPIData(title: "Escalated\nCases",        value: 0, trend: 0, trendUp: false, icon: "arrow.up.circle.fill",                        color: .purple, chartData: [0, 0, 0, 0, 0, 0, 0]),
        KPIData(title: "Overdue\nBorrowers",      value: 0, trend: 0, trendUp: false, icon: "person.crop.circle.badge.exclamationmark.fill", color: Color(red: 0.8, green: 0.4, blue: 0), chartData: [0, 0, 0, 0, 0, 0, 0])
    ]
    var quickActions: [QuickAction] = [
        QuickAction(title: "Review\nApplications", icon: "doc.text.magnifyingglass",           color: .blue,   gradient: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.1, green: 0.3, blue: 0.9)], pendingCount: 0, destination: .loanReview),
        QuickAction(title: "Recovery\nManagement",  icon: "arrow.uturn.backward.circle.fill",  color: .orange, gradient: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.9, green: 0.4, blue: 0.1)], pendingCount: 0, destination: .recovery),
        QuickAction(title: "Borrower\nMessages",    icon: "bubble.left.and.bubble.right.fill", color: .indigo, gradient: [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.25, green: 0.2, blue: 0.8)], pendingCount: 0, destination: .messages)
    ]
    var recentApplications: [LOLoanApplication] = []
    var activityFeed: [ActivityItem] = []
    var notifications: [AppNotification] = []
    var overdueBorrowers: [OverdueBorrower] = []
    //var fieldVisits: [FieldVisit] = []
    var conversations: [BorrowerConversation] = []
    var digitalDocuments: [DigitalDocument] = []
    var documents: [LOLoanDocument] = []
    var collateral = CollateralInfo(
        propertyType: "",
        address: "",
        currentValuation: 0,
        lastValuationDate: Date(),
        coverageRatio: 0,
        revaluationHistory: []
    )
    var selectedConversation: BorrowerConversation?

    private var environment: AppEnvironment?
    private var officerID: UUID?

    // Dynamic KPI counters — populated from real backend data
    private var pendingCount = 0
    private var approvedCount = 0
    private var escalatedCount = 0

    // UI State
    var showApproveConfirmation = false
    var showRejectConfirmation = false
    var showEscalateSheet = false
    var showDocumentRequest = false
    var showSearchBar = false
    var showBranchSelector = false

    // Computed
    var unreadNotifications: Int {
        notifications.filter { !$0.isRead }.count
    }

    var totalPendingTasks: Int {
        kpiData.reduce(0) { $0 + $1.value }
    }

    var branches: [String] {
        // Populated from the backend; fallback to current branch if available
        guard !selectedBranch.isEmpty else { return [] }
        return [selectedBranch]
    }

    var filteredApplications: [LOLoanApplication] {
        if searchText.isEmpty {
            return recentApplications
        }
        return recentApplications.filter { app in
            app.borrowerName.localizedCaseInsensitiveContains(searchText) ||
            app.loanType.localizedCaseInsensitiveContains(searchText) ||
            app.status.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    func configure(environment: AppEnvironment) {
        self.environment = environment
        Task { await refreshFromService() }
    }

    func ensureThread(for application: LOLoanApplication) {
        guard let environment,
              let appID = application.sourceApplicationID,
              let borrowerID = application.borrowerID,
              let officerID else { return }
        Task {
            _ = try? await environment.messaging.ensureThread(
                applicationID: appID,
                participantIDs: [officerID, borrowerID]
            )
        }
    }

    private func refreshFromService() async {
        guard let environment else { return }

        if officerID == nil {
            officerID = (await environment.auth.currentUser)?.id
        }

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
            self.recentApplications = rows
            
            // Build Activity Feed
            var feed: [ActivityItem] = []
            for app in rows {
                for event in app.timeline {
                    let type: ActivityType = event.status == .approved ? .approved : (event.status == .escalated ? .escalation : .newApplication)
                    feed.append(ActivityItem(title: event.title, subtitle: "\(app.borrowerName) — \(event.description)", type: type, timestamp: event.timestamp))
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
                                    loanId: "LN-\(sourceID.uuidString.prefix(6).uppercased())",
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
                var branch = ""
                var empId = user.uniqueID
                if let profiles = try? await environment.admin.listStaffProfiles(),
                   let staff = profiles.first(where: { $0.id == user.id }) {
                    empId = staff.employeeID
                    // branchID is available but branch name requires a separate lookup;
                    // store a sentinel so the UI can show "Branch Assigned" if needed.
                    if staff.branchID != nil { branch = "Branch Assigned" }
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
    }

    private static func makeOfficerApplication(
        from app: LoanApplication,
        events: [ApplicationEvent],
        documents: [LoanDocument] = []
    ) -> LOLoanApplication {
        let name = app.borrowerName ?? "Borrower"
        let initials = name
            .split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
            .uppercased()
        let amount = NSDecimalNumber(decimal: app.requestedAmount).doubleValue
        let officerStatus = app.status.officerStatus

        let loDocuments = documents.map(Self.makeOfficerDocument)
        // Derive KYC status from the real document vault.
        let kyc: LOKYCStatus
        if loDocuments.isEmpty {
            kyc = .pending
        } else if loDocuments.allSatisfy({ $0.status == .verified }) {
            kyc = .verified
        } else if loDocuments.contains(where: { $0.status == .rejected }) {
            kyc = .partial
        } else {
            kyc = .pending
        }

        let timeline: [TimelineEvent] = events
            .sorted { $0.createdAt > $1.createdAt }
            .map { event in
                TimelineEvent(
                    title: Self.eventTitle(event.eventType),
                    description: event.remark ?? Self.eventTitle(event.eventType),
                    timestamp: event.createdAt,
                    status: officerStatus,
                    officerName: ""
                )
            }

        // Derive risk level from document statuses (no credit score available from backend yet)
        let riskLevel: RiskLevel
        let hasBlockerDocs = loDocuments.contains(where: { $0.status == .tampered || $0.status == .missing })
        if hasBlockerDocs {
            riskLevel = .high
        } else if loDocuments.contains(where: { $0.status == .pending || $0.status == .needsReview || $0.status == .rejected }) {
            riskLevel = .medium
        } else if loDocuments.isEmpty {
            riskLevel = .medium  // Unknown — no docs to evaluate
        } else {
            riskLevel = .low
        }

        return LOLoanApplication(
            sourceApplicationID: app.id,
            borrowerID: app.borrowerID,
            borrowerName: name,
            borrowerInitials: initials.isEmpty ? "?" : initials,
            creditScore: 0,          // Not available from backend — shown as "—" in UI
            loanAmount: amount,
            riskLevel: riskLevel,
            kycStatus: kyc,
            fraudFlag: false,        // Fraud flagging not yet surfaced in this API response
            status: officerStatus,
            applicationDate: app.createdAt,
            loanType: app.productName ?? (app.loanType.rawValue.capitalized + " Loan"),
            tenure: app.tenureMonths,
            interestRate: app.interestRate,
            employmentType: "—",     // Not in current API response
            employer: "—",           // Not in current API response
            monthlyIncome: 0,        // Not in current API response
            existingLiabilities: 0,  // Not in current API response
            eligibilityScore: 0,     // Computed server-side; not yet returned
            emiAmount: amount / Double(max(app.tenureMonths, 1)),
            phoneNumber: app.borrowerPhone ?? "—",
            email: app.borrowerEmail ?? "—",
            address: "—",            // Not in current API response
            purpose: "—",            // Not in current API response
            documents: loDocuments,
            timeline: timeline
        )
    }

    /// Maps a backend document to the officer's rich document model.
    private static func makeOfficerDocument(_ doc: LoanDocument) -> LOLoanDocument {
        let status: DocumentStatus
        switch doc.status {
        case .verified: status = .verified
        case .rejected: status = .rejected
        case .pending:  status = .needsReview
        }
        let (type, icon): (String, String)
        switch doc.kind {
        case .identityProof: (type, icon) = ("Identity Proof", "person.text.rectangle.fill")
        case .addressProof:  (type, icon) = ("Address Proof", "house.fill")
        case .incomeProof:   (type, icon) = ("Income Proof", "doc.text.fill")
        case .bankStatement: (type, icon) = ("Bank Statement", "building.columns.fill")
        case .collateral:    (type, icon) = ("Collateral", "shield.fill")
        case .other:         (type, icon) = ("Document", "doc.fill")
        }
        return LOLoanDocument(
            sourceDocumentID: doc.id,
            name: doc.fileName,
            type: type,
            status: status,
            uploadDate: doc.uploadedAt,
            ocrVerified: doc.status == .verified,
            icon: icon
        )
    }

    // Maps a free-form requested document name to the backend's documentType enum.
    private static func backendDocumentType(_ name: String) -> String {
        let n = name.lowercased()
        if n.contains("pan") { return "pan_card" }
        if n.contains("aadhaar") || n.contains("aadhar") { return "aadhaar_card" }
        if n.contains("salary") { return "salary_slip" }
        if n.contains("bank") { return "bank_statement" }
        if n.contains("itr") || n.contains("tax") { return "itr" }
        if n.contains("photo") || n.contains("passport") { return "passport_photo" }
        if n.contains("employment") || n.contains("employer") { return "employment_certificate" }
        if n.contains("address") { return "address_proof" }
        return "other"
    }

    private static func eventTitle(_ rawType: String) -> String {
        switch rawType {
        case "submitted": return "Application Submitted"
        case "auto_assigned", "assigned": return "Assigned to Officer"
        case "review_started": return "Review Started"
        case "documents_requested": return "Documents Requested"
        case "documents_uploaded": return "Documents Uploaded"
        case "sent_to_manager": return "Sent to Manager"
        case "approved": return "Approved"
        case "rejected": return "Rejected"
        case "loan_disbursed": return "Loan Disbursed"
        default: return rawType.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func recalculateKPIs() {
        pendingCount = recentApplications.filter { $0.status == .pending || $0.status == .underReview }.count
        approvedCount = recentApplications.filter { $0.status == .approved || $0.status == .disbursed }.count
        escalatedCount = recentApplications.filter { $0.status == .escalated }.count
        updateKPIs()
    }

    private func syncStatus(
        for application: LOLoanApplication,
        to status: ApplicationStatus,
        note: String?
    ) {
        guard let environment, let sourceApplicationID = application.sourceApplicationID else { return }

        Task {
            try? await environment.loans.updateStatus(
                applicationID: sourceApplicationID,
                to: status,
                note: note
            )
        }
    }

    // Actions
    func updateKPIs() {
        let overdueCount = overdueBorrowers.count
        kpiData = [
            KPIData(title: "Pending\nApplications", value: pendingCount, trend: 0, trendUp: true, icon: "doc.text.fill", color: .orange, chartData: [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.75]),
            KPIData(title: "Approved\nLoans", value: approvedCount, trend: 0, trendUp: true, icon: "checkmark.circle.fill", color: .green, chartData: [0.4, 0.5, 0.55, 0.6, 0.65, 0.7, 0.8]),
            KPIData(title: "Escalated\nCases", value: escalatedCount, trend: 0, trendUp: false, icon: "arrow.up.circle.fill", color: .purple, chartData: [0.6, 0.7, 0.5, 0.4, 0.45, 0.35, 0.3]),
            KPIData(title: "Overdue\nBorrowers", value: overdueCount, trend: 0, trendUp: false, icon: "person.crop.circle.badge.exclamationmark.fill", color: Color(red: 0.8, green: 0.4, blue: 0), chartData: [0.7, 0.65, 0.6, 0.55, 0.5, 0.45, 0.4])
        ]
    }

    func approveApplication(_ app: LOLoanApplication, remarks: String) {
        if let index = recentApplications.firstIndex(where: { $0.id == app.id }) {
            let prevStatus = recentApplications[index].status
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                recentApplications[index].status = .approved
                
                // Add timeline event
                let event = TimelineEvent(
                    title: "Approved & Recommended",
                    description: "Recommended for final approval by \(officerProfile.name.isEmpty ? "Loan Officer" : officerProfile.name). Remarks: \(remarks.isEmpty ? "No remarks provided" : remarks)",
                    timestamp: Date(),
                    status: .approved,
                    officerName: officerProfile.name
                )
                recentApplications[index].timeline.insert(event, at: 0)
                
                // Update selection
                if selectedApplication?.id == app.id {
                    selectedApplication = recentApplications[index]
                }
                
                // Update KPI counters
                if prevStatus == .pending || prevStatus == .underReview {
                    pendingCount = max(0, pendingCount - 1)
                } else if prevStatus == .escalated {
                    escalatedCount = max(0, escalatedCount - 1)
                }
                approvedCount += 1
                updateKPIs()
                syncStatus(for: recentApplications[index], to: .recommended, note: remarks)
                
                // Prepend to activity feed
                let activity = ActivityItem(
                    title: "Application Approved",
                    subtitle: "\(app.borrowerName) — Approved for \(AppFormatters.formatCurrency(app.loanAmount))",
                    type: .approved,
                    timestamp: Date()
                )
                activityFeed.insert(activity, at: 0)
            }
        }
    }

    func rejectApplication(_ app: LOLoanApplication, remarks: String) {
        if let index = recentApplications.firstIndex(where: { $0.id == app.id }) {
            let prevStatus = recentApplications[index].status
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                recentApplications[index].status = .rejected
                
                // Add timeline event
                let event = TimelineEvent(
                    title: "Application Rejected",
                    description: "Rejected by \(officerProfile.name.isEmpty ? "Loan Officer" : officerProfile.name). Remarks: \(remarks.isEmpty ? "No remarks provided" : remarks)",
                    timestamp: Date(),
                    status: .rejected,
                    officerName: officerProfile.name
                )
                recentApplications[index].timeline.insert(event, at: 0)
                
                // Update selection
                if selectedApplication?.id == app.id {
                    selectedApplication = recentApplications[index]
                }
                
                // Update KPI counters
                if prevStatus == .pending || prevStatus == .underReview {
                    pendingCount = max(0, pendingCount - 1)
                } else if prevStatus == .escalated {
                    escalatedCount = max(0, escalatedCount - 1)
                }
                updateKPIs()
                syncStatus(for: recentApplications[index], to: .rejected, note: remarks)
            }
        }
    }

    func escalateApplication(_ app: LOLoanApplication, remarks: String) {
        if let index = recentApplications.firstIndex(where: { $0.id == app.id }) {
            let prevStatus = recentApplications[index].status
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                recentApplications[index].status = .escalated
                
                // Add timeline event
                let event = TimelineEvent(
                    title: "Escalated to Manager",
                    description: "Escalated by \(officerProfile.name.isEmpty ? "Loan Officer" : officerProfile.name). Notes: \(remarks.isEmpty ? "No escalation notes provided" : remarks)",
                    timestamp: Date(),
                    status: .escalated,
                    officerName: officerProfile.name
                )
                recentApplications[index].timeline.insert(event, at: 0)
                
                // Update selection
                if selectedApplication?.id == app.id {
                    selectedApplication = recentApplications[index]
                }
                
                // Update KPI counters
                if prevStatus == .pending || prevStatus == .underReview {
                    pendingCount = max(0, pendingCount - 1)
                    escalatedCount += 1
                }
                updateKPIs()
                syncStatus(for: recentApplications[index], to: .escalated, note: remarks)
                
                // Add escalation warning to activity feed
                let activity = ActivityItem(
                    title: "Escalation raised",
                    subtitle: "\(app.borrowerName) — KYC Escalation",
                    type: .escalation,
                    timestamp: Date()
                )
                activityFeed.insert(activity, at: 0)
            }
        }
    }

    func requestDocument(_ app: LOLoanApplication, docName: String, note: String) {
        guard !docName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        if let index = recentApplications.firstIndex(where: { $0.id == app.id }) {
            withAnimation {
                // 1. Create or update document status to .pending
                let existingIndex = recentApplications[index].documents.firstIndex(where: { $0.name.localizedCaseInsensitiveCompare(docName) == .orderedSame })
                if let docIdx = existingIndex {
                    recentApplications[index].documents[docIdx].status = .pending
                    recentApplications[index].documents[docIdx].uploadDate = nil
                } else {
                    let newDoc = LOLoanDocument(
                        name: docName,
                        type: "Additional Info",
                        status: .pending,
                        uploadDate: nil,
                        ocrVerified: false,
                        icon: "doc.badge.plus"
                    )
                    recentApplications[index].documents.append(newDoc)
                }
                
                // 2. Add Timeline Event
                let timelineEvent = TimelineEvent(
                    title: "Document Requested",
                    description: "Requested: \(docName). Note: \(note.isEmpty ? "Please upload this document for verification" : note)",
                    timestamp: Date(),
                    status: recentApplications[index].status,
                    officerName: officerProfile.name
                )
                recentApplications[index].timeline.insert(timelineEvent, at: 0)
                
                // 3. Add to chat history
                if let chatIndex = conversations.firstIndex(where: { $0.borrowerName.localizedCaseInsensitiveContains(app.borrowerName) }) {
                    let chatMsg = LOChatMessage(
                        text: "⚠️ REQUEST FOR DOCUMENT: [\(docName)]\nNotes: \(note.isEmpty ? "Please upload this document for verification." : note)",
                        sender: .officer,
                        timestamp: Date(),
                        isRead: true
                    )
                    conversations[chatIndex].messages.append(chatMsg)
                    conversations[chatIndex].lastMessage = "Requested \(docName)"
                    conversations[chatIndex].lastMessageTime = Date()
                }
                
                // 4. Trigger Notification
                let notification = AppNotification(
                    title: "Document Request Sent",
                    message: "Requested \(docName) from \(app.borrowerName)",
                    type: .documentRequest,
                    timestamp: Date(),
                    isRead: false,
                    priority: 2
                )
                notifications.insert(notification, at: 0)
                
                // Update selectedApplication
                if selectedApplication?.id == app.id {
                    selectedApplication = recentApplications[index]
                }
            }
        }
    }

    func simulateBorrowerResubmission(for app: LOLoanApplication) {
        if let index = recentApplications.firstIndex(where: { $0.id == app.id }) {
            withAnimation {
                var resubmittedCount = 0
                for docIdx in recentApplications[index].documents.indices {
                    let doc = recentApplications[index].documents[docIdx]
                    if doc.status == .pending || doc.status == .missing || doc.status == .tampered {
                        recentApplications[index].documents[docIdx].status = .verified
                        recentApplications[index].documents[docIdx].uploadDate = Date()
                        recentApplications[index].documents[docIdx].ocrVerified = true
                        resubmittedCount += 1
                        
                        let timelineEvent = TimelineEvent(
                            title: "Document Submitted",
                            description: "\(doc.name) resubmitted by borrower and verified successfully.",
                            timestamp: Date(),
                            status: recentApplications[index].status,
                            officerName: "System"
                        )
                        recentApplications[index].timeline.insert(timelineEvent, at: 0)
                    }
                }
                
                if resubmittedCount > 0 {
                    recentApplications[index].kycStatus = .verified
                    recentApplications[index].fraudFlag = false
                    
                    if let chatIndex = conversations.firstIndex(where: { $0.borrowerName.localizedCaseInsensitiveContains(app.borrowerName) }) {
                        let chatMsg = LOChatMessage(
                            text: "I have uploaded the requested documents. Please check.",
                            sender: .borrower,
                            timestamp: Date(),
                            isRead: false
                        )
                        conversations[chatIndex].messages.append(chatMsg)
                        conversations[chatIndex].lastMessage = "I have uploaded the documents."
                        conversations[chatIndex].lastMessageTime = Date()
                        conversations[chatIndex].unreadCount += 1
                    }
                    
                    let notification = AppNotification(
                        title: "Document Uploaded: \(app.borrowerName)",
                        message: "Borrower submitted the requested documents.",
                        type: .assignedApplication,
                        timestamp: Date(),
                        isRead: false,
                        priority: 2
                    )
                    notifications.insert(notification, at: 0)
                }
                
                if selectedApplication?.id == app.id {
                    selectedApplication = recentApplications[index]
                }
            }
        }
    }

    func simulateBorrowerDocumentResubmission(for app: LOLoanApplication, documentId: UUID) {
        if let index = recentApplications.firstIndex(where: { $0.id == app.id }) {
            if let docIdx = recentApplications[index].documents.firstIndex(where: { $0.id == documentId }) {
                withAnimation {
                    let doc = recentApplications[index].documents[docIdx]
                    recentApplications[index].documents[docIdx].status = .verified
                    recentApplications[index].documents[docIdx].uploadDate = Date()
                    recentApplications[index].documents[docIdx].ocrVerified = true
                    recentApplications[index].documents[docIdx].reviewNotes = nil
                    recentApplications[index].documents[docIdx].rejectionReason = nil
                    
                    let timelineEvent = TimelineEvent(
                        title: "Document Submitted",
                        description: "\(doc.name) resubmitted by borrower and verified successfully.",
                        timestamp: Date(),
                        status: recentApplications[index].status,
                        officerName: "System"
                    )
                    recentApplications[index].timeline.insert(timelineEvent, at: 0)
                    
                    // Re-evaluate application's kycStatus
                    let allVerified = recentApplications[index].documents.allSatisfy { $0.status == .verified }
                    if allVerified {
                        recentApplications[index].kycStatus = .verified
                        recentApplications[index].fraudFlag = false
                    } else {
                        recentApplications[index].kycStatus = .partial
                    }
                    
                    // Add chat message
                    if let chatIndex = conversations.firstIndex(where: { $0.borrowerName.localizedCaseInsensitiveContains(app.borrowerName) }) {
                        let chatMsg = LOChatMessage(
                            text: "I have uploaded the requested document: \(doc.name).",
                            sender: .borrower,
                            timestamp: Date(),
                            isRead: false
                        )
                        conversations[chatIndex].messages.append(chatMsg)
                        conversations[chatIndex].lastMessage = "Uploaded \(doc.name)."
                        conversations[chatIndex].lastMessageTime = Date()
                        conversations[chatIndex].unreadCount += 1
                    }
                    
                    // Add notification
                    let notification = AppNotification(
                        title: "Document Uploaded: \(app.borrowerName)",
                        message: "Borrower submitted the requested document: \(doc.name).",
                        type: .assignedApplication,
                        timestamp: Date(),
                        isRead: false,
                        priority: 2
                    )
                    notifications.insert(notification, at: 0)
                    
                    // Sync selected application
                    if selectedApplication?.id == app.id {
                        selectedApplication = recentApplications[index]
                    }
                }
            }
        }
    }

    func updateDocumentReview(for app: LOLoanApplication, documentId: UUID, status: DocumentStatus, reviewNotes: String?, rejectionReason: String?) {
        if let appIdx = recentApplications.firstIndex(where: { $0.id == app.id }) {
            if let docIdx = recentApplications[appIdx].documents.firstIndex(where: { $0.id == documentId }) {
                withAnimation {
                    recentApplications[appIdx].documents[docIdx].status = status
                    recentApplications[appIdx].documents[docIdx].reviewNotes = reviewNotes
                    recentApplications[appIdx].documents[docIdx].rejectionReason = rejectionReason
                    
                    // If it is verified, make sure uploadDate is set
                    if status == .verified {
                        recentApplications[appIdx].documents[docIdx].uploadDate = Date()
                        recentApplications[appIdx].documents[docIdx].ocrVerified = true
                    }
                    
                    // Add a timeline event
                    let docName = recentApplications[appIdx].documents[docIdx].name
                    var desc = "\(docName) marked as \(status.rawValue)."
                    if let notes = reviewNotes, !notes.isEmpty {
                        desc += " Notes: \(notes)"
                    }
                    if let reason = rejectionReason, !reason.isEmpty {
                        desc += " Reason: \(reason)"
                    }
                    
                    let timelineEvent = TimelineEvent(
                        title: "Document Reviewed",
                        description: desc,
                        timestamp: Date(),
                        status: recentApplications[appIdx].status,
                        officerName: officerProfile.name
                    )
                    recentApplications[appIdx].timeline.insert(timelineEvent, at: 0)
                    
                    // Re-evaluate application's kycStatus
                    let allVerified = recentApplications[appIdx].documents.allSatisfy { $0.status == .verified }
                    if allVerified {
                        recentApplications[appIdx].kycStatus = .verified
                        recentApplications[appIdx].fraudFlag = false
                    } else if recentApplications[appIdx].documents.contains(where: { $0.status == .needsReview || $0.status == .tampered || $0.status == .missing || $0.status == .rejected }) {
                        recentApplications[appIdx].kycStatus = .partial
                    }
                    
                    // Sync selected application
                    if selectedApplication?.id == app.id {
                        selectedApplication = recentApplications[appIdx]
                    }
                }
            }
        }
    }

    func markNotificationRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
    }

    func deleteNotification(_ notification: AppNotification) {
        notifications.removeAll(where: { $0.id == notification.id })
    }

    func markAllNotificationsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
    }

    func markBorrowerContacted(_ borrower: OverdueBorrower) {
        if let index = overdueBorrowers.firstIndex(where: { $0.id == borrower.id }) {
            overdueBorrowers[index].lastContactDate = Date()
            overdueBorrowers[index].contactAttempts += 1
        }
    }

    // Greeting
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 17 { return "Good Afternoon" }
        return "Good Evening"
    }
}
