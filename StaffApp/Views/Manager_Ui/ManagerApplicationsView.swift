import SwiftUI

public struct ManagerApplicationsView: View {
    // Custom Colors matching the design
    let bgLight = Color(red: 0.96, green: 0.97, blue: 0.98)
    let primaryBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    let lightBlueBg = Color(red: 0.9, green: 0.95, blue: 1.0)
    let textDark = Color.black
    let textGray = Color.gray
    let searchBg = Color(red: 0.92, green: 0.93, blue: 0.94)
    let segmentBg = Color(red: 0.92, green: 0.93, blue: 0.94)
    
    // Status badges
    let highRecBg = Color(red: 0.9, green: 0.98, blue: 0.92)
    let highRecText = Color(red: 0.1, green: 0.6, blue: 0.2)
    let medRecBg = Color(red: 0.98, green: 0.95, blue: 0.85)
    let medRecText = Color(red: 0.8, green: 0.5, blue: 0.0)
    
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = "Pending"
    @State private var searchText = ""
    let tabs = ["Pending", "Approved", "Rejected", "Sent Back"]
    
    public init() {}
    
    public var body: some View {
        applicationsContent
    }
    
    private var applicationsContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(textDark)
                }
                .padding(.trailing, 8)
                
                Text("Applications")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(textDark)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bell")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(primaryBlue)
                        .frame(width: 36, height: 36)
                        .background(lightBlueBg)
                        .clipShape(Circle())
                }
                
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.gray)
                    .clipShape(Circle())
                    .padding(.leading, 8)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 16)
            
            // Custom Segmented Control
            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        Text(tab)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .medium)
                            .foregroundColor(selectedTab == tab ? textDark : textGray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedTab == tab ? Color.white : Color.clear)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(4)
            .background(segmentBg)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // Search and Filter
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search", text: $searchText)
                        .foregroundColor(textDark)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(searchBg)
                .cornerRadius(10)
                
                Button(action: {}) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20))
                        .foregroundColor(primaryBlue)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // Applications List
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    applicationCard(
                        name: "Sarah Jenkins",
                        subtitle: "LN-90210 • Home Loan",
                        amount: "₹45,000.00",
                        officer: "Marcus Reed",
                        recLabel: "HIGH REC",
                        recBg: highRecBg,
                        recColor: highRecText
                    )
                    
                    applicationCard(
                        name: "David Chen",
                        subtitle: "LN-88432 • Personal Loan",
                        amount: "₹12,500.00",
                        officer: "Marcus Reed",
                        recLabel: "MEDIUM REC",
                        recBg: medRecBg,
                        recColor: medRecText
                    )
                    
                    applicationCard(
                        name: "Elena Rodriguez",
                        subtitle: "LN-91104 • Auto Loan",
                        amount: "₹32,000.00",
                        officer: "Marcus Reed",
                        recLabel: "HIGH REC",
                        recBg: highRecBg,
                        recColor: highRecText
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(bgLight.ignoresSafeArea())
    }
    
    private func applicationCard(name: String, subtitle: String, amount: String, officer: String, recLabel: String, recBg: Color, recColor: Color) -> some View {
        VStack(spacing: 16) {
            // Top row
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(textDark)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(textGray)
                }
                
                Spacer()
                
                Text(recLabel)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(recColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(recBg)
                    .cornerRadius(4)
            }
            
            Divider()
            
            // Middle row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Amount")
                        .font(.caption)
                        .foregroundColor(textGray)
                    Text(amount)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(textDark)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Officer")
                        .font(.caption)
                        .foregroundColor(textGray)
                    Text(officer)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(textDark)
                }
                
                Spacer()
            }
            
            // Bottom row
            HStack(spacing: 12) {
                NavigationLink(destination: ApplicationReviewView().navigationBarBackButtonHidden(true)) {
                    Text("Review")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(primaryBlue)
                        .cornerRadius(8)
                        .shadow(color: primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundColor(primaryBlue)
                        .frame(width: 48, height: 48)
                        .background(searchBg)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct ManagerApplicationsView_Previews: PreviewProvider {
    static var previews: some View {
        ManagerApplicationsView()
    }
}
