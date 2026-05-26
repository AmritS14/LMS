import SwiftUI

struct ApplicationReviewView: View {
    let applicationID: UUID

    @Environment(ManagerStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var activeSheet: ApplicationActionType?
    @State private var pendingResult: ApplicationActionType?
    @State private var completed: ApplicationActionType?

    @State private var showDisburseConfirm = false
    @State private var isDisbursing = false
    @State private var disburseError: String?

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
                documentsSection(app)
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
        .confirmationDialog(
            "Disburse \(app.amountText) to \(app.borrowerName)?",
            isPresented: $showDisburseConfirm,
            titleVisibility: .visible
        ) {
            Button("Disburse Loan") { disburse(app) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This creates the loan and EMI schedule and notifies the borrower. This can't be undone.")
        }
        .alert("Disbursement Failed", isPresented: Binding(
            get: { disburseError != nil },
            set: { if !$0 { disburseError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(disburseError ?? "")
        }
    }

    private func disburse(_ app: ManagerApplication) {
        isDisbursing = true
        Task {
            do {
                try await store.disburse(app)
                isDisbursing = false
            } catch {
                disburseError = error.localizedDescription
                isDisbursing = false
            }
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

    @ViewBuilder
    private func documentsSection(_ app: ManagerApplication) -> some View {
        SectionCard(title: "Submitted Documents",
                    footer: "Documents and their verification status from the loan officer's review.") {
            HStack {
                Text("Verification")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if app.totalDocumentCount > 0 {
                    StatusBadge("\(app.verifiedDocumentCount) of \(app.totalDocumentCount) Verified",
                                tone: app.allDocumentsVerified ? .success : .warning,
                                size: .small)
                }
            }
            if app.documents.isEmpty {
                Text("No documents uploaded yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.xs)
            } else {
                ForEach(app.documents) { doc in
                    documentRow(doc)
                }
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

    private func documentRow(_ doc: LoanDocument) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: Self.icon(for: doc.kind))
                .foregroundStyle(Color.lmsAccent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.label(for: doc.kind)).font(.subheadline).foregroundStyle(.primary)
                Text(doc.fileName).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            documentStatusIndicator(doc.status)
        }
        .padding(Spacing.sm)
        .background(Color.lmsBackground, in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
    }

    @ViewBuilder
    private func documentStatusIndicator(_ status: DocumentVerificationStatus) -> some View {
        switch status {
        case .verified:
            Image(systemName: "checkmark.circle.fill").font(.title3).foregroundStyle(Color.lmsSuccess)
        case .rejected:
            Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(Color.lmsDanger)
        case .pending:
            Image(systemName: "clock.fill").font(.title3).foregroundStyle(Color.lmsWarning)
        }
    }

    private static func label(for kind: DocumentKind) -> String {
        switch kind {
        case .identityProof: "Identity Proof"
        case .addressProof:  "Address Proof"
        case .incomeProof:   "Income Proof"
        case .bankStatement: "Bank Statement"
        case .collateral:    "Collateral Proof"
        case .other:         "Document"
        }
    }

    private static func icon(for kind: DocumentKind) -> String {
        switch kind {
        case .identityProof: "person.text.rectangle"
        case .addressProof:  "house"
        case .incomeProof:   "doc.text"
        case .bankStatement: "building.columns"
        case .collateral:    "shield"
        case .other:         "doc"
        }
    }

    // MARK: Action bar

    @ViewBuilder
    private func actionBar(_ app: ManagerApplication) -> some View {
        VStack(spacing: Spacing.s) {
            switch app.status {
            case .approved:
                disburseBar
            case .disbursed:
                statusPill("Loan Disbursed", systemImage: "checkmark.seal.fill", tone: .lmsSuccess)
            case .rejected:
                statusPill("Application Rejected", systemImage: "slash.circle", tone: .lmsDanger)
            default:
                reviewBar
            }
        }
        .padding(Spacing.m)
        .background(.bar)
    }

    private var reviewBar: some View {
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
    }

    private var disburseBar: some View {
        Button { showDisburseConfirm = true } label: {
            HStack(spacing: Spacing.s) {
                if isDisbursing {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "indianrupeesign.circle.fill")
                }
                Text(isDisbursing ? "Disbursing…" : "Disburse Loan")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 28)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: CornerRadius.button))
        .controlSize(.large)
        .tint(.lmsAccent)
        .disabled(isDisbursing)
    }

    private func statusPill(_ text: String, systemImage: String, tone: Color) -> some View {
        Label(text, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(tone)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(tone.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous))
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
