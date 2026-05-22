import SwiftUI

// MARK: - Loan Review View
struct LoanReviewView: View {
    @EnvironmentObject var viewModel: AppViewModel

    // MARK: Local State
    @State private var officerRemarks: String = ""
    @State private var expandedDocumentIDs: Set<UUID> = []
    @State private var showShareSheet = false
    @State private var showSendBackAlert = false
    @State private var escalationNotes: String = ""
    @State private var requestedDocumentName: String = ""
    @State private var requestedDocumentNote: String = ""
    @State private var animateIn = false
    
    // New states for validation and remarks checking
    @State private var showBlockerAlert = false
    @State private var highlightRemarks = false

    /// The application under review — uses selectedApplication or falls back to the first recent one.
    private var application: LoanApplication {
        viewModel.selectedApplication ?? viewModel.recentApplications.first ?? SampleData.recentApplications[0]
    }
    
    private var blockerAlertMessage: String {
        let blockers = application.validationIssues.filter { $0.isBlocker }
        return blockers.map { "• " + $0.message }.joined(separator: "\n")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    borrowerProfileSection
                    
                    // Validation Checks Checklist Card
                    validationChecklistSection
                    
                    loanDetailsSection
                    documentKYCSection
                    collateralSection
                    recommendationSection
                    
                    // Timeline Section
                    timelineSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 120) // room for floating action bar
            }
            .background(Color(.systemGroupedBackground))

            // Floating decision action bar
            floatingActionBar
        }
        .navigationTitle("Loan Review")
        .navigationBarTitleDisplayMode(.large)
        
        .confirmationDialog("Approve Application", isPresented: $viewModel.showApproveConfirmation, titleVisibility: .visible) {
            Button("Approve Loan", role: .confirm) {
                viewModel.approveApplication(application, remarks: officerRemarks)
                if !viewModel.navigationPath.isEmpty {
                    viewModel.navigationPath.removeLast()
                }
            }
        } message: {
            Text("Are you sure you want to approve \(application.borrowerName)'s \(application.loanType) application for \(AppFormatters.formatCurrency(application.loanAmount))?")
        }
        
        .confirmationDialog("Reject Application", isPresented: $viewModel.showRejectConfirmation, titleVisibility: .visible) {
            Button("Reject Loan", role: .destructive) {
                viewModel.rejectApplication(application, remarks: officerRemarks)
                if !viewModel.navigationPath.isEmpty {
                    viewModel.navigationPath.removeLast()
                }
            }
        } message: {
            Text("Are you sure you want to reject \(application.borrowerName)'s application? This action will notify the borrower.")
        }
        
        .sheet(isPresented: $viewModel.showEscalateSheet) {
            escalateSheetContent
        }
        .sheet(isPresented: $viewModel.showDocumentRequest) {
            requestDocumentSheetContent
        }
        .alert("Send Back for Revision", isPresented: $showSendBackAlert) {
            Button("Send Back") {
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
}

// MARK: - Validation Checklist Section
extension LoanReviewView {
    private var validationChecklistSection: some View {
        Group {
            if !application.validationIssues.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        title: "System Validation Checks",
                        subtitle: "\(application.validationIssues.filter { !$0.isBlocker }.count) Warnings, \(application.validationIssues.filter { $0.isBlocker }.count) Blocker(s)",
                        icon: "exclamationmark.shield.fill"
                    )
                    
                    PremiumCard(cornerRadius: 16, padding: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(application.validationIssues) { issue in
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
                                
                                if issue.id != application.validationIssues.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(application.canProceedToApproval ? Color.orange.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1.5)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(application.canProceedToApproval ? Color.orange.opacity(0.04) : Color.red.opacity(0.04))
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
        PremiumCard {
            VStack(spacing: 12) {
                // Header row: avatar + name + status
                HStack(spacing: 16) {
                    AvatarView(
                        initials: application.borrowerInitials,
                        size: 72,
                        colors: avatarGradient(for: application.riskLevel)
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(application.borrowerName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.primary)

                        HStack(spacing: 8) {
                            StatusBadge(
                                text: application.employmentType,
                                color: .blue,
                                icon: "briefcase.fill",
                                size: .medium
                            )
                            StatusBadge(
                                text: application.status.rawValue,
                                color: application.status.color,
                                icon: application.status.icon,
                                size: .medium
                            )
                        }
                    }

                    Spacer()
                }
                
                // Credit Score Badge Row
                HStack {
                    StatusBadge(
                        text: "Credit Score: \(application.creditScore) (\(creditScoreRating(for: application.creditScore)))",
                        color: creditScoreColor(for: application.creditScore),
                        icon: "creditcard.fill",
                        size: .medium
                    )
                    Spacer()
                }
                .padding(.top, 4)
                
                Divider()
                
                // Detail rows
                DetailRow(icon: "building.2.fill", title: "Employer", value: application.employer)
                
                DetailRow(
                    icon: "indianrupeesign.circle.fill",
                    title: "Monthly Income",
                    value: AppFormatters.formatCurrency(application.monthlyIncome),
                    valueColor: .green
                )
                
                DetailRow(
                    icon: "star.fill",
                    title: "Eligibility Score",
                    value: "\(application.eligibilityScore)/100",
                    valueColor: application.eligibilityScore >= 70 ? .green : (application.eligibilityScore >= 50 ? .orange : .red)
                )

                Divider()

                // Contact row
                VStack(alignment: .leading, spacing: 5) {
                    contactButton(icon: "phone.fill", label: application.phoneNumber, color: .green)
                    contactButton(icon: "envelope.fill", label: application.email, color: .blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }

    private func contactButton(icon: String, label: String, color: Color) -> some View {
        Button {
            // Tap action
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
            SectionHeader(title: "Loan Details")
            
            PremiumCard {
                VStack(spacing: 2) {
                    DetailRow(icon: "doc.text.fill", title: "Loan Type", value: application.loanType)
                    DetailRow(
                        icon: "indianrupeesign.circle",
                        title: "Requested Amount",
                        value: AppFormatters.formatCurrency(application.loanAmount),
                        valueColor: .primary
                    )
                    DetailRow(
                        icon: "calendar.badge.clock",
                        title: "EMI",
                        value: AppFormatters.formatCurrency(application.emiAmount),
                        valueColor: .blue
                    )
                    DetailRow(
                        icon: "percent",
                        title: "Interest Rate",
                        value: String(format: "%.2f%%", application.interestRate)
                    )
                    DetailRow(
                        icon: "clock.fill",
                        title: "Tenure",
                        value: "\(application.tenure) months"
                    )
                    DetailRow(
                        icon: "text.quote",
                        title: "Purpose",
                        value: application.purpose
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
    
    private var repaymentSummaryCard: some View {
        let totalPayable = application.emiAmount * Double(application.tenure)
        let totalInterest = totalPayable - application.loanAmount
        
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
            SectionHeader(
                title: "Documents & KYC",
                subtitle: "\(application.documents.filter { $0.status == .verified }.count)/\(application.documents.count) verified",
                actionTitle: "Request New",
                action: {
                    requestedDocumentName = ""
                    requestedDocumentNote = ""
                    highlightRemarks = false
                    viewModel.showDocumentRequest = true
                }
            )

            PremiumCard {
                VStack(spacing: 10) {
                    ForEach(application.documents) { document in
                        documentCard(document)
                    }
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }

    private func documentCard(_ document: LoanDocument) -> some View {
        let isExpanded = expandedDocumentIDs.contains(document.id)

        return VStack(spacing: 0) {
            // Main row — always visible
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedDocumentIDs.remove(document.id)
                    } else {
                        expandedDocumentIDs.insert(document.id)
                    }
                }
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
                        Text(document.type)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    StatusBadge(
                        text: document.status.rawValue,
                        color: document.status.color,
                        icon: document.status.icon,
                        size: .small
                    )

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Alert banners based on status
                    if document.status == .tampered {
                        alertBanner(
                            icon: "exclamationmark.octagon.fill",
                            message: "⚠️ Tampering detected! This document has been flagged for potential fraud. Immediate review is required.",
                            color: .red
                        )
                    }

                    if document.status == .duplicate {
                        alertBanner(
                            icon: "doc.on.doc.fill",
                            message: "Duplicate document detected. A previous version of this document already exists in the system.",
                            color: .purple
                        )
                    }

                    if document.status == .missing {
                        alertBanner(
                            icon: "arrow.up.doc.fill",
                            message: "Upload Required — This document has not been submitted by the borrower.",
                            color: .red
                        )
                    }

                    if let uploadDate = document.uploadDate {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text("Uploaded: \(AppFormatters.formatDate(uploadDate))")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Simulate Borrower Upload button for pending, missing, or tampered documents
                    if document.status == .pending || document.status == .missing || document.status == .tampered {
                        Button {
                            viewModel.simulateBorrowerResubmission(for: application)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.doc.fill")
                                Text("Simulate Borrower Upload")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
                .padding(.leading, 48)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if document.id != application.documents.last?.id {
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
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Collateral")

            PremiumCard {
                VStack(spacing: 8) {
                    DetailRow(icon: "house.fill", title: "Property Type", value: viewModel.collateral.propertyType)
                    DetailRow(icon: "mappin.circle.fill", title: "Address", value: viewModel.collateral.address)
                    DetailRow(
                        icon: "indianrupeesign.circle.fill",
                        title: "Current Valuation",
                        value: AppFormatters.formatCurrency(viewModel.collateral.currentValuation),
                        valueColor: .green
                    )
                    DetailRow(
                        icon: "calendar",
                        title: "Last Valuation",
                        value: AppFormatters.formatDate(viewModel.collateral.lastValuationDate)
                    )

                    Divider()

                    // Coverage ratio visualization
                    HStack(spacing: 16) {
                        CircularProgress(
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

// MARK: - Recommendation Section
extension LoanReviewView {
    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Remarks")
            
            PremiumCard {
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
                                .onChange(of: officerRemarks) { newValue in
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
                    
                    // Clear/Submit Remarks Button
                    Button {
                        if officerRemarks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            withAnimation {
                                highlightRemarks = true
                            }
                        } else {
                            // Just a visual feedback saving success
                            highlightRemarks = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Save Remarks")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    officerRemarks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                    LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(
                                        colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.15, green: 0.35, blue: 0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color.blue.opacity(0.15), radius: 8, x: 0, y: 4)
                        )
                    }
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
}

// MARK: - Timeline Section
extension LoanReviewView {
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Application Timeline",
                subtitle: "History of updates & audits",
                icon: "clock.arrow.2.circlepath"
            )
            
            PremiumCard {
                if application.timeline.isEmpty {
                    Text("No timeline events logged yet.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<application.timeline.count, id: \.self) { index in
                            let event = application.timeline[index]
                            TimelineRow(
                                event: event,
                                isFirst: index == 0,
                                isLast: index == application.timeline.count - 1
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

// MARK: - Floating Action Bar
extension LoanReviewView {
    private var floatingActionBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    actionPill(icon: "checkmark.circle.fill", text: "Approve", gradient: [.blue]) {
                        if officerRemarks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            withAnimation {
                                highlightRemarks = true
                            }
                        } else if !application.canProceedToApproval {
                            showBlockerAlert = true
                        } else {
                            viewModel.showApproveConfirmation = true
                        }
                    }

                    actionPill(icon: "xmark.circle.fill", text: "Reject", gradient: [.red, Color(red: 0.85, green: 0.15, blue: 0.15)]) {
                        if officerRemarks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            withAnimation {
                                highlightRemarks = true
                            }
                        } else {
                            viewModel.showRejectConfirmation = true
                        }
                    }

                    actionPill(icon: "arrow.up.circle.fill", text: "Escalate", gradient: [.purple, Color(red: 0.6, green: 0.2, blue: 0.85)]) {
                        highlightRemarks = false
                        viewModel.showEscalateSheet = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(.container, edges: .bottom)
            )
        }
    }

    private func actionPill(icon: String, text: String, gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(text)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: gradient.first?.opacity(0.35) ?? .clear, radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
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
                    if !escalationNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        viewModel.escalateApplication(application, remarks: escalationNotes)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.showEscalateSheet = false
                    }
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
                    if !requestedDocumentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        viewModel.requestDocument(application, docName: requestedDocumentName, note: requestedDocumentNote)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.showDocumentRequest = false
                    }
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
            .environmentObject(AppViewModel())
    }
}
