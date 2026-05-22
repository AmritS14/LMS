import SwiftUI

struct ApplicationTrackingView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let error = viewModel.errorMessage {
                Text(error).foregroundStyle(Color.lmsDanger)
            } else if viewModel.applications.isEmpty {
                Text("No applications found.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.applications) { app in
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        HStack {
                            Text("\(app.loanType.rawValue.capitalized) Loan").font(.lmsHeadline)
                            Spacer()
                            statusBadge(for: app.status)
                        }
                        Text(Formatting.currency(app.requestedAmount))
                            .font(.lmsBody)
                        Text("Submitted on \(Formatting.date(app.createdAt))")
                            .font(.lmsCaption)
                            .foregroundStyle(.secondary)
                            
                        // Status Pipeline Tracker
                        PipelineTrackerView(status: app.status)
                            .padding(.top, Spacing.s)
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
        }
        .navigationTitle("My Applications")
        .task {
            if let env = env, let userID = session.currentUser?.id {
                await viewModel.fetchDashboardData(loanService: env.loans, borrowerID: userID)
            }
        }
    }
    
    private func statusBadge(for status: ApplicationStatus) -> some View {
        switch status {
        case .draft, .submitted: return StatusBadge(status.rawValue.capitalized, tone: .neutral)
        case .underReview, .additionalInfoRequired, .recommended: return StatusBadge(status.rawValue.capitalized, tone: .warning)
        case .approved, .disbursed: return StatusBadge(status.rawValue.capitalized, tone: .success)
        case .rejected: return StatusBadge(status.rawValue.capitalized, tone: .danger)
        case .closed: return StatusBadge(status.rawValue.capitalized, tone: .neutral)
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
        VStack {
            Circle()
                .fill(isCompleted ? Color.lmsSuccess : Color.gray.opacity(0.3))
                .frame(width: 12, height: 12)
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(isCompleted ? .primary : .secondary)
        }
    }
    
    private func line(isActive: Bool) -> some View {
        Rectangle()
            .fill(isActive ? Color.lmsSuccess : Color.gray.opacity(0.3))
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
