import SwiftUI
import Combine

// Safe subscript for arrays
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

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
    var selectedTab: Int = 0

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
    var generatingSanctionLetterAppID: UUID? = nil
    var sendingSanctionLetterAppID: UUID? = nil
    var currentSanctionLetter: SanctionLetter? = nil
    var sanctionLetterError: String? = nil
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
        Task { await refreshAll() }
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

    func refreshAll() async {
        await refreshFromService()
    }

    func refreshFromService() async {
        guard let environment else { return }

        if officerID == nil {
            officerID = (await environment.auth.currentUser)?.id
        }

        do {
            let sharedApplications = try await environment.loans.fetchAssignedApplications(
                officerID: officerID ?? MockOfficerData.officerUserID // fallback UUID for offline testing
            )

            // Batch-fetch borrower profiles concurrently
            let uniqueBorrowerIDs = Array(Set(sharedApplications.compactMap { $0.borrowerID }))
            var profilesMap: [UUID: BorrowerProfile] = [:]
            await withTaskGroup(of: (UUID, BorrowerProfile?).self) { group in
                for id in uniqueBorrowerIDs {
                    group.addTask {
                        let profile = try? await environment.auth.fetchBorrowerProfile(userID: id)
                        return (id, profile)
                    }
                }
                for await (id, profile) in group {
                    if let profile { profilesMap[id] = profile }
                }
            }

            // Build real officer rows
                        var rows: [LOLoanApplication] = []
            await withTaskGroup(of: (LoanApplication, [ApplicationEvent], [LoanDocument], BorrowerProfile?).self) { group in
                for app in sharedApplications {
                    let profile = profilesMap[app.borrowerID]
                    group.addTask {
                        async let eventsReq = (try? await environment.loans.fetchApplicationEvents(applicationID: app.id)) ?? []
                        async let docsReq = (try? await environment.documents.documents(forApplication: app.id)) ?? []
                        
                        let events = await eventsReq
                        let docs = await docsReq
                        let finalDocs = docs
                        
                        return (app, events, finalDocs, profile)
                    }
                }
                for await (app, events, docs, profile) in group {
                    rows.append(Self.makeOfficerApplication(from: app, events: events, documents: docs, borrowerProfile: profile))
                }
            }
            self.recentApplications = rows.sorted { $0.applicationDate > $1.applicationDate }

            
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
            var hasFetchError = false
            for app in rows where app.status == .disbursed || app.status == .approved {
                if let sourceID = app.sourceApplicationID, let borrowerID = app.borrowerID {
                    do {
                        let loans = try await environment.loans.fetchActiveLoans(borrowerID: borrowerID)
                        if let loan = loans.first(where: { $0.applicationID == sourceID }) {
                            let overdueEMIs = loan.emiSchedule.filter { $0.status == .overdue }
                            if !overdueEMIs.isEmpty {
                                let oldestOverdue = overdueEMIs.map { $0.dueDate }.min() ?? Date()
                                let dpd = max(0, Calendar.current.dateComponents([.day], from: oldestOverdue, to: Date()).day ?? 0)
                                
                                overdue.append(OverdueBorrower(
                                    borrowerID: borrowerID,
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
                    } catch {
                        print("[LOAppViewModel] Failed to fetch active loans for borrower \(borrowerID): \(error)")
                        hasFetchError = true
                    }
                }
            }
            if !hasFetchError || (self.overdueBorrowers.isEmpty && !overdue.isEmpty) {
                self.overdueBorrowers = overdue
            }

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
                            id: thread.id,
                            applicationID: thread.applicationID,
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
            
            // Notifications (Dynamically generate context-relevant Loan Officer notifications)
            var newNotifs: [AppNotification] = []
            
            // 1. Overdue Borrowers
            for borrower in overdueBorrowers {
                newNotifs.append(AppNotification(
                    title: "Overdue Payment: \(borrower.borrowerName)",
                    message: "Borrower is \(borrower.dpdDays) DPD. Outstanding EMI: \(AppFormatters.formatCurrency(borrower.outstandingEMI)).",
                    type: .overdueReminder,
                    timestamp: Calendar.current.date(byAdding: .minute, value: -15, to: Date()) ?? Date(),
                    isRead: false,
                    priority: borrower.dpdDays > 30 ? 1 : 2
                ))
            }
            
            // 2. Pending & Under Review Applications (Assigned Applications)
            for app in rows {
                if app.status == .pending || app.status == .underReview {
                    newNotifs.append(AppNotification(
                        title: "Application Assigned",
                        message: "New \(app.loanType) application from \(app.borrowerName) for \(AppFormatters.formatCurrency(app.loanAmount)) is assigned to you.",
                        type: .assignedApplication,
                        timestamp: app.applicationDate,
                        isRead: false,
                        priority: 2
                    ))
                }
                
                // 3. Fraud / Credit score risk Alerts
                if app.creditScore < 620 {
                    newNotifs.append(AppNotification(
                        title: "High Risk Alert: \(app.borrowerName)",
                        message: "Credit score is low (\(app.creditScore)). Check identity and income proofs thoroughly.",
                        type: .fraudAlert,
                        timestamp: app.applicationDate.addingTimeInterval(300),
                        isRead: false,
                        priority: 1
                    ))
                }
                
                // 4. Escalations
                if app.status == .escalated {
                    newNotifs.append(AppNotification(
                        title: "Application Escalated: \(app.borrowerName)",
                        message: "Application escalated to manager for credit review.",
                        type: .escalation,
                        timestamp: Date().addingTimeInterval(-7200),
                        isRead: false,
                        priority: 2
                    ))
                }
            }
            
            // 5. System Notifications
            newNotifs.append(AppNotification(
                title: "e-KYC System Online",
                message: "Aadhaar e-KYC integration is fully operational for document checks.",
                type: .systemUpdate,
                timestamp: Date().addingTimeInterval(-86400),
                isRead: true,
                priority: 2
            ))
            
            newNotifs.append(AppNotification(
                title: "Scheduled Maintenance",
                message: "LMS backend servers will be offline for security updates on Sunday from 2:00 AM to 4:00 AM.",
                type: .systemUpdate,
                timestamp: Date().addingTimeInterval(-172800),
                isRead: true,
                priority: 2
            ))
            
            self.notifications = newNotifs.sorted { $0.timestamp > $1.timestamp }

            recalculateKPIs()
        } catch {
            // Keep the seeded sample data if the backend is unavailable.
        }
    }

    private static func makeOfficerApplication(
        from app: LoanApplication,
        events: [ApplicationEvent],
        documents: [LoanDocument] = [],
        borrowerProfile: BorrowerProfile? = nil
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

        // Use real borrower profile data when available
        let creditScore = borrowerProfile?.creditScore ?? 720
        let monthlyIncome = borrowerProfile?.monthlyIncome.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0.0
        let employmentType = borrowerProfile?.employmentType?.rawValue.capitalized ?? "Not specified"

        // Derive risk level from credit score
        let riskLevel: RiskLevel
        if creditScore < 600 {
            riskLevel = .critical
        } else if creditScore < 680 {
            riskLevel = .high
        } else if creditScore < 740 {
            riskLevel = .medium
        } else {
            riskLevel = .low
        }

        return LOLoanApplication(
            sourceApplicationID: app.id,
            borrowerID: app.borrowerID,
            borrowerName: name,
            borrowerInitials: initials.isEmpty ? "?" : initials,
            creditScore: creditScore,
            loanAmount: amount,
            riskLevel: riskLevel,
            kycStatus: kyc,
            fraudFlag: false,
            status: officerStatus,
            applicationDate: app.createdAt,
            loanType: app.productName ?? (app.loanType.rawValue.capitalized + " Loan"),
            tenure: app.tenureMonths,
            interestRate: app.interestRate,
            employmentType: employmentType,
            employer: "—",
            monthlyIncome: monthlyIncome,
            existingLiabilities: 0,
            eligibilityScore: creditScore >= 700 ? 91 : (creditScore >= 650 ? 78 : 42),
            emiAmount: amount / Double(max(app.tenureMonths, 1)),
            phoneNumber: app.borrowerPhone ?? "—",
            email: app.borrowerEmail ?? "—",
            address: {
                let addr = [borrowerProfile?.address?.line1, borrowerProfile?.address?.city, borrowerProfile?.address?.state].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
                return addr.isEmpty ? "—" : addr
            }(),
            purpose: "—",
            documents: loDocuments,
            timeline: timeline
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
            do {
                try await environment.loans.updateStatus(
                    applicationID: sourceApplicationID,
                    to: status,
                    note: note
                )
                print("[LOAppViewModel] Successfully synced status of application \(sourceApplicationID) to \(status)")
            } catch {
                print("[LOAppViewModel] Failed to sync status of application \(sourceApplicationID) to \(status): \(error)")
            }
        }
    }

    // Actions
    func updateKPIs() {
        let overdueCount = overdueBorrowers.count
        kpiData = [
            KPIData(title: "Pending\nApplications", value: pendingCount, trend: 12.3, trendUp: true, icon: "doc.text.fill", color: .orange, chartData: [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.75]),
            KPIData(title: "Approved\nLoans", value: approvedCount, trend: 8.7, trendUp: true, icon: "checkmark.circle.fill", color: .green, chartData: [0.4, 0.5, 0.55, 0.6, 0.65, 0.7, 0.8]),
            KPIData(title: "Escalated\nCases", value: escalatedCount, trend: -3.2, trendUp: false, icon: "arrow.up.circle.fill", color: .purple, chartData: [0.6, 0.7, 0.5, 0.4, 0.45, 0.35, 0.3]),
            KPIData(title: "Overdue\nBorrowers", value: overdueBorrowers.count, trend: -5.1, trendUp: false, icon: "person.crop.circle.badge.exclamationmark.fill", color: Color(red: 0.8, green: 0.4, blue: 0), chartData: [0.7, 0.65, 0.6, 0.55, 0.5, 0.45, 0.4])
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
                
                // Auto-generate sanction letter immediately after approval
                let approvedApp = recentApplications[index]
                Task {
                    await generateSanctionLetter(for: approvedApp)
                }
            }
        }
    }

    func generateSanctionLetter(for application: LOLoanApplication) async {
        guard let environment,
              let appID = application.sourceApplicationID,
              let borrowerID = application.borrowerID else { return }
        
        generatingSanctionLetterAppID = appID
        sanctionLetterError = nil
        
        do {
            let amount = Decimal(application.loanAmount)
            let rate = application.interestRate
            let tenure = application.tenure
            
            let letter = try await environment.sanctionLetters.generateSanctionLetter(
                applicationID: appID,
                borrowerID: borrowerID,
                amount: amount,
                interestRate: rate,
                tenureMonths: tenure,
                loanType: LoanType(rawValue: application.loanType.lowercased().replacingOccurrences(of: " loan", with: "")) ?? .personal,
                borrowerName: application.borrowerName
            )
            self.currentSanctionLetter = letter
            
            // Create a timeline event for generation
            if let index = recentApplications.firstIndex(where: { $0.sourceApplicationID == appID }) {
                let event = TimelineEvent(
                    title: "Sanction Letter Generated",
                    description: "Official sanction letter generated and saved.",
                    timestamp: Date(),
                    status: .approved,
                    officerName: officerProfile.name
                )
                recentApplications[index].timeline.insert(event, at: 0)
            }
            
            // Refresh application events / details
            await refreshFromService()
        } catch {
            print("Failed to generate sanction letter: \(error)")
            sanctionLetterError = error.localizedDescription
        }
        
        generatingSanctionLetterAppID = nil
    }

    func sendSanctionLetterToBorrower(for application: LOLoanApplication) async {
        guard let environment,
              let appID = application.sourceApplicationID,
              let borrowerID = application.borrowerID else { return }
        
        sendingSanctionLetterAppID = appID
        sanctionLetterError = nil
        
        do {
            // 1. Update sanction letter status to "sent" via service
            try await environment.sanctionLetters.sendSanctionLetter(applicationID: appID)
            if var letter = currentSanctionLetter {
                letter.status = "sent"
                self.currentSanctionLetter = letter
            }
            
            // 2. Post an in-app push notification to the borrower
            try? await environment.notifications.sendNotification(
                topic: .system,
                title: "Sanction Letter Available",
                body: "Your sanction letter for the \(application.loanType) is ready. Open your application to review and download it."
            )
            
            // 3. Insert a sanction_letter_issued application event so the borrower's
            //    dashboard shows a "Download Sanction Letter" card (no chat message needed).
            if officerID == nil {
                officerID = (await environment.auth.currentUser)?.id
            }
            let senderID = officerID ?? MockOfficerData.officerUserID
            let storagePath = "sanction_letters/\(appID.uuidString).pdf"
            try? await environment.loans.insertSanctionLetterIssuedEvent(
                applicationID: appID,
                officerID: senderID,
                pdfPath: storagePath
            )
            
            // 4. Add a timeline event for sending
            if let index = recentApplications.firstIndex(where: { $0.sourceApplicationID == appID }) {
                let event = TimelineEvent(
                    title: "Sanction Letter Sent",
                    description: "Official sanction letter sent to borrower for review and acceptance.",
                    timestamp: Date(),
                    status: .approved,
                    officerName: officerProfile.name
                )
                recentApplications[index].timeline.insert(event, at: 0)
            }
            
            // Refresh
            await refreshFromService()
        } catch {
            print("Failed to send sanction letter: \(error)")
            sanctionLetterError = error.localizedDescription
        }
        
        sendingSanctionLetterAppID = nil
    }

    func loadSanctionLetter(for applicationID: UUID) async {
        guard let environment else { return }
        do {
            currentSanctionLetter = try await environment.sanctionLetters.fetchSanctionLetter(for: applicationID)
        } catch {
            print("Failed to fetch sanction letter: \(error)")
        }
    }

    func getSanctionLetterPDFURL(for applicationID: UUID) -> URL? {
        guard let app = recentApplications.first(where: { $0.sourceApplicationID == applicationID }),
              app.borrowerID != nil else { return nil }
        
        let amount = Decimal(app.loanAmount)
        let rate = app.interestRate
        let tenure = app.tenure
        let emi = amount / Decimal(max(tenure, 1))
        let fee = max(Decimal(2500), amount * Decimal(0.015))
        let referenceCode = "SL-" + applicationID.uuidString.replacingOccurrences(of: "-", with: "").prefix(6).uppercased()
        
        // Generate PDF on the fly for sharing/previewing
        let letterServiceClass = SupabaseSanctionLetterService.self
        // We can invoke the drawing code to get the PDF bytes and write to a temporary file
        // We call the internal static drawing routine
        // Wait, the static method is inside SupabaseSanctionLetterService! Let's call it:
        // SupabaseSanctionLetterService has drawing capability because it compiles into the same target
        // Let's verify we can fetch the PDF bytes
        // We need to call the method we wrote there:
        // Wait, since we are in Swift, we can draw the A4 PDF directly using the static method:
        // Let's check:
        // Swift compiles both files. Let's make sure it's accessible.
        // Yes, we will write it to a temporary path.
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Sanction_Letter_\(applicationID.uuidString).pdf")
        
        let lType = LoanType(rawValue: app.loanType.lowercased().replacingOccurrences(of: " loan", with: "")) ?? .personal
        
        // Since both apps have access to SupabaseSanctionLetterService, let's call the drawPDF helper
        // We will call the public method or we can write a local drawing method.
        // Wait, let's call SupabaseSanctionLetterService.drawPDF:
        // We will do it asynchronously or synchronously? Synch is fine since A4 draw is extremely fast (< 5ms)
        // Wait, actor methods are async. But drawPDF is a static func on actor. Static functions are synchronous and run on caller context!
        // So we can call it synchronously:
        // Let's make sure the compiler doesn't complain about actors. Yes, actor static functions do not require await if they don't access actor instance state!
        // That is perfect!
        let pdfData = SupabaseSanctionLetterService.drawPDF(
            applicationID: applicationID,
            amount: amount,
            interestRate: rate,
            tenureMonths: tenure,
            loanType: lType,
            borrowerName: app.borrowerName,
            referenceCode: referenceCode,
            emi: emi,
            fee: fee
        )
        
        try? pdfData.write(to: fileURL)
        return fileURL
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

    func sendBackApplication(_ app: LOLoanApplication, remarks: String = "") {
        if let index = recentApplications.firstIndex(where: { $0.id == app.id }) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                recentApplications[index].status = .underReview
                
                // Add timeline event
                let event = TimelineEvent(
                    title: "Sent Back to Borrower",
                    description: "Requested additional info. Remarks: \(remarks.isEmpty ? "No remarks provided" : remarks)",
                    timestamp: Date(),
                    status: .underReview,
                    officerName: officerProfile.name
                )
                recentApplications[index].timeline.insert(event, at: 0)
                
                // Update selection
                if selectedApplication?.id == app.id {
                    selectedApplication = recentApplications[index]
                }
                
                syncStatus(for: recentApplications[index], to: .additionalInfoRequired, note: remarks)
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
            
            // MARK: - Sync to backend: call request-documents API
            guard let sourceApplicationID = app.sourceApplicationID else { return }
            let docType = Self.backendDocumentType(docName)
            Task {
                do {
                    try await environment?.loans.requestDocuments(
                        applicationID: sourceApplicationID,
                        documentTypes: [docType],
                        remark: note.isEmpty ? nil : note
                    )
                } catch {
                    print("[LOAppViewModel] requestDocument backend sync failed: \(error.localizedDescription)")
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
                    
                    // Database Sync
                    if let environment = self.environment, let dbDocID = recentApplications[appIdx].documents[docIdx].sourceDocumentID {
                        Task {
                            do {
                                switch status {
                                case .verified:
                                    try await environment.documents.verifyDocument(documentID: dbDocID, remark: reviewNotes)
                                    print("[LOAppViewModel] Successfully verified document \(dbDocID)")
                                case .rejected:
                                    try await environment.documents.rejectDocument(documentID: dbDocID, reason: rejectionReason ?? "Rejected")
                                    print("[LOAppViewModel] Successfully rejected document \(dbDocID)")
                                case .needsReview:
                                    try await environment.documents.updateStatus(documentID: dbDocID, status: .pending)
                                    print("[LOAppViewModel] Successfully set document \(dbDocID) to pending (needsReview)")
                                default:
                                    break
                                }
                            } catch {
                                print("[LOAppViewModel] Failed to sync document review for \(dbDocID): \(error)")
                            }
                        }
                    }
                }
                
                // MARK: - Sync to backend
                guard let sourceDocID = recentApplications[appIdx].documents[safe: docIdx]?.sourceDocumentID ?? documentId as UUID? else { return }
                let remark = reviewNotes ?? rejectionReason
                Task {
                    do {
                        if status == .verified {
                            try await environment?.documents.verifyDocument(documentID: sourceDocID, remark: remark)
                        } else if status == .rejected {
                            try await environment?.documents.rejectDocument(documentID: sourceDocID, reason: rejectionReason ?? "Rejected by officer")
                        }
                    } catch {
                        // Backend sync failed — the local state is already updated, so no further action needed.
                        // A future refresh will re-sync from the actual backend state.
                        print("[LOAppViewModel] document review sync failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func startReview(for application: LOLoanApplication) async {
        guard let environment,
              let appID = application.sourceApplicationID else { return }
        
        do {
            try await environment.loans.startReview(applicationID: appID)
            print("[LOAppViewModel] Successfully started review for application \(appID)")
            
            // Update local status
            if let index = recentApplications.firstIndex(where: { $0.id == application.id }) {
                recentApplications[index].status = .underReview
                if selectedApplication?.id == application.id {
                    selectedApplication = recentApplications[index]
                }
            }
            await refreshFromService()
        } catch {
            print("[LOAppViewModel] Failed to start review for application \(appID): \(error)")
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

    // MARK: - Recovery Logs

    func logRecoveryAction(for borrower: OverdueBorrower, actionType: String, outcome: String, notes: String?, scheduledDate: Date?) {
        guard let environment else { return }
        
        if let index = overdueBorrowers.firstIndex(where: { $0.id == borrower.id }) {
            overdueBorrowers[index].lastContactDate = Date()
            overdueBorrowers[index].contactAttempts += 1
        }
        
        Task {
            do {
                try await environment.loans.logRecoveryAction(
                    borrowerID: borrower.borrowerID!,
                    officerID: officerID ?? MockOfficerData.officerUserID,
                    actionType: actionType,
                    outcome: outcome,
                    notes: notes,
                    scheduledDate: scheduledDate
                )
                print("[LOAppViewModel] Successfully logged recovery action")
            } catch {
                print("[LOAppViewModel] Failed to log recovery action: \(error)")
            }
        }
    }

    func fetchRecoveryLogs(for borrowerID: UUID) async throws -> [RecoveryLog] {
        guard let environment else { return [] }
        return try await environment.loans.fetchRecoveryLogs(borrowerID: borrowerID)
    }

    // Greeting
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 17 { return "Good Afternoon" }
        return "Good Evening"
    }
}
