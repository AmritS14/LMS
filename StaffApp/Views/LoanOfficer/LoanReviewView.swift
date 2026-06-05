import SwiftUI

enum ReviewSegment: String, CaseIterable {
    case overview = "Overview"
    case documents = "Documents"
    case actions = "Actions"
    
    var icon: String {
        switch self {
        case .overview: return "doc.text.magnifyingglass"
        case .documents: return "folder.fill"
        case .actions: return "hand.tap.fill"
        }
    }
}

enum ActionType {
    case approve
    case reject
    case escalate
}

// MARK: - Loan Review View
struct LoanReviewView: View {
    @Environment(AppViewModel.self) var viewModel

    // MARK: Local State
    @State private var selectedSegment: ReviewSegment = .overview
    @State private var selectedAction: ActionType? = nil
    @State private var officerRemarks: String = ""
    @State private var expandedDocumentIDs: Set<UUID> = []
    @State private var showSendBackAlert = false
    @State private var escalationNotes: String = ""
    @State private var requestedDocumentName: String = ""
    @State private var requestedDocumentNote: String = ""
    @State private var animateIn = false
    @State private var pulsingScale: CGFloat = 1.0
    
    // New states for validation and remarks checking
    @State private var showBlockerAlert = false
    @State private var highlightRemarks = false
    @State private var selectedReviewDocument: LOLoanDocument? = nil
    @State private var showConversation = false

    /// The application under review — uses selectedApplication or falls back to the first real one.
    private var application: LOLoanApplication? {
        viewModel.selectedApplication ?? viewModel.recentApplications.first
    }
    
    /// Non-optional accessor for use inside view sections that are only shown when application != nil.
    private var currentApplication: LOLoanApplication {
        // swiftlint:disable:next force_unwrapping
        application! // Safe: only called from sections rendered inside the else-branch guard
    }
    
    private var blockerAlertMessage: String {
        let blockers = (application?.validationIssues ?? []).filter { $0.isBlocker }
        return blockers.map { "• " + $0.message }.joined(separator: "\n")
    }

    var body: some View {
        @Bindable var bindableViewModel = viewModel
        
        if viewModel.selectedApplication == nil && viewModel.recentApplications.isEmpty {
            ContentUnavailableView("No Application", systemImage: "doc.text.magnifyingglass", description: Text("No application data available to review."))
                .navigationTitle("Loan Review")
                .navigationBarTitleDisplayMode(.inline)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    borrowerProfileSection
                    
                    segmentSelector
                    
                    switch selectedSegment {
                    case .overview:
                        VStack(spacing: 20) {
                            borrowerProfileDetailsSection
                            validationChecklistSection
                            loanDetailsSection
                            collateralSection
                            timelineSection
                        }
                        .transition(.opacity)
                    case .documents:
                        documentKYCSection
                            .transition(.opacity)
                    case .actions:
                        VStack(spacing: 20) {
                            recommendationSection
                            if currentApplication.status == .approved || currentApplication.status == .disbursed {
                                sanctionLetterSection
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Loan Review")
            .navigationBarTitleDisplayMode(.inline)
            
            .confirmationDialog("Approve Application", isPresented: $bindableViewModel.showApproveConfirmation, titleVisibility: .visible) {
                Button("Approve Loan", role: .confirm) {
                    if let app = application {
                        viewModel.approveApplication(app, remarks: officerRemarks)
                    }
                    if !viewModel.navigationPath.isEmpty {
                        viewModel.navigationPath.removeLast()
                    }
                }
            } message: {
                Text("Are you sure you want to approve \(application?.borrowerName ?? "")'s \(application?.loanType ?? "") application for \(AppFormatters.formatCurrency(application?.loanAmount ?? 0))?")
            }
            
            .confirmationDialog("Reject Application", isPresented: $bindableViewModel.showRejectConfirmation, titleVisibility: .visible) {
                Button("Reject Loan", role: .destructive) {
                    if let app = application {
                        viewModel.rejectApplication(app, remarks: officerRemarks)
                    }
                    if !viewModel.navigationPath.isEmpty {
                        viewModel.navigationPath.removeLast()
                    }
                }
            } message: {
                Text("Are you sure you want to reject \(application?.borrowerName ?? "")'s application? This action will notify the borrower.")
            }
            
            .sheet(isPresented: $bindableViewModel.showEscalateSheet) {
                escalateSheetContent
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $bindableViewModel.showDocumentRequest) {
                requestDocumentSheetContent
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedReviewDocument) { doc in
                if let app = application {
                    DocumentReviewSheet(
                        viewModel: viewModel,
                        application: app,
                        document: doc
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showConversation) {
                if let app = application {
                    LOConversationView(application: app)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            }
            .alert("Send Back for Revision", isPresented: $showSendBackAlert) {
                Button("Send Back") {
                    if let app = application {
                        viewModel.sendBackApplication(app, remarks: "Application sent back for revision.")
                    }
                    if !viewModel.navigationPath.isEmpty {
                        viewModel.navigationPath.removeLast()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This application will be sent back to the borrower for additional information.")
            }
            .alert("Approval Blocked", isPresented: $showBlockerAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This application has critical blocker issues that must be resolved first:\n\n\(blockerAlertMessage)")
            }
            .onAppear {
                withAnimation() {
                    animateIn = true
                }
                // Open (or reuse) the borrower⇄officer conversation for this app.
                if let app = application {
                    viewModel.ensureThread(for: app)
                    // Auto-start the review if application is in pending status (transition to under_review on backend)
                    if app.status == .pending {
                        Task {
                            await viewModel.startReview(for: app)
                        }
                    }
                    let appID = app.sourceApplicationID ?? app.id
                    Task {
                        await viewModel.loadSanctionLetter(for: appID)
                    }
                }
            }
            .onDisappear {
                viewModel.highlightMessageButton = false
            }
        }
    }
}

// MARK: - Helper Methods for Credit Score
extension LoanReviewView {
    private func creditScoreColor(for score: Int) -> Color {
        if score < 600 { return .red }
        if score < 680 { return .orange }
        if score < 750 { return .yellow }
        return .green
    }
    
    private func creditScoreRating(for score: Int) -> String {
        if score < 600 { return "Poor" }
        if score < 680 { return "Fair" }
        if score < 750 { return "Good" }
        return "Excellent"
    }

    private func riskColor(for risk: RiskLevel) -> Color {
        switch risk {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .red
        }
    }

    private func eligibilityColor(for score: Int) -> Color {
        if score >= 70 { return .green }
        if score >= 50 { return .orange }
        return .red
    }
}

// MARK: - Segment Selector View
extension LoanReviewView {
    private var segmentSelector: some View {
        Picker("Review Segment", selection: $selectedSegment) {
            ForEach(ReviewSegment.allCases, id: \.self) { segment in
                Text(segment.rawValue)
                    .tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
}

// MARK: - Validation Checklist Section
extension LoanReviewView {
    private var validationChecklistSection: some View {
        Group {
            if !currentApplication.validationIssues.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    LOSectionHeader(
                        title: "System Validation Checks",
                        subtitle: "\(currentApplication.validationIssues.filter { !$0.isBlocker }.count) Warnings, \(currentApplication.validationIssues.filter { $0.isBlocker }.count) Blocker(s)",
                        icon: "exclamationmark.shield.fill"
                    )
                    
                    LOPremiumCard(cornerRadius: 16, padding: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(currentApplication.validationIssues) { issue in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: issue.isBlocker ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(issue.isBlocker ? .red : .orange)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(issue.message)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.primary)
                                        Text(issue.isBlocker ? "BLOCKER — Action required before approval" : "WARNING — High risk parameter")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                
                                if issue.id != currentApplication.validationIssues.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(currentApplication.canProceedToApproval ? Color.orange.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1.5)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(currentApplication.canProceedToApproval ? Color.orange.opacity(0.04) : Color.red.opacity(0.04))
                    )
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
            }
        }
    }
}

// MARK: - Borrower Profile Section
extension LoanReviewView {
    private var borrowerProfileSection: some View {
        LOPremiumCard {
            VStack(spacing: 14) {
                // Row 1: Avatar + Name and Employment Info
                HStack(spacing: 14) {
                    LOAvatarView(
                        initials: currentApplication.borrowerInitials,
                        size: 52,
                        colors: avatarGradient(for: currentApplication.riskLevel)
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentApplication.borrowerName)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Text(currentApplication.employmentType)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Row 2: Status Badges (Left) & Message Button (Right)
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        LOStatusBadge(
                            text: currentApplication.status.rawValue,
                            color: currentApplication.status.color,
                            icon: currentApplication.status.icon,
                            size: .small
                        )
                        LOStatusBadge(
                            text: "\(currentApplication.riskLevel.rawValue) Risk",
                            color: riskColor(for: currentApplication.riskLevel),
                            icon: "shield.fill",
                            size: .small
                        )
                    }
                    
                    Spacer()
                    
                    messageBorrowerButton
                }
                
                Divider()
                    .overlay(Color(.separator).opacity(0.3))
                
                // Row 3: 3-Column Quick Stats Panel
                HStack(alignment: .center) {
                    // Column 1: Credit Score
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 11))
                                .foregroundColor(currentApplication.creditScore > 0 ? creditScoreColor(for: currentApplication.creditScore) : .secondary)
                            Text(currentApplication.creditScore > 0 ? "\(currentApplication.creditScore)" : "N/A")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        Text(currentApplication.creditScore > 0 ? creditScoreRating(for: currentApplication.creditScore) : "Unknown")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 24)
                        .overlay(Color(.separator).opacity(0.3))
                    
                    // Column 2: Loan Amount
                    VStack(spacing: 4) {
                        Text(AppFormatters.formatCurrency(currentApplication.loanAmount))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Requested")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 24)
                        .overlay(Color(.separator).opacity(0.3))
                    
                    // Column 3: Match / Eligibility Score
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundColor(currentApplication.eligibilityScore > 0 ? .orange : .secondary)
                            Text(currentApplication.eligibilityScore > 0 ? "\(currentApplication.eligibilityScore)%" : "N/A")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(currentApplication.eligibilityScore > 0 ? eligibilityColor(for: currentApplication.eligibilityScore) : .secondary)
                        }
                        
                        Text("Match Score")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }

    private var messageBorrowerButton: some View {
        Button {
            withAnimation { viewModel.highlightMessageButton = false }
            // Real backend application → open the live borrower⇄officer thread.
            if currentApplication.sourceApplicationID != nil, currentApplication.borrowerID != nil {
                showConversation = true
            } else if let conversation = viewModel.conversations.first(where: {
                $0.borrowerName == currentApplication.borrowerName
            }) {
                withAnimation {
                    viewModel.highlightMessageButton = false
                }
                viewModel.navigationPath.append(AppDestination.chat(conversation))
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "message.fill")
                    .font(.system(size: 13, weight: .bold))
                Text("Message")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(viewModel.highlightMessageButton ? .white : .blue)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Group {
                    if viewModel.highlightMessageButton {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color(red: 0.15, green: 0.4, blue: 0.95)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.blue.opacity(0.4), radius: 6, x: 0, y: 3)
                    } else {
                        Capsule()
                            .fill(Color.blue.opacity(0.12))
                    }
                }
            )
            .scaleEffect(viewModel.highlightMessageButton ? pulsingScale : 1.0)
            .overlay(
                Capsule()
                    .stroke(Color.blue.opacity(viewModel.highlightMessageButton ? 1.0 : 0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            if viewModel.highlightMessageButton {
                withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulsingScale = 1.08
                }
            } else {
                pulsingScale = 1.0
            }
        }
    }

    private var borrowerProfileDetailsSection: some View {
        LOPremiumCard {
            VStack(spacing: 12) {
                LOSectionHeader(title: "Borrower Information")
                
                LODetailRow(icon: "building.2.fill", title: "Employment", value: currentApplication.employmentType)
                
                LODetailRow(
                    icon: "indianrupeesign.circle.fill",
                    title: "Monthly Income",
                    value: currentApplication.monthlyIncome > 0 ? AppFormatters.formatCurrency(currentApplication.monthlyIncome) : "—",
                    valueColor: .green
                )

                Divider()

                // Contact row
                VStack(alignment: .leading, spacing: 5) {
                    contactButton(icon: "phone.fill", label: currentApplication.phoneNumber, color: .green)
                    contactButton(icon: "envelope.fill", label: currentApplication.email, color: .blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }

    private func contactButton(icon: String, label: String, color: Color) -> some View {
        Button {
            if icon == "phone.fill", let url = URL(string: "tel://\(label.filter(\.isNumber))") {
                UIApplication.shared.open(url)
            } else if icon == "envelope.fill", let url = URL(string: "mailto:\(label)") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private func avatarGradient(for risk: RiskLevel) -> [Color] {
        switch risk {
        case .low: return [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.55, blue: 0.3)]
        case .medium: return [Color(red: 0.9, green: 0.6, blue: 0.1), Color(red: 0.8, green: 0.45, blue: 0.05)]
        case .high: return [Color(red: 0.9, green: 0.3, blue: 0.2), Color(red: 0.75, green: 0.2, blue: 0.15)]
        case .critical: return [Color(red: 0.75, green: 0.05, blue: 0.05), Color(red: 0.55, green: 0.0, blue: 0.0)]
        }
    }
}

// MARK: - Loan Details Section
extension LoanReviewView {
    private var loanDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LOSectionHeader(title: "Loan Details")
            
            LOPremiumCard {
                VStack(spacing: 2) {
                    LODetailRow(icon: "doc.text.fill", title: "Loan Type", value: currentApplication.loanType)
                    LODetailRow(
                        icon: "indianrupeesign.circle",
                        title: "Requested Amount",
                        value: AppFormatters.formatCurrency(currentApplication.loanAmount),
                        valueColor: .primary
                    )
                    LODetailRow(
                        icon: "calendar.badge.clock",
                        title: "EMI",
                        value: AppFormatters.formatCurrency(currentApplication.emiAmount),
                        valueColor: .blue
                    )
                    LODetailRow(
                        icon: "percent",
                        title: "Interest Rate",
                        value: String(format: "%.2f%%", currentApplication.interestRate)
                    )
                    LODetailRow(
                        icon: "clock.fill",
                        title: "Tenure",
                        value: "\(currentApplication.tenure) months"
                    )
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Repayment summary
                    repaymentSummaryCard
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    private var sanctionLetterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LOSectionHeader(title: "Sanction Letter Management", icon: "doc.text.fill")
            
            LOPremiumCard {
                VStack(spacing: 16) {
                    if let app = application {
                        let appID = app.sourceApplicationID ?? app.id
                        
                        if viewModel.generatingSanctionLetterAppID == appID {
                            HStack(spacing: 12) {
                                ProgressView().progressViewStyle(.circular)
                                    .scaleEffect(1.0)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Generating Sanction Letter...")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Creating PDF draft and uploading documents")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else if viewModel.sendingSanctionLetterAppID == appID {
                            HStack(spacing: 12) {
                                ProgressView().progressViewStyle(.circular)
                                    .scaleEffect(1.0)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sending to Borrower...")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Notifying borrower and posting in chat thread")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else if let letter = viewModel.currentSanctionLetter {
                            VStack(alignment: .leading, spacing: 12) {
                                // Status display
                                HStack(spacing: 10) {
                                    if letter.status == "generated" {
                                        Image(systemName: "doc.badge.plus")
                                            .font(.system(size: 20))
                                            .foregroundColor(.orange)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Draft Generated (Not Sent)")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.primary)
                                            Text("The borrower will not see this until you send it.")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.secondary)
                                        }
                                    } else if letter.status == "sent" {
                                        Image(systemName: "paperplane.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Sent to Borrower")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.primary)
                                            Text("Pending borrower review & e-signature.")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.secondary)
                                        }
                                    } else if letter.status == "accepted" || letter.isAccepted {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.green)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Accepted & Signed")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.primary)
                                            if let acceptedAt = letter.acceptedAt {
                                                Text("Signed on \(AppFormatters.formatDate(acceptedAt))")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.secondary)
                                            } else {
                                                Text("Terms agreed and accepted by borrower.")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    Spacer()
                                }
                                
                                Divider()
                                
                                HStack(spacing: 12) {
                                    if let pdfURL = viewModel.getSanctionLetterPDFURL(for: appID) {
                                        ShareLink(
                                            item: pdfURL,
                                            preview: SharePreview("Sanction Letter", image: Image(systemName: "doc.text.fill"))
                                        ) {
                                            HStack {
                                                Image(systemName: "eye.fill")
                                                Text("Preview PDF")
                                            }
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.blue)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(10)
                                        }
                                    }
                                    
                                    if letter.status == "generated" {
                                        Button {
                                            Task {
                                                await viewModel.sendSanctionLetterToBorrower(for: app)
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "paperplane.fill")
                                                Text("Send to Borrower")
                                            }
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(
                                                LinearGradient(
                                                    colors: [.blue, Color(red: 0.15, green: 0.4, blue: 0.95)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                            }
                        } else {
                            // No sanction letter generated yet
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 10) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("No Sanction Letter Generated")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Generate draft to review terms before sending.")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                
                                Divider()
                                
                                Button {
                                    Task {
                                        await viewModel.generateSanctionLetter(for: app)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Generate Sanction Letter")
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    } else {
                        Text("No application selected")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var repaymentSummaryCard: some View {
        let totalPayable = currentApplication.emiAmount * Double(currentApplication.tenure)
        let totalInterest = totalPayable - currentApplication.loanAmount
        
        return VStack(spacing: 8) {
            HStack {
                Text("Repayment Summary")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            HStack(spacing: 0) {
                summaryColumn(label: "Interest", value: AppFormatters.formatCurrency(totalInterest), color: .orange)
                Spacer()
                summaryColumn(label: "Total Payable", value: AppFormatters.formatCurrency(totalPayable), color: .green)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
    }
    
    private func summaryColumn(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Document & KYC Section
extension LoanReviewView {
    private var documentKYCSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LOSectionHeader(
                title: "Documents & KYC",
                subtitle: "\(currentApplication.documents.filter { $0.status == .verified }.count)/\(currentApplication.documents.count) verified",
                actionTitle: "Request New",
                action: {
                    requestedDocumentName = ""
                    requestedDocumentNote = ""
                    highlightRemarks = false
                    viewModel.showDocumentRequest = true
                }
            )

            LOPremiumCard {
                if currentApplication.documents.isEmpty {
                    HStack {
                        Spacer()
                        Text("No documents uploaded yet.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                        Spacer()
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(currentApplication.documents) { document in
                            documentCard(document)
                        }
                    }
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }

    private func documentCard(_ document: LOLoanDocument) -> some View {
        return VStack(spacing: 0) {
            // Main row — always visible
            Button {
                selectedReviewDocument = document
            } label: {
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: document.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(document.status.color)
                        .frame(width: 36, height: 36)
                        .background(document.status.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(document.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                        
                        if let reason = document.rejectionReason, !reason.isEmpty {
                            Text("Rejected: \(reason)")
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                                .lineLimit(1)
                        } else if let notes = document.reviewNotes, !notes.isEmpty {
                            Text("Notes: \(notes)")
                                .font(.system(size: 11))
                                .foregroundStyle(.orange)
                                .lineLimit(1)
                        } else {
                            Text(document.type)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    LOStatusBadge(
                        text: document.status.rawValue,
                        color: document.status.color,
                        icon: document.status.icon,
                        size: .small
                    )

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if document.id != currentApplication.documents.last?.id {
                Divider()
            }
        }
    }

    private func alertBanner(icon: String, message: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - Collateral Section
extension LoanReviewView {
    private var collateralSection: some View {
        Group {
            if !viewModel.collateral.propertyType.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    LOSectionHeader(title: "Collateral")

                    LOPremiumCard {
                        VStack(spacing: 8) {
                            LODetailRow(icon: "house.fill", title: "Property Type", value: viewModel.collateral.propertyType)
                            LODetailRow(icon: "mappin.circle.fill", title: "Address", value: viewModel.collateral.address)
                            LODetailRow(
                                icon: "indianrupeesign.circle.fill",
                                title: "Current Valuation",
                                value: AppFormatters.formatCurrency(viewModel.collateral.currentValuation),
                                valueColor: .green
                            )
                            LODetailRow(
                                icon: "calendar",
                                title: "Last Valuation",
                                value: AppFormatters.formatDate(viewModel.collateral.lastValuationDate)
                            )

                            Divider()

                            // Coverage ratio visualization
                            HStack(spacing: 16) {
                                LOCircularProgress(
                                    progress: min(viewModel.collateral.coverageRatio / 2.0, 1.0),
                                    color: viewModel.collateral.coverageRatio >= 1.5 ? .green : (viewModel.collateral.coverageRatio >= 1.0 ? .orange : .red),
                                    size: 72
                                )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Coverage Ratio")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text(String(format: "%.2fx", viewModel.collateral.coverageRatio))
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(viewModel.collateral.coverageRatio >= 1.5 ? .green : (viewModel.collateral.coverageRatio >= 1.0 ? .orange : .red))
                                    Text(viewModel.collateral.coverageRatio >= 1.5 ? "Adequate collateral" : "Marginal coverage")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
            }
        }
    }
}

// MARK: - Recommendation Section
extension LoanReviewView {
    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LOSectionHeader(title: "Remarks & Actions")
            
            LOPremiumCard {
                VStack(spacing: 16) {
                    // Text editor for remarks
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Officer Remarks")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        ZStack(alignment: .topLeading) {
                            if officerRemarks.isEmpty {
                                Text("Enter your assessment, observations, and recommendation...")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(.placeholderText))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                            }
                            TextEditor(text: $officerRemarks)
                                .font(.system(size: 14))
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .onChange(of: officerRemarks) { _, newValue in
                                    if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        highlightRemarks = false
                                    }
                                }
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.tertiarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(highlightRemarks ? Color.red : Color(.separator).opacity(0.3), lineWidth: highlightRemarks ? 1.5 : 0.5)
                        )
                        
                        if highlightRemarks {
                            Text("⚠️ Remarks are mandatory for authorization decisions")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Approve, Reject, Escalate buttons merged in this card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Perform Action")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 8) {
                            actionButton(
                                type: .approve,
                                title: "Approve",
                                icon: "checkmark.circle.fill",
                                gradient: [.blue, Color(red: 0.15, green: 0.4, blue: 0.95)]
                            )
                            
                            actionButton(
                                type: .reject,
                                title: "Reject",
                                icon: "xmark.circle.fill",
                                gradient: [.red, Color(red: 0.85, green: 0.15, blue: 0.15)]
                            )
                            
                            actionButton(
                                type: .escalate,
                                title: "Escalate",
                                icon: "arrow.up.circle.fill",
                                gradient: [.purple, Color(red: 0.6, green: 0.2, blue: 0.85)]
                            )
                        }
                    }
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    private func actionButton(type: ActionType, title: String, icon: String, gradient: [Color]) -> some View {
        let isSelected = selectedAction == type
        let isAnySelected = selectedAction != nil
        let opacity = isAnySelected ? (isSelected ? 1.0 : 0.4) : 1.0
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedAction = type
            }
            performAction(type)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: gradient.first?.opacity(isSelected ? 0.35 : 0.1) ?? .clear, radius: 6, x: 0, y: 3)
            )
            .opacity(opacity)
        }
        .buttonStyle(.plain)
    }
    
    private func performAction(_ type: ActionType) {
        switch type {
        case .approve:
            if officerRemarks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                withAnimation {
                    highlightRemarks = true
                }
            } else if !currentApplication.canProceedToApproval {
                showBlockerAlert = true
            } else {
                viewModel.showApproveConfirmation = true
            }
            
        case .reject:
            if officerRemarks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                withAnimation {
                    highlightRemarks = true
                }
            } else {
                viewModel.showRejectConfirmation = true
            }
            
        case .escalate:
            highlightRemarks = false
            escalationNotes = officerRemarks
            viewModel.showEscalateSheet = true
        }
    }
}

// MARK: - Timeline Section
extension LoanReviewView {
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LOSectionHeader(
                title: "Application Timeline",
                subtitle: "History of updates & audits",
                icon: "clock.arrow.2.circlepath"
            )
            
            LOPremiumCard {
                if currentApplication.timeline.isEmpty {
                    Text("No timeline events logged yet.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<currentApplication.timeline.count, id: \.self) { index in
                            let event = currentApplication.timeline[index]
                            TimelineRow(
                                event: event,
                                isFirst: index == 0,
                                isLast: index == currentApplication.timeline.count - 1
                            )
                        }
                    }
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
}

// MARK: - Timeline Row View
struct TimelineRow: View {
    let event: TimelineEvent
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Indicator column
            VStack(spacing: 0) {
                // Line above dot
                if !isFirst {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 2, height: 12)
                } else {
                    Spacer().frame(height: 12)
                }
                
                // Dot
                Circle()
                    .fill(event.status.color)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    )
                    .shadow(color: event.status.color.opacity(0.4), radius: 4)
                
                // Line below dot
                if !isLast {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 2)
                } else {
                    Spacer()
                }
            }
            .frame(width: 16)
            
            // Content column
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(event.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(AppFormatters.formatDate(event.timestamp))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                Text(event.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text("By: \(event.officerName)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
                
                if !isLast {
                    Spacer().frame(height: 16)
                }
            }
            .padding(.top, 8)
        }
    }
}



// MARK: - Escalate Sheet
extension LoanReviewView {
    private var escalateSheetContent: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Escalation Reason")
                        .font(.system(size: 14, weight: .semibold))

                    ZStack(alignment: .topLeading) {
                        if escalationNotes.isEmpty {
                            Text("Describe the reason for escalation to the senior officer...")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(.placeholderText))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }
                        TextEditor(text: $escalationNotes)
                            .font(.system(size: 14))
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                    )
                }

                // Escalation level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Escalation Level")
                        .font(.system(size: 14, weight: .semibold))

                    HStack(spacing: 10) {
                        escalationLevelOption(title: "Branch Manager", icon: "person.2.fill", isSelected: true)
                    }
                }

                Spacer()

                Button {
                    if !escalationNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       let app = application {
                        viewModel.escalateApplication(app, remarks: escalationNotes)
                        viewModel.showEscalateSheet = false
                        if !viewModel.navigationPath.isEmpty {
                            viewModel.navigationPath.removeLast()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Submit Escalation")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                escalationNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(
                                    colors: [.purple, Color(red: 0.6, green: 0.2, blue: 0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .disabled(escalationNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
            .navigationTitle("Escalate Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { viewModel.showEscalateSheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func escalationLevelOption(title: String, icon: String, isSelected: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.purple : Color(.tertiarySystemGroupedBackground))
                )
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Request Document Sheet
extension LoanReviewView {
    private var requestDocumentSheetContent: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Document Name")
                        .font(.system(size: 14, weight: .semibold))

                    TextField("e.g. Bank Statement (6 months)", text: $requestedDocumentName)
                        .font(.system(size: 14))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.tertiarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Note to Borrower")
                        .font(.system(size: 14, weight: .semibold))

                    ZStack(alignment: .topLeading) {
                        if requestedDocumentNote.isEmpty {
                            Text("Add any specific instructions for the borrower...")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(.placeholderText))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }
                        TextEditor(text: $requestedDocumentNote)
                            .font(.system(size: 14))
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                    )
                }

                // Quick select common docs
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Select")
                        .font(.system(size: 14, weight: .semibold))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        quickDocOption(name: "Bank Statement", icon: "building.columns.fill")
                        quickDocOption(name: "Salary Slip", icon: "doc.text.fill")
                        quickDocOption(name: "IT Returns", icon: "doc.on.doc.fill")
                        quickDocOption(name: "Property Docs", icon: "house.fill")
                    }
                }

                Spacer()

                Button {
                    if !requestedDocumentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       let app = application {
                        viewModel.requestDocument(app, docName: requestedDocumentName, note: requestedDocumentNote)
                        viewModel.showDocumentRequest = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Send Request")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                requestedDocumentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(
                                    colors: [.blue, Color(red: 0.15, green: 0.4, blue: 0.95)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .disabled(requestedDocumentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
            .navigationTitle("Request Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { viewModel.showDocumentRequest = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func quickDocOption(name: String, icon: String) -> some View {
        Button {
            requestedDocumentName = name
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.blue)
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(requestedDocumentName == name ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LoanReviewView()
            .environment(AppViewModel())
    }
}
