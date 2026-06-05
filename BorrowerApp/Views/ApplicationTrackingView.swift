import SwiftUI

struct ApplicationTrackingView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var viewModel = DashboardViewModel()

    var body: some View {
        List {
            if viewModel.isLoading {
                Section {
                    HStack { Spacer(); ProgressView().progressViewStyle(.circular); Spacer() }
                        .listRowBackground(Color.clear)
                }
            } else if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.lmsDanger)
                }
            } else if viewModel.applications.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Applications",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("You haven't submitted any loan applications yet.")
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(viewModel.applications) { app in
                    Section {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(app.loanType.rawValue.capitalized) Loan")
                                    .font(.lmsHeadline)
                                Spacer()
                                statusBadge(for: app.status)
                            }
                            Text(Formatting.currency(app.requestedAmount))
                                .font(.subheadline)
                            Text("Submitted on \(Formatting.date(app.createdAt))")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            PipelineTrackerView(status: app.status)
                                .padding(.top, Spacing.xs)

                            // Show sanction letter card if:
                            // 1. Event-based detection (officer sent via new flow), OR
                            // 2. Legacy: sanction letter status == "sent" from DB
                            let hasSLEvent = viewModel.sanctionLetterPDFPaths[app.id] != nil
                            let hasLegacyLetter = app.status == .approved &&
                                (app.sanctionLetter?.status == "sent" || app.sanctionLetter?.status == "accepted")
                            if hasSLEvent || hasLegacyLetter {
                                sanctionLetterPromptCard(for: app)
                                    .padding(.top, Spacing.s)
                            }
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("My Applications")
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await loadData() }
        .task { await loadData() }
    }

    private func loadData() async {
        guard let env, let userID = session.currentUser?.id else { return }
        await viewModel.fetchDashboardData(
            loanService: env.loans,
            sanctionLetterService: env.sanctionLetters,
            borrowerID: userID
        )
    }

    private func sanctionLetterPromptCard(for app: LoanApplication) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "doc.badge.checkmark.fill")
                    .foregroundColor(.accentColor)
                Text("Sanction Letter Ready")
                    .font(.subheadline.weight(.bold))
            }
            Text("Your official loan sanction letter is ready. Review the terms and accept it to proceed to disbursement.")
                .font(.caption)
                .foregroundColor(.secondary)

            NavigationLink(destination: SanctionLetterView(application: app).toolbar(.hidden, for: .tabBar)) {
                Label("View & Accept Letter", systemImage: "arrow.down.doc.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs_s)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
        .padding(Spacing.m)
        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }

    private func statusBadge(for status: ApplicationStatus) -> some View {
        switch status {
        case .draft, .submitted:
            return StatusBadge(status.displayLabel, tone: .neutral)
        case .underReview, .additionalInfoRequired, .recommended:
            return StatusBadge(status.displayLabel, tone: .warning)
        case .approved, .disbursed:
            return StatusBadge(status.displayLabel, tone: .success)
        case .rejected:
            return StatusBadge(status.displayLabel, tone: .danger)
        case .closed:
            return StatusBadge(status.displayLabel, tone: .neutral)
        case .escalated:
            return StatusBadge(status.displayLabel, tone: .warning)
        }
    }
}

struct PipelineTrackerView: View {
    let status: ApplicationStatus

    var body: some View {
        HStack(spacing: 0) {
            let order: [ApplicationStatus] = [.draft, .submitted, .underReview, .approved, .disbursed]
            ForEach(Array(order.enumerated()), id: \.offset) { idx, step in
                let isDone = isStepDone(current: status, step: step, order: order)
                let isCurrent = status == step

                VStack(spacing: Spacing.xs) {
                    ZStack {
                        Circle()
                            .fill(isDone || isCurrent ? Color.accentColor : Color.lmsFill)
                            .frame(width: 26, height: 26)
                        if isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        } else if isCurrent {
                            Circle().fill(.white).frame(width: 9, height: 9)
                        }
                    }
                    Text(step.rawValue.capitalized)
                        .font(.caption2.weight(isCurrent ? .semibold : .regular))
                        .foregroundStyle(isCurrent ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: 60)
                }

                if idx < order.count - 1 {
                    Rectangle()
                        .fill(isDone ? Color.accentColor : Color.lmsFill)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .offset(y: -10)
                }
            }
        }
    }

    private func isStepDone(current: ApplicationStatus, step: ApplicationStatus, order: [ApplicationStatus]) -> Bool {
        guard let ci = order.firstIndex(of: current),
              let si = order.firstIndex(of: step) else { return false }
        return si < ci
    }
}

#Preview {
    NavigationStack {
        ApplicationTrackingView()
            .environment(SessionStore(
                currentUser: MockAuthService.seedBorrower,
                borrowerProfile: MockAuthService.seedBorrowerProfile
            ))
            .environment(\.appEnvironment, AppEnvironment(
                auth: MockAuthService(),
                loans: MockLoanService(),
                documents: MockDocumentService(),
                notifications: MockNotificationService(),
                messaging: MockMessagingService(),
                keychain: MockKeychainService()
            ))
    }
}
