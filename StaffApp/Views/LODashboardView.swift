import SwiftUI

// MARK: - Dashboard View

struct LODashboardView: View {
    @Environment(SessionStore.self) private var session
    @State private var applications: [LoanApplication] = []
//    @State private var fieldVisits: [FieldVisit] = FieldVisit.mockVisits
    @State private var isLoading = true

    private var officerName: String {
        session.currentUser?.fullName.components(separatedBy: " ").first ?? "Officer"
    }

    private var assignedCount: Int { applications.count }
    private var pendingReviewCount: Int { applications.filter { $0.status == .submitted || $0.status == .underReview }.count }
    private var awaitingDocsCount: Int { applications.filter { $0.status == .additionalInfoRequired }.count }

    private var priorityApps: [LoanApplication] {
        applications.filter { $0.status == .submitted || $0.status == .underReview || $0.status == .additionalInfoRequired }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {

                    // Greeting header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Good \(greeting()), \(officerName) 👋")
                                .font(.lmsTitle2)
                            Text("Here's your workload for today")
                                .font(.lmsSubheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        NavigationLink(destination: LONotificationsView()){
                        // Notification badge indicator
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                
                                    .font(.title2)
                                    .foregroundStyle(Color.lmsNavyBlue)
                                Circle()
                                    .fill(Color.lmsDanger)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                    
                    .padding(.horizontal, Spacing.m)
                    .padding(.top, Spacing.s)

                    // KPI Cards
                    HStack(spacing: Spacing.m) {
                        KPICard(title: "Assigned", value: "\(assignedCount)", icon: "tray.full.fill", color: .lmsNavyBlue)
                        KPICard(title: "Pending Review", value: "\(pendingReviewCount)", icon: "clock.fill", color: .lmsWarning)
                        KPICard(title: "Needs Docs", value: "\(awaitingDocsCount)", icon: "doc.badge.ellipsis", color: .lmsDanger)
                    }
                    .padding(.horizontal, Spacing.m)

//                    // Fraud Alert Banner (if any flagged app)
//                    if let flagged = applications.first(where: { MockData.fraudFlagged($0) }) {
//                        FraudAlertBanner(application: flagged)
//                            .padding(.horizontal, Spacing.m)
//                    }

                    //Applications
                    DashboardSection(title: "Applications") {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if priorityApps.isEmpty {
                            EmptyStateView(icon: "checkmark.seal.fill", title: "All Clear!", message: "No pending applications.")
                                .frame(height: 120)
                        } else {
                            ForEach(priorityApps) { app in
                                NavigationLink {
                                    LOApplicationDetailView(application: app)
                                } label: {
                                    PriorityCard(application: app)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Upcoming Field Visits
//                    DashboardSection(title: "Upcoming Field Visits") {
//                        if fieldVisits.isEmpty {
//                            Text("No visits scheduled.")
//                                .font(.lmsBody)
//                                .foregroundStyle(.secondary)
//                                .padding()
//                        } else {
//                            ForEach(fieldVisits) { visit in
//                                FieldVisitCard(visit: visit)
//                            }
//                        }
//                    }

                    Spacer(minLength: Spacing.xxl)
                }
                .padding(.vertical, Spacing.m)
            }
            .navigationTitle("Dashboard")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .task {
                await loadApplications()
            }
            .refreshable {
                await loadApplications()
            }
        }
    }

    private func loadApplications() async {
        isLoading = true
        let service = MockData.sharedLoanService
        if let apps = try? await service.fetchAssignedApplications(officerID: MockData.loanOfficerUser.id) {
            applications = apps
        }
        isLoading = false
    }

    private func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Morning"
        case 12..<17: return "Afternoon"
        default: return "Evening"
        }
    }
}

// MARK: - Sub-Components

struct KPICard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text(title)
                .font(.lmsCaption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(.background, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}


struct DashboardSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .font(.lmsTitle2)
                .padding(.horizontal, Spacing.m)
            content
        }
    }
}

struct PriorityCard: View {
    let application: LoanApplication

    private var borrowerName: String {
        MockData.borrowerUser(for: application.borrowerID)?.fullName ?? "—"
    }

    private var appIDShort: String {
        "#\(application.id.uuidString.prefix(8).uppercased())"
    }

    private var timeAgo: String {
        let diff = Date().timeIntervalSince(application.updatedAt)
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }

    private var statusTone: StatusBadge.Tone {
        switch application.status {
        case .submitted: return .info
        case .underReview: return .warning
        case .additionalInfoRequired: return .danger
        default: return .neutral
        }
    }

    private var isFraudFlagged: Bool { MockData.fraudFlagged(application) }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(borrowerName.prefix(1))
                    .font(.lmsHeadline)
                    .foregroundStyle(avatarColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(borrowerName).font(.lmsHeadline)
                    if isFraudFlagged {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundStyle(Color.lmsDanger)
                            .font(.caption)
                    }
                }
                Text("\(application.loanType.rawValue.capitalized) Loan • \(Formatting.currency(application.requestedAmount))")
                    .font(.lmsCaption)
                    .foregroundStyle(.secondary)
                Text(appIDShort)
                    .font(.lmsMono)
                    .foregroundStyle(.secondary)
                    .font(.caption2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                StatusBadge(application.status.displayName, tone: statusTone)
                Text(timeAgo)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(Spacing.m)
        .background(.background, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        .padding(.horizontal, Spacing.m)
    }

    private var avatarColor: Color {
        let colors: [Color] = [.lmsNavyBlue, .lmsPrimary, .lmsAccent, .lmsSuccess, .lmsWarning]
        let idx = abs(application.borrowerID.hashValue) % colors.count
        return colors[idx]
    }
}

// MARK: - Field Visit Card

//struct FieldVisitCard: View {
//    let visit: FieldVisit
//
//    var body: some View {
//        HStack(spacing: Spacing.m) {
//            VStack(spacing: 4) {
//                Image(systemName: "calendar.badge.clock")
//                    .font(.title3)
//                    .foregroundStyle(Color.lmsPrimary)
//                Text(visit.dateLabel)
//                    .font(.lmsCaption.weight(.semibold))
//                    .foregroundStyle(Color.lmsPrimary)
//            }
//            .frame(width: 64)
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text(visit.borrowerName).font(.lmsHeadline)
//                Text(visit.purpose).font(.lmsCaption).foregroundStyle(.secondary)
//                Text(visit.address).font(.caption2).foregroundStyle(.tertiary)
//            }
//
//            Spacer()
//
//            StatusBadge(visit.status, tone: visit.statusTone)
//        }
//        .padding(Spacing.m)
//        .background(.background, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
//        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
//        .padding(.horizontal, Spacing.m)
//    }
//}
//
//// MARK: - Field Visit Model
//
//struct FieldVisit: Identifiable {
//    var id: UUID = UUID()
//    var borrowerName: String
//    var purpose: String
//    var address: String
//    var date: Date
//    var status: String
//    var statusTone: StatusBadge.Tone
//
//    var dateLabel: String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "dd MMM"
//        return formatter.string(from: date)
//    }
//
//    static let mockVisits: [FieldVisit] = [
//        FieldVisit(borrowerName: "Jane Doe", purpose: "Property Verification",
//                   address: "12 Maple Ave, Mumbai",
//                   date: Calendar.current.date(byAdding: .day, value: 2, to: .now)!,
//                   status: "Scheduled", statusTone: .info),
//        FieldVisit(borrowerName: "Robert King", purpose: "Address Verification",
//                   address: "45 Industrial Road, Pune",
//                   date: Calendar.current.date(byAdding: .day, value: 4, to: .now)!,
//                   status: "Pending", statusTone: .warning)
//    ]
//}

// MARK: - Shared Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.5))
            Text(title)
                .font(.lmsTitle2)
            Text(message)
                .font(.lmsBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.l)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension ApplicationStatus {
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .submitted: return "Submitted"
        case .underReview: return "Under Review"
        case .additionalInfoRequired: return "Needs Docs"
        case .recommended: return "Recommended"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .disbursed: return "Disbursed"
        case .closed: return "Closed"
        }
    }
}

#Preview {
    LODashboardView()
        .environment(SessionStore(currentUser: MockData.loanOfficerUser, staffProfile: MockData.loanOfficerStaff))
}
