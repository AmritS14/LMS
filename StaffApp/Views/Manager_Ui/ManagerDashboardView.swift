import SwiftUI

public struct ManagerDashboardView: View {
    @State private var navigateToApps = false
    @State private var navigateToReview = false
    @State private var navigateToProfile = false
    @State private var navigateToNotifications = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            dashboardContent
                .navigationDestination(isPresented: $navigateToApps) {
                    ManagerApplicationsView()
                }
                .navigationDestination(isPresented: $navigateToReview) {
                    ApplicationReviewView()
                }
                .navigationDestination(isPresented: $navigateToProfile) {
                    StaffProfileView()
                }
                .navigationDestination(isPresented: $navigateToNotifications) {
                    LONotificationsView()
                }
        }
    }
    
    private var dashboardContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.l) {
                // Header
                HStack {
                    Text("Dashboard")
                        .font(.lmsTitle)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: { navigateToNotifications = true }) {
                        Image(systemName: "bell")
                            .font(.lmsHeadline)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: { navigateToProfile = true }) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                            .clipShape(Circle())
                    }
                    .padding(.leading, Spacing.s)
                }
                .padding(.horizontal, Spacing.m)
                .padding(.top, Spacing.s)
                
                // Approval Summary Section
                SectionCard(title: "Approval Summary") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.m) {
                        summaryCard(icon: "clock", iconColor: .lmsNavyBlue, title: "Pending Review", value: "23", valueColor: .primary) { navigateToApps = true }
                        summaryCard(icon: "checkmark.circle", iconColor: .lmsSuccess, title: "Approved Today", value: "13", valueColor: .lmsSuccess) { navigateToApps = true }
                        summaryCard(icon: "xmark.circle", iconColor: .lmsDanger, title: "Rejected Today", value: "2", valueColor: .lmsDanger) { navigateToApps = true }
                        summaryCard(icon: "arrow.uturn.backward.square", iconColor: .lmsWarning, title: "Sent Back", value: "5", valueColor: .lmsWarning) { navigateToApps = true }
                    }
                }
                .padding(.horizontal, Spacing.m)
                
                // Review Applications Button
                PrimaryButton("Review Applications") {
                    navigateToApps = true
                }
                .padding(.horizontal, Spacing.m)
                
                // Analytics Preview Section
                SectionCard(title: "Branch Analytics") {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("Approval Rate")
                            .font(.lmsSubheadline)
                            .foregroundColor(.gray)
                        
                        HStack(alignment: .bottom) {
                            Text("84%")
                                .font(.lmsTitle)
                                .foregroundColor(.primary)
                            Text("+2.5% this week")
                                .font(.lmsCaption)
                                .foregroundColor(.lmsSuccess)
                                .padding(.bottom, Spacing.xs)
                        }
                        
                        // Progress bar mock
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                
                                Capsule()
                                    .fill(Color.lmsNavyBlue)
                                    .frame(width: geometry.size.width * 0.84, height: 8)
                            }
                        }
                        .frame(height: 8)
                        .padding(.top, Spacing.xs)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Avg. Decision Time")
                                .font(.lmsSubheadline)
                                .foregroundColor(.gray)
                                .padding(.top, Spacing.m)
                            
                            Text("4.1h")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 10, weight: .bold))
                                Text("14% faster than last week")
                                    .font(.lmsCaption)
                            }
                            .foregroundColor(.lmsSuccess)
                        }
                    }
                }
                .padding(.horizontal, Spacing.m)
                
                // Recent Actions Section
                SectionCard(title: "Recent Actions") {
                    VStack(spacing: Spacing.s) {
                        recentActionRow(
                            title: "Approved • Sarah Jenkins • ₹4,50,000",
                            subtitle: "Just now • LN88461",
                            color: .lmsSuccess,
                            isHighlighted: true
                        ) { navigateToReview = true }
                        recentActionRow(
                            title: "Approved • Jonathan Aris • ₹2,10,000",
                            subtitle: "Today, 10:45 AM • LN88421",
                            color: .lmsSuccess,
                            isHighlighted: false
                        ) { navigateToReview = true }
                        recentActionRow(
                            title: "Rejected • LN88432 • ₹1,25,000",
                            subtitle: "Today, 09:12 AM",
                            color: .lmsDanger,
                            isHighlighted: false
                        ) { navigateToReview = true }
                        recentActionRow(
                            title: "Returned • LN88456 • ₹5,00,000",
                            subtitle: "Yesterday, 4:30 PM",
                            color: .lmsWarning,
                            isHighlighted: false
                        ) { navigateToReview = true }
                    }
                }
                .padding(.horizontal, Spacing.m)
                
                Spacer().frame(height: Spacing.xl)
            }
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.lmsSurface.ignoresSafeArea())
    }
    
    private func summaryCard(icon: String, iconColor: Color, title: String, value: String, valueColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Image(systemName: icon)
                    .font(.lmsTitle2)
                    .foregroundColor(iconColor)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.lmsCaption)
                        .foregroundColor(.gray)
                    
                    Text(value)
                        .font(.lmsTitle2)
                        .foregroundColor(valueColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.m)
            .background(Color.white)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func recentActionRow(title: String, subtitle: String, color: Color, isHighlighted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                Capsule()
                    .fill(color)
                    .frame(width: 4, height: 36)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.lmsSubheadline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.lmsCaption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.lmsCaption)
                    .foregroundColor(Color.gray.opacity(0.5))
            }
            .padding(Spacing.m)
            .background(isHighlighted ? color.opacity(0.05) : Color.white)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(isHighlighted ? color.opacity(0.1) : Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ManagerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ManagerDashboardView()
            .environment(SessionStore())
    }
}
