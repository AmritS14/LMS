import SwiftUI

public struct ManagerDashboardView: View {
    // Custom Colors matching the design
    let navyBlue = Color(red: 0.05, green: 0.12, blue: 0.25)
    let successGreen = Color(red: 0.13, green: 0.77, blue: 0.36)
    let errorRed = Color(red: 0.93, green: 0.27, blue: 0.27)
    let warningOrange = Color(red: 0.96, green: 0.62, blue: 0.04)
    let bgLight = Color(red: 0.98, green: 0.98, blue: 0.99)
    let cardBorder = Color.gray.opacity(0.15)
    
    public var body: some View {
        NavigationStack {
            dashboardContent
        }
    }
    
    private var dashboardContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Dashboard")
                        .font(.headline)
                        .foregroundColor(navyBlue)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "bell")
                            .font(.title3)
                            .foregroundColor(navyBlue)
                    }
                    
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                        .padding(.leading, 8)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Approval Summary Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Approval Summary")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(navyBlue)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        summaryCard(icon: "doc.text.badge.clock", iconColor: navyBlue, title: "Pending Review", value: "23", valueColor: navyBlue)
                        summaryCard(icon: "checkmark.circle", iconColor: successGreen, title: "Approved Today", value: "13", valueColor: successGreen)
                        summaryCard(icon: "xmark.circle", iconColor: errorRed, title: "Rejected Today", value: "2", valueColor: errorRed)
                        summaryCard(icon: "arrow.uturn.backward.square", iconColor: warningOrange, title: "Sent Back", value: "5", valueColor: warningOrange)
                    }
                    .padding(.horizontal)
                }
                
                // Review Applications Button
                NavigationLink(destination: ManagerApplicationsView().navigationBarBackButtonHidden(true)) {
                    HStack {
                        Image(systemName: "list.bullet.rectangle.portrait")
                        Text("Review Applications")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(navyBlue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Approval Rate Card
                ZStack(alignment: .bottomTrailing) {
                    // Watermark icon
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white.opacity(0.05))
                        .offset(x: 10, y: 10)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Approval Rate")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("85%")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 4)
                                
                                Capsule()
                                    .fill(successGreen)
                                    .frame(width: geometry.size.width * 0.85, height: 4)
                            }
                        }
                        .frame(height: 4)
                        .padding(.top, 4)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(navyBlue)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Avg Decision Time Card
                ZStack(alignment: .trailing) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 100))
                        .foregroundColor(Color.gray.opacity(0.1))
                        .offset(x: 20, y: 0)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Avg. Decision Time")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("4.1h")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(navyBlue)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.caption2)
                            Text("14% faster than last week")
                                .font(.caption)
                        }
                        .foregroundColor(successGreen)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Recent Actions
                VStack(spacing: 12) {
                    HStack {
                        Text("Recent Actions")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(navyBlue)
                        
                        Spacer()
                        
                        Button("View All") { }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(navyBlue)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        recentActionRow(
                            title: "Approved • Sarah Jenkins • ₹4,50,000",
                            subtitle: "Just now • LN88461",
                            color: successGreen,
                            isHighlighted: true
                        )
                        
                        recentActionRow(
                            title: "Approved • Jonathan Aris • ₹2,10,000",
                            subtitle: "Today, 10:45 AM • LN88421",
                            color: successGreen,
                            isHighlighted: false
                        )
                        
                        recentActionRow(
                            title: "Rejected • LN88432 • ₹1,25,000",
                            subtitle: "Today, 09:12 AM",
                            color: errorRed,
                            isHighlighted: false
                        )
                        
                        recentActionRow(
                            title: "Returned • LN88456 • ₹5,00,000",
                            subtitle: "Yesterday, 4:30 PM",
                            color: warningOrange,
                            isHighlighted: false
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
                
            }
            .padding(.bottom, 20)
        }
        .background(bgLight.ignoresSafeArea())
    }
    
    private func summaryCard(icon: String, iconColor: Color, title: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(valueColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(cardBorder, lineWidth: 1)
        )
    }
    
    private func recentActionRow(title: String, subtitle: String, color: Color, isHighlighted: Bool) -> some View {
        HStack(spacing: 12) {
            // Colored strip
            Capsule()
                .fill(color)
                .frame(width: 4, height: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(navyBlue)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color.gray.opacity(0.5))
        }
        .padding()
        .background(isHighlighted ? color.opacity(0.05) : Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? color.opacity(0.1) : cardBorder, lineWidth: 1)
        )
    }
}

struct ManagerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ManagerDashboardView()
    }
}
