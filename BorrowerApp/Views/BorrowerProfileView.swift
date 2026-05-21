import SwiftUI

struct BorrowerProfileView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    
    @State private var settledLoans: [Loan] = []

    var body: some View {
        ZStack(alignment: .top) {
            // Clean Background
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            // Subtle top header color accent
            GeometryReader { proxy in
                LinearGradient(
                    colors: [Color.blue.opacity(0.12), Color.indigo.opacity(0.05), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: proxy.size.height * 0.4)
                .ignoresSafeArea()
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    profileHeader
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                    
                    quickStats
                        .padding(.horizontal)
                    
                    menuSection
                        .padding(.horizontal)
                    
                    if !settledLoans.isEmpty {
                        settledLoansSection
                            .padding(.horizontal)
                    }
                    
                    signOutButton
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let env = env, let userID = session.currentUser?.id {
                do {
                    let loans = try await env.loans.fetchActiveLoans(borrowerID: userID)
                    self.settledLoans = loans.filter { $0.status == .settled }
                } catch {
                    print("Failed to fetch loans: \(error)")
                }
            }
        }
    }
    
    // MARK: - Refined Header
    var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 104, height: 104)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.15), Color.indigo.opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 94, height: 94)
                
                Text(session.currentUser?.fullName.prefix(1).uppercased() ?? "U")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.indigo)
            }
            
            VStack(spacing: 4) {
                Text(session.currentUser?.fullName ?? "User Name")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(session.currentUser?.email ?? "user@example.com")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Quick Stats (Clean Cards)
    var quickStats: some View {
        HStack(spacing: 16) {
            // Credit Score Card
            statCard(
                icon: "speedometer",
                iconColor: .indigo,
                title: "Credit Score",
                value: session.borrowerProfile?.creditScore.map(String.init) ?? "—"
            )
            
            // KYC Card
            let isVerified = session.borrowerProfile?.kycStatus == .verified
            statCard(
                icon: isVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                iconColor: isVerified ? .teal : .orange,
                title: "KYC Status",
                value: session.borrowerProfile?.kycStatus.rawValue.capitalized ?? "Pending"
            )
        }
    }
    
    private func statCard(icon: String, iconColor: Color, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Menu Section
    var menuSection: some View {
        VStack(spacing: 0) {
            menuRow(
                icon: "phone.fill",
                iconColor: .blue,
                title: "Phone Number",
                subtitle: session.currentUser?.phone ?? "—"
            )
            
            Divider().padding(.leading, 60)
            
            NavigationLink {
                KYCView().toolbar(.hidden, for: .tabBar)
            } label: {
                menuRow(
                    icon: "doc.text.viewfinder",
                    iconColor: .orange,
                    title: "Manage KYC Documents",
                    subtitle: "View or upload identity documents",
                    showChevron: true
                )
            }
            
            Divider().padding(.leading, 60)
            
            NavigationLink {
                BorrowerMessagingView().toolbar(.hidden,for: .tabBar)
            } label: {
                menuRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    iconColor: .teal,
                    title: "Help and Support",
                    subtitle: "Get support for your applications",
                    showChevron: true
                )
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    private func menuRow(icon: String, iconColor: Color, title: String, subtitle: String, showChevron: Bool = false) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
    
    // MARK: - Settled Loans Section
    var settledLoansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settled Loans")
                .font(.headline)
                .padding(.leading, 4)
            
            ForEach(settledLoans.prefix(1)) { loan in
                NavigationLink(destination: RepaymentDashboardView(loan: loan)) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(loan.loanType.rawValue.capitalized) Loan")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text(Formatting.currency(loan.principal))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("Settled")
                            .font(.caption).bold()
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.green.opacity(0.12))
                            .foregroundStyle(Color.green)
                            .clipShape(Capsule())
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if settledLoans.count > 1 {
                NavigationLink(destination: LoanHistoryListView(loans: settledLoans)) {
                    Text("See All \(settledLoans.count) Loans")
                        .font(.subheadline).bold()
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Sign Out Button
    var signOutButton: some View {
        Button(role: .destructive) {
            Task {
                try? await env?.auth.signOut()
                session.currentUser = nil
                session.borrowerProfile = nil
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .medium))
                Text("Sign Out")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color(.secondarySystemGroupedBackground))
            .foregroundStyle(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    NavigationStack {
        BorrowerProfileView()
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

// MARK: - Loan History List View
struct LoanHistoryListView: View {
    let loans: [Loan]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(loans) { loan in
                    NavigationLink(destination: RepaymentDashboardView(loan: loan)) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(loan.loanType.rawValue.capitalized) Loan")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                Text(Formatting.currency(loan.principal))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("Settled")
                                .font(.caption).bold()
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.green.opacity(0.12))
                                .foregroundStyle(Color.green)
                                .clipShape(Capsule())
                        }
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .navigationTitle("Loan History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
