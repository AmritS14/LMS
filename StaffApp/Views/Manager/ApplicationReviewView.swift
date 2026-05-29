import SwiftUI

struct ApplicationReviewView: View {
    let applicationID: UUID

    @Environment(ManagerStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var activeSheet: ApplicationActionType?
    @State private var pendingResult: ApplicationActionType?
    @State private var completed: ApplicationActionType?
    @State private var verifiedDocs: Set<String> = Set(Self.documents)

    private static let documents = ["Government ID", "Income Proof", "Collateral Proof"]
    private static let documentIcons = [
        "Government ID": "person.text.rectangle",
        "Income Proof": "doc.text",
        "Collateral Proof": "building.columns"
    ]

    private var app: ManagerApplication? { store.application(id: applicationID) }

    var body: some View {
        Group {
            if let app {
                content(app)
            } else {
                ContentUnavailableView("Application unavailable",
                                       systemImage: "doc.questionmark",
                                       description: Text("This application is no longer in the queue."))
            }
        }
        .navigationTitle("Review Application")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ app: ManagerApplication) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.m) {
                borrowerSection(app)
                loanSection(app)
                riskSummarySection(app)
                evaluationSection(app)
                documentsSection
                timelineSection(app)
            }
            .padding(Spacing.m)
        }
        .background(Color.lmsBackground)
        .safeAreaInset(edge: .bottom) { actionBar(app) }
        .sheet(item: $activeSheet, onDismiss: presentSuccessIfNeeded) { action in
            decisionSheet(action, app: app)
        }
        .fullScreenCover(item: $completed) { action in
            SuccessStateView(
                actionType: action,
                applicant: app.borrowerName,
                reference: app.referenceCode,
                officer: app.officerName,
                onFinish: { dismiss() }
            )
        }
    }

    // MARK: Borrower Summary

    private func borrowerSection(_ app: ManagerApplication) -> some View {
        SectionCard(title: "Borrower Summary") {
            HStack(spacing: Spacing.sm) {
                AvatarView(initials: app.borrowerInitials, size: 50)
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.borrowerName).font(.lmsHeadline)
                    Text(app.base.employmentType).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(app.riskLevel.rawValue + " Risk", tone: app.riskLevel.tone,
                            icon: app.riskLevel.icon, size: .small)
            }

            HStack(spacing: Spacing.sm) {
                statTile("Annual Income", app.annualIncomeText)
                statTile("Credit Score", "\(app.creditScore)")
            }
        }
    }

    // MARK: Loan Details

    private func loanSection(_ app: ManagerApplication) -> some View {
        SectionCard(title: "Loan Details") {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Requested Amount").font(.caption).foregroundStyle(.secondary)
                Text(app.amountText)
                    .font(.system(.title, design: .rounded).weight(.bold))
            }
            Divider()
            DetailRow(icon: "calendar", title: "Loan Term", value: app.tenureText)
            DetailRow(icon: "briefcase", title: "Primary Purpose", value: app.purpose)
            DetailRow(icon: "indianrupeesign.circle", title: "Estimated EMI", value: app.emiText)
        }
    }

    // MARK: Borrower Risk Summary (NEW)

    private func riskSummarySection(_ app: ManagerApplication) -> some View {
        SectionCard(title: "Borrower Risk Summary") {
            HStack(spacing: Spacing.m) {
                // Credit Score Gauge
                VStack(spacing: Spacing.xs) {
                    ZStack {
                        Circle()
                            .stroke(Color.lmsGray5, lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: min(Double(app.creditScore) / 900.0, 1.0))
                            .stroke(creditScoreColor(app.creditScore), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text("\(app.creditScore)")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                            Text("CIBIL")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 64, height: 64)
                    Text("Credit Score")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Metrics
                VStack(alignment: .leading, spacing: Spacing.s) {
                    riskMetricRow("Risk Level", app.riskLevel.rawValue, tone: app.riskLevel.tone)
                    riskMetricRow("DTI Ratio", "\(String(format: "%.0f", app.debtToIncomeRatio * 100))%",
                                  tone: app.debtToIncomeRatio > 0.5 ? .danger : app.debtToIncomeRatio > 0.35 ? .warning : .success)
                    riskMetricRow("Eligibility", "\(app.eligibilityScore)%",
                                  tone: app.eligibilityScore >= 75 ? .success : app.eligibilityScore >= 50 ? .warning : .danger)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func creditScoreColor(_ score: Int) -> Color {
        switch score {
        case ..<600: return .lmsDanger
        case 600..<680: return .lmsWarning
        case 680..<740: return .lmsInfo
        default: return .lmsSuccess
        }
    }

    private func riskMetricRow(_ title: String, _ value: String, tone: StatusBadge.Tone) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            StatusBadge(value, tone: tone, size: .small)
        }
    }

    // MARK: Officer Recommendation

    private func evaluationSection(_ app: ManagerApplication) -> some View {
        SectionCard(title: "Officer Recommendation") {
            HStack {
                StatusBadge(app.recommendation.badgeText, tone: app.recommendation.tone, size: .medium)
                Spacer()
                Text("by \(app.officerName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "quote.opening")
                    .font(.title2)
                    .foregroundStyle(Color.lmsAccent)
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text(app.evaluationNote)
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: Verified Documents

    private var documentsSection: some View {
        SectionCard(title: "Verified Documents",
                    footer: "Tap a document to toggle verification.") {
            HStack {
                Text("Verification")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                StatusBadge("\(verifiedDocs.count) of \(Self.documents.count) Verified",
                            tone: verifiedDocs.count == Self.documents.count ? .success : .warning,
                            size: .small)
            }
            ForEach(Self.documents, id: \.self) { doc in
                documentRow(doc)
            }
        }
    }

    // MARK: Timeline (NEW)

    private func timelineSection(_ app: ManagerApplication) -> some View {
        SectionCard(title: "Timeline") {
            VStack(alignment: .leading, spacing: 0) {
                timelineStep(icon: "doc.text", title: "Application Submitted",
                             subtitle: Formatting.date(app.base.application.createdAt),
                             isComplete: true, isLast: false)
                timelineStep(icon: "person.badge.clock", title: "Assigned to Officer",
                             subtitle: app.officerName,
                             isComplete: true, isLast: false)
                timelineStep(icon: "magnifyingglass", title: "Under Review",
                             subtitle: "Risk assessment completed",
                             isComplete: app.status != .submitted, isLast: false)
                timelineStep(icon: statusIcon(for: app.status), title: statusTitle(for: app.status),
                             subtitle: app.status.displayLabel,
                             isComplete: app.status == .approved || app.status == .rejected || app.status == .disbursed,
                             isLast: true)
            }
        }
    }

    private func timelineStep(icon: String, title: String, subtitle: String,
                               isComplete: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isComplete ? Color.lmsAccent : Color.lmsGray4)
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isComplete ? .white : .secondary)
                }
                if !isLast {
                    Rectangle()
                        .fill(isComplete ? Color.lmsAccent.opacity(0.3) : Color.lmsGray5)
                        .frame(width: 2, height: 28)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isComplete ? .primary : .secondary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, isLast ? 0 : Spacing.s)

            Spacer()
        }
    }

    private func statusIcon(for status: ApplicationStatus) -> String {
        switch status {
        case .approved, .disbursed: return "checkmark.seal.fill"
        case .rejected: return "xmark.octagon.fill"
        case .additionalInfoRequired: return "arrow.uturn.backward"
        default: return "clock"
        }
    }

    private func statusTitle(for status: ApplicationStatus) -> String {
        switch status {
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .disbursed: return "Disbursed"
        case .additionalInfoRequired: return "Sent Back"
        default: return "Decision Pending"
        }
    }

    // MARK: Components

    private func statTile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value).font(.lmsHeadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(Color.lmsBackground, in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
    }

    private func documentRow(_ doc: String) -> some View {
        let verified = verifiedDocs.contains(doc)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if verified { verifiedDocs.remove(doc) } else { verifiedDocs.insert(doc) }
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: Self.documentIcons[doc] ?? "doc")
                    .foregroundStyle(Color.lmsAccent)
                    .frame(width: 24)
                Text(doc).font(.subheadline).foregroundStyle(.primary)
                Spacer()
                Image(systemName: verified ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(verified ? Color.lmsSuccess : Color.lmsGray4)
            }
            .padding(Spacing.sm)
            .background(Color.lmsBackground, in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Action bar

    private func actionBar(_ app: ManagerApplication) -> some View {
        VStack(spacing: Spacing.s) {
            HStack(spacing: Spacing.s) {
                Button(role: .destructive) { activeSheet = .reject } label: {
                    Label("Reject", systemImage: "slash.circle").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.lmsDanger)

                Button { activeSheet = .sendBack } label: {
                    Label("Send Back", systemImage: "arrow.uturn.backward").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.lmsWarning)
            }
            .controlSize(.large)

            Button { activeSheet = .approve } label: {
                Label("Approve", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 28)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: CornerRadius.button))
            .controlSize(.large)
            .tint(.lmsSuccess)
        }
        .padding(Spacing.m)
        .background(.bar)
    }

    @ViewBuilder
    private func decisionSheet(_ action: ApplicationActionType, app: ManagerApplication) -> some View {
        let onComplete: (String?) -> Void = { remarks in
            store.decide(action, on: app, remarks: remarks)
            pendingResult = action
        }
        switch action {
        case .approve:
            ApproveModalView(app: app, onComplete: onComplete)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        case .reject:
            RejectModalView(app: app, onComplete: onComplete)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        case .sendBack:
            SendBackModalView(app: app, onComplete: onComplete)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func presentSuccessIfNeeded() {
        guard let result = pendingResult else { return }
        pendingResult = nil
        completed = result
    }
}

#Preview {
    NavigationStack {
        ApplicationReviewView(applicationID: UUID())
            .environment(ManagerStore.preview)
    }
}
