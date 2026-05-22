import SwiftUI

struct ApplicationTrackingView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var viewModel = DashboardViewModel()

    var body: some View {
        List {
            if viewModel.isLoading {
                Section {
                    HStack { Spacer(); ProgressView(); Spacer() }
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
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("My Applications")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if let env, let userID = session.currentUser?.id {
                await viewModel.fetchDashboardData(loanService: env.loans, borrowerID: userID)
            }
        }
    }

    private func statusBadge(for status: ApplicationStatus) -> some View {
        switch status {
        case .draft, .submitted:
            return StatusBadge(status.rawValue.capitalized, tone: .neutral)
        case .underReview, .additionalInfoRequired, .recommended:
            return StatusBadge(status.rawValue.capitalized, tone: .warning)
        case .approved, .disbursed:
            return StatusBadge(status.rawValue.capitalized, tone: .success)
        case .rejected:
            return StatusBadge(status.rawValue.capitalized, tone: .danger)
        case .closed:
            return StatusBadge(status.rawValue.capitalized, tone: .neutral)
        }
    }
}

struct PipelineTrackerView: View {
    let status: ApplicationStatus

    var body: some View {
        HStack {
            stepView(title: "Submitted", isCompleted: true)
            line(isActive: status != .draft && status != .submitted)
            stepView(title: "Review", isCompleted: isReviewCompleted)
            line(isActive: isApprovedOrDisbursed)
            stepView(title: "Approved", isCompleted: isApprovedOrDisbursed)
        }
    }

    private var isReviewCompleted: Bool {
        status == .approved || status == .disbursed || status == .rejected
    }

    private var isApprovedOrDisbursed: Bool {
        status == .approved || status == .disbursed
    }

    private func stepView(title: String, isCompleted: Bool) -> some View {
        VStack(spacing: Spacing.xs) {
            Circle()
                .fill(isCompleted ? Color.lmsSuccess : Color.lmsFill)
                .frame(width: 12, height: 12)
            Text(title)
                .font(.caption2)
                .foregroundStyle(isCompleted ? .primary : .secondary)
        }
    }

    private func line(isActive: Bool) -> some View {
        Rectangle()
            .fill(isActive ? Color.lmsSuccess : Color.lmsFill)
            .frame(height: 2)
            .padding(.bottom, 14)
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
