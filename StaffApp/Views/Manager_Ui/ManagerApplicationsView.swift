import SwiftUI

public struct ManagerApplicationsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    
    // For Navigation
    @State private var navigateToReview = false
    
    // Mock Data matching the dashboard's Recent Actions (Approved, Rejected, and Returned)
    private let allApps: [MockApplication] = [
        MockApplication(name: "Sarah Jenkins", subtitle: "LN-90210 • Home Loan", amount: "₹4,50,000", officer: "Marcus Reed", status: "Approved", time: "Just now", color: Color.lmsSuccess, symbol: "checkmark.circle.fill"),
        MockApplication(name: "Jonathan Aris", subtitle: "LN-91104 • Auto Loan", amount: "₹2,10,000", officer: "Marcus Reed", status: "Approved", time: "10:45 AM", color: Color.lmsSuccess, symbol: "checkmark.circle.fill"),
        MockApplication(name: "LN88432", subtitle: "LN-88432 • Personal Loan", amount: "₹1,25,000", officer: "Marcus Reed", status: "Rejected", time: "09:12 AM", color: Color.lmsDanger, symbol: "xmark.circle.fill"),
        MockApplication(name: "LN88456", subtitle: "LN-88456 • Home Loan", amount: "₹5,00,000", officer: "Jim Halpert", status: "Returned", time: "Yesterday", color: Color.lmsWarning, symbol: "arrow.uturn.backward.circle.fill")
    ]
    
    private var filteredApps: [MockApplication] {
        allApps.filter { app in
            let matchesFilter = selectedFilter == "All" || app.status.lowercased() == selectedFilter.lowercased()
            
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty ||
                app.name.localizedCaseInsensitiveContains(query) ||
                app.subtitle.localizedCaseInsensitiveContains(query) ||
                app.officer.localizedCaseInsensitiveContains(query) ||
                app.status.localizedCaseInsensitiveContains(query)
                
            return matchesFilter && matchesSearch
        }
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            
            // Native Segmented Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                Text("All").tag("All")
                Text("Approved").tag("Approved")
                Text("Rejected").tag("Rejected")
                Text("Returned").tag("Returned")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
            
            // Search Bar
            HStack(spacing: Spacing.m) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search applications...", text: $searchText)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.s)
            
            // Native List layout showing all recent actions
            List {
                if filteredApps.isEmpty {
                    VStack(spacing: Spacing.s) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No applications found")
                            .font(.lmsHeadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .padding(.top, 40)
                } else {
                    ForEach(filteredApps) { app in
                        Button(action: {
                            navigateToReview = true
                        }) {
                            HStack(spacing: Spacing.m) {
                                Image(systemName: app.symbol)
                                    .font(.title3)
                                    .foregroundColor(app.color)
                                    .frame(width: 32, height: 32)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(app.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text(app.amount)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    HStack {
                                        Text(app.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(app.time)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary.opacity(0.4))
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(Color.lmsSurface.ignoresSafeArea())
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
        }
        .navigationDestination(isPresented: $navigateToReview) {
            ApplicationReviewView()
        }
    }
}

// Data Model
struct MockApplication: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let amount: String
    let officer: String
    let status: String // "Approved", "Rejected", "Returned"
    let time: String
    let color: Color
    let symbol: String
}

struct ManagerApplicationsView_Previews: PreviewProvider {
    static var previews: some View {
        ManagerApplicationsView()
            .environment(SessionStore())
    }
}
