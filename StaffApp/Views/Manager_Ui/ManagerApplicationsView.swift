import SwiftUI

public struct ManagerApplicationsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    // For Navigation
    @State private var navigateToReview = false
    
    // Mock Data
    private let allApps: [MockApplication] = [
        MockApplication(name: "Sarah Jenkins", subtitle: "LN-90210 • Home Loan", amount: "₹45,000.00", officer: "Marcus Reed", recLabel: "HIGH REC", recTone: .success, status: "Pending"),
        MockApplication(name: "David Chen", subtitle: "LN-88432 • Personal Loan", amount: "₹12,500.00", officer: "Marcus Reed", recLabel: "MEDIUM REC", recTone: .warning, status: "Pending"),
        MockApplication(name: "Elena Rodriguez", subtitle: "LN-91104 • Auto Loan", amount: "₹32,000.00", officer: "Marcus Reed", recLabel: "HIGH REC", recTone: .success, status: "Approved"),
        MockApplication(name: "Robert Fox", subtitle: "LN-92205 • Auto Loan", amount: "₹15,000.00", officer: "Jane Doe", recLabel: "LOW REC", recTone: .danger, status: "Rejected"),
        MockApplication(name: "Michael Scott", subtitle: "LN-93306 • Home Loan", amount: "₹85,000.00", officer: "Jim Halpert", recLabel: "MEDIUM REC", recTone: .warning, status: "Sent Back")
    ]
    
    private var filteredApps: [MockApplication] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return allApps.filter { app in
            let matchesSearch = query.isEmpty ||
                app.name.localizedCaseInsensitiveContains(query) ||
                app.subtitle.localizedCaseInsensitiveContains(query) ||
                app.officer.localizedCaseInsensitiveContains(query)
            return matchesSearch
        }
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
                
                // Search and Filter
                HStack(spacing: Spacing.m) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search", text: $searchText)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
                    
                }
                .padding(.horizontal, Spacing.m)
                .padding(.bottom, Spacing.m)
                
                // Applications List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.m) {
                        if filteredApps.isEmpty {
                            VStack(spacing: Spacing.s) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No applications found")
                                    .font(.lmsHeadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(filteredApps) { app in
                                applicationCard(
                                    name: app.name,
                                    subtitle: app.subtitle,
                                    amount: app.amount,
                                    officer: app.officer,
                                    recLabel: app.recLabel,
                                    recTone: app.recTone
                                )
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.bottom, Spacing.xl)
                }
        }
        .background(Color.gray.opacity(0.05).ignoresSafeArea())
        .navigationTitle("Applications")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Empty override to hide parent icons
            }
        }
        .navigationDestination(isPresented: $navigateToReview) {
            ApplicationReviewView()
        }

    }
    
    private func applicationCard(name: String, subtitle: String, amount: String, officer: String, recLabel: String, recTone: StatusBadge.Tone) -> some View {
        VStack(spacing: Spacing.m) {
            // Top row
            HStack(alignment: .top, spacing: Spacing.m) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.lmsTitle2)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.lmsCaption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                StatusBadge(recLabel, tone: recTone)
            }
            
            Divider()
            
            // Middle row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Amount")
                        .font(.lmsCaption)
                        .foregroundColor(.gray)
                    Text(amount)
                        .font(.lmsSubheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Officer")
                        .font(.lmsCaption)
                        .foregroundColor(.gray)
                    Text(officer)
                        .font(.lmsSubheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            // Bottom row
            PrimaryButton("Review") {
                navigateToReview = true
            }
        }
        .padding(Spacing.m)
        .background(Color.white)
        .cornerRadius(CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
}

// Data Model
struct MockApplication: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let amount: String
    let officer: String
    let recLabel: String
    let recTone: StatusBadge.Tone
    let status: String
}

struct ManagerApplicationsView_Previews: PreviewProvider {
    static var previews: some View {
        ManagerApplicationsView()
            .environment(SessionStore())
    }
}
