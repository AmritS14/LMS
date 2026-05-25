import SwiftUI

struct ApplicationTrackingView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding()
                } else if viewModel.applications.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.applications) { app in
                            applicationCard(app)
                        }
                    }
                    .padding()
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
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No applications found.")
                .font(.headline)
            Text("You haven't submitted any loan applications yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .padding()
    }
    
    // MARK: - Application Card
    private func applicationCard(_ app: LoanApplication) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(app.loanType.rawValue.capitalized) Loan Application")
                        .font(.headline)
                    Text(Formatting.currency(app.requestedAmount))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: icon(for: app.loanType))
                    .foregroundStyle(.blue)
                    .font(.title2)
            }
            
            Text("Submitted on \(Formatting.date(app.createdAt))")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if app.status == .rejected {
                HStack(spacing: 10) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red).font(.title2)
                    VStack(alignment: .leading) {
                        Text("Application Rejected").bold()
                    }
                }
            } else {
                HStack(spacing: 0) {
                    let order: [ApplicationStatus] = [.draft, .submitted, .underReview, .approved, .disbursed]
                    ForEach(Array(order.enumerated()), id: \.offset) { idx, step in
                        let isDone = isStepDone(current: app.status, step: step, order: order)
                        let isCurrent = app.status == step

                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(isDone || isCurrent ? Color.blue : Color(.systemFill))
                                    .frame(width: 28, height: 28)
                                if isDone {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                } else if isCurrent {
                                    Circle().fill(.white).frame(width: 10, height: 10)
                                }
                            }
                            Text(step.rawValue.capitalized)
                                .font(.system(size: 9, weight: isCurrent ? .bold : .regular))
                                .foregroundStyle(isCurrent ? .blue : .secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(width: 55)
                        }

                        if idx < order.count - 1 {
                            Rectangle()
                                .fill(isDone ? Color.blue : Color(.systemFill))
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                                .offset(y: -10)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    // MARK: - Helpers
    private func isStepDone(current: ApplicationStatus, step: ApplicationStatus, order: [ApplicationStatus]) -> Bool {
        guard let ci = order.firstIndex(of: current),
              let si = order.firstIndex(of: step) else { return false }
        return si < ci
    }
    
    private func icon(for type: LoanType) -> String {
        switch type {
        case .personal: return "person.fill"
        case .home: return "house.fill"
        case .vehicle: return "car.fill"
        case .education: return "graduationcap.fill"
        case .business: return "briefcase.fill"
        }
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
