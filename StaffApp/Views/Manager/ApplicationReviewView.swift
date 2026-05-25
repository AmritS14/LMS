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
                documentsSection
                evaluationSection(app)
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

    // MARK: Sections

    private func borrowerSection(_ app: ManagerApplication) -> some View {
        SectionCard(title: "Borrower Profile") {
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

    private func loanSection(_ app: ManagerApplication) -> some View {
        SectionCard(title: "Loan Configuration") {
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

    private func evaluationSection(_ app: ManagerApplication) -> some View {
        SectionCard(title: "Officer Evaluation") {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "quote.opening")
                    .font(.title2)
                    .foregroundStyle(Color.lmsAccent)
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text(app.evaluationNote)
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.primary)
                    Text("— \(app.officerName)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
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
            .environment(ManagerStore())
    }
}
