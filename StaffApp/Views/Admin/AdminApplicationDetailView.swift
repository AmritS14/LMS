import SwiftUI

struct AdminApplicationDetailView: View {
    let applicationID: UUID
    @State private var viewModel: AdminApplicationDetailViewModel
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    init(applicationID: UUID) {
        self.applicationID = applicationID
        _viewModel = State(initialValue: AdminApplicationDetailViewModel(applicationID: applicationID))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.application == nil {
                loadingView
            } else if let error = viewModel.error {
                errorView(error)
            } else if let app = viewModel.application {
                detailContent(app)
            } else {
                emptyView
            }
        }
        .background(AdminColor.background)
        .navigationTitle("Application Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(environment: env)
            await viewModel.loadDetails()
            viewModel.subscribeToRealtimeChanges()
        }
        .onDisappear {
            viewModel.unsubscribeFromRealtime()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading application details...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            
            Text("Failed to Load Details")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Retry") {
                Task {
                    await viewModel.loadDetails()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AdminColor.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "Application Not Found",
            systemImage: "doc.questionmark",
            description: Text("The requested application could not be located.")
        )
    }

    private func detailContent(_ app: LoanApplication) -> some View {
        List {
            // Overview Section
            Section {
                overviewRow(title: "Applicant Name", value: viewModel.borrower?.fullName ?? "—")
                overviewRow(title: "Application ID", value: "APP-\(app.id.uuidString.prefix(8).uppercased())")
                overviewRow(title: "Loan Type", value: app.loanType.rawValue.capitalized)
                overviewRow(title: "Requested Amount", value: Formatting.currency(app.requestedAmount))
                overviewRow(title: "Application Date", value: Formatting.date(app.createdAt))
                
                HStack {
                    Text("Current Status")
                        .foregroundStyle(.secondary)
                    Spacer()
                    StatusBadge(
                        app.status.rawValue.capitalized,
                        tone: app.status == .approved || app.status == .disbursed ? .success : (app.status == .rejected ? .danger : .warning)
                    )
                }
            } header: {
                Text("Application Overview")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .textCase(nil)
            }

            // Loan Processing Tracking Timeline
            Section {
                ProcessingTimelineView(stages: computeStages(app))
                    .padding(.vertical, Spacing.s)
            } header: {
                Text("Loan Processing Tracking")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func overviewRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Stages Calculation

    private func computeStages(_ app: LoanApplication) -> [TrackingStage] {
        let borrowerName = viewModel.borrower?.fullName ?? "Applicant"
        let loName = viewModel.loanOfficer?.fullName ?? "Loan Officer"
        let mgrName = viewModel.manager?.fullName ?? "Manager"
        
        let format = DateFormatter()
        format.dateStyle = .medium
        format.timeStyle = .short
        
        // Find events to display accurate dates
        let submitEvent = viewModel.events.first(where: { $0.eventType.lowercased() == "submitted" || $0.eventType.lowercased() == "application_created" })
        let assignLOEvent = viewModel.events.first(where: { $0.eventType.lowercased() == "assigned" })
        let reviewLOEvent = viewModel.events.first(where: { $0.eventType.lowercased() == "start-review" || $0.eventType.lowercased() == "review_started" })
        let escalateEvent = viewModel.events.first(where: { $0.eventType.lowercased() == "send-to-manager" || $0.eventType.lowercased() == "sent_to_manager" })
        let decisionEvent = viewModel.events.first(where: { $0.eventType.lowercased() == "approve" || $0.eventType.lowercased() == "reject" || $0.eventType.lowercased() == "approved" || $0.eventType.lowercased() == "rejected" })

        // 1. Application Submitted
        let submitStage = TrackingStage(
            title: "Application Submitted",
            subtitle: "Submitted by \(borrowerName)",
            date: submitEvent.map { format.string(from: $0.createdAt) } ?? format.string(from: app.createdAt),
            status: .completed
        )

        // 2. Assigned Loan Officer
        let loAssigned = app.assignedOfficerID != nil
        let loAssignStage = TrackingStage(
            title: "Assigned Loan Officer",
            subtitle: loAssigned ? "Assigned to \(loName)" : "Awaiting assignment",
            date: assignLOEvent.map { format.string(from: $0.createdAt) },
            status: loAssigned ? .completed : (app.status == .draft || app.status == .submitted ? .current : .pending)
        )

        // 3. Loan Officer Review
        let loReviewed = [.escalated, .approved, .rejected, .disbursed, .closed].contains(app.status)
        let loReviewing = [.underReview, .additionalInfoRequired].contains(app.status)
        let loReviewStage = TrackingStage(
            title: "Loan Officer Review",
            subtitle: loReviewed ? "Review completed by \(loName)" : (loReviewing ? (app.status == .additionalInfoRequired ? "Information requested from borrower" : "Review in progress by \(loName)") : "Pending officer review"),
            date: reviewLOEvent.map { format.string(from: $0.createdAt) },
            status: loReviewed ? .completed : (loReviewing ? .current : .pending)
        )

        // 4. Assigned Manager
        let isEscalated = [.escalated, .approved, .rejected, .disbursed, .closed].contains(app.status)
        let hasManager = viewModel.manager != nil
        let managerAssignStage = TrackingStage(
            title: "Assigned Manager",
            subtitle: hasManager ? "Assigned to \(mgrName)" : "Awaiting escalation",
            date: escalateEvent.map { format.string(from: $0.createdAt) },
            status: isEscalated ? .completed : (loReviewed ? .current : .pending)
        )

        // 5. Manager Review
        let isDecided = [.approved, .rejected, .disbursed, .closed].contains(app.status)
        let managerReviewStage = TrackingStage(
            title: "Manager Review",
            subtitle: isDecided ? "Review completed by \(mgrName)" : (app.status == .escalated ? "Escalated to \(mgrName) for decision" : "Pending manager review"),
            date: escalateEvent.map { format.string(from: $0.createdAt) },
            status: isDecided ? .completed : (app.status == .escalated ? .current : .pending)
        )

        // 6. Decision (Approved / Rejected)
        var decisionStatus: StageStatus = .pending
        var decisionSubtitle = "Awaiting final decision"
        if app.status == .rejected {
            decisionStatus = .failed
            decisionSubtitle = "Rejected by \(mgrName)"
        } else if [.approved, .disbursed, .closed].contains(app.status) {
            decisionStatus = .completed
            decisionSubtitle = "Approved by \(mgrName)"
        }

        let decisionStage = TrackingStage(
            title: app.status == .rejected ? "Rejected" : "Approved / Rejected",
            subtitle: decisionSubtitle,
            date: decisionEvent.map { format.string(from: $0.createdAt) },
            status: decisionStatus
        )

        return [submitStage, loAssignStage, loReviewStage, managerAssignStage, managerReviewStage, decisionStage]
    }
}

// MARK: - Timeline Timeline Helpers

enum StageStatus {
    case completed
    case current
    case pending
    case failed

    var color: Color {
        switch self {
        case .completed: return .green
        case .current: return .blue
        case .pending: return .gray.opacity(0.3)
        case .failed: return .red
        }
    }
}

struct TrackingStage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let date: String?
    let status: StageStatus
}

struct ProcessingTimelineView: View {
    let stages: [TrackingStage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(stages.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 16) {
                    // Left Timeline bar / Node
                    VStack(spacing: 0) {
                        nodeCircle(for: stages[index].status)
                        
                        if index < stages.count - 1 {
                            Rectangle()
                                .fill(lineColor(from: stages[index].status, to: stages[index + 1].status))
                                .frame(width: 2)
                                .frame(minHeight: 36)
                        }
                    }
                    .frame(width: 24)
                    
                    // Right Content details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stages[index].title)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(stages[index].status == .pending ? .secondary : .primary)
                        
                        if let subtitle = stages[index].subtitle {
                            Text(subtitle)
                                .font(.footnote)
                                .foregroundStyle(stages[index].status == .pending ? .tertiary : .secondary)
                        }
                        
                        if let date = stages[index].date {
                            Text(date)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
    }

    @ViewBuilder
    private func nodeCircle(for status: StageStatus) -> some View {
        ZStack {
            Circle()
                .fill(status.color)
                .frame(width: 24, height: 24)
            
            switch status {
            case .completed:
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            case .current:
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
            case .failed:
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            case .pending:
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func lineColor(from current: StageStatus, to next: StageStatus) -> Color {
        if current == .completed && (next == .completed || next == .current || next == .failed) {
            return .green
        }
        if current == .failed {
            return .red
        }
        return Color.gray.opacity(0.3)
    }
}
