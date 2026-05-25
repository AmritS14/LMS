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
    var selectedBranch: String = "Mumbai Central"

    // Data
    var officerProfile = SampleData.officerProfile
    var kpiData = SampleData.kpiData
    var quickActions = SampleData.quickActions
    var recentApplications = SampleData.recentApplications
    var activityFeed = SampleData.activityFeed
    var notifications = SampleData.notifications
    var overdueBorrowers = SampleData.overdueBorrowers
    //var fieldVisits = SampleData.fieldVisits
    var conversations = SampleData.conversations
    var digitalDocuments = SampleData.digitalDocuments
    var documents = SampleData.sampleDocuments
    var collateral = SampleData.sampleCollateral
    var selectedConversation: BorrowerConversation?

    // Dynamic KPI counters tracking base numbers
    private var pendingCount = 47
    private var approvedCount = 132
    private var escalatedCount = 8

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
        ["Mumbai Central", "Mumbai South", "Delhi NCR", "Pune West", "Bangalore East", "Chennai Central"]
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

    // Actions
    func updateKPIs() {
        kpiData = [
            KPIData(title: "Pending\nApplications", value: pendingCount, trend: 12.3, trendUp: true, icon: "doc.text.fill", color: .orange, chartData: [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.75]),
            KPIData(title: "Approved\nLoans", value: approvedCount, trend: 8.7, trendUp: true, icon: "checkmark.circle.fill", color: .green, chartData: [0.4, 0.5, 0.55, 0.6, 0.65, 0.7, 0.8]),
            KPIData(title: "Escalated\nCases", value: escalatedCount, trend: -3.2, trendUp: false, icon: "arrow.up.circle.fill", color: .purple, chartData: [0.6, 0.7, 0.5, 0.4, 0.45, 0.35, 0.3]),
            KPIData(title: "Overdue\nBorrowers", value: 19, trend: -5.1, trendUp: false, icon: "person.crop.circle.badge.exclamationmark.fill", color: Color(red: 0.8, green: 0.4, blue: 0), chartData: [0.7, 0.65, 0.6, 0.55, 0.5, 0.45, 0.4])
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
                    description: "Recommended for final approval by Rajesh Kumar. Remarks: \(remarks.isEmpty ? "No remarks provided" : remarks)",
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
                    description: "Rejected by Rajesh Kumar. Remarks: \(remarks.isEmpty ? "No remarks provided" : remarks)",
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
                    description: "Escalated by Rajesh Kumar. Notes: \(remarks.isEmpty ? "No escalation notes provided" : remarks)",
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
                        officerName: "Rajesh Kumar"
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
