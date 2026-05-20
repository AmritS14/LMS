import SwiftUI

public enum ApplicationActionType {
    case approve, reject, sendBack
}

public struct SuccessStateView: View {
    let navyBlue = Color(red: 0.05, green: 0.12, blue: 0.25)
    let successGreen = Color(red: 0.13, green: 0.77, blue: 0.36)
    let errorRed = Color(red: 0.93, green: 0.27, blue: 0.27)
    let warningOrange = Color(red: 0.96, green: 0.62, blue: 0.04)
    let bgLight = Color(red: 0.96, green: 0.97, blue: 0.98)
    
    var actionType: ApplicationActionType
    
    public init(actionType: ApplicationActionType = .approve) {
        self.actionType = actionType
    }
    
    var themeColor: Color {
        switch actionType {
        case .approve: return successGreen
        case .reject: return errorRed
        case .sendBack: return warningOrange
        }
    }
    
    var iconName: String {
        switch actionType {
        case .approve: return "checkmark"
        case .reject: return "xmark"
        case .sendBack: return "arrow.uturn.backward"
        }
    }
    
    var titleText: String {
        switch actionType {
        case .approve: return "Application Approved"
        case .reject: return "Application Rejected"
        case .sendBack: return "Application Sent Back"
        }
    }
    
    var subtitleText: String {
        switch actionType {
        case .approve: return "Sarah Jenkins (LN-90210) has been notified. Dashboard metrics updated."
        case .reject: return "Sarah Jenkins (LN-90210) has been notified of the rejection."
        case .sendBack: return "Application returned to Marcus Reed for corrections."
        }
    }
    
    var updateTitle: String {
        switch actionType {
        case .approve: return "Institutional Update"
        case .reject: return "Action Recorded"
        case .sendBack: return "Officer Notified"
        }
    }
    
    var updateText: String {
        switch actionType {
        case .approve: return "Credit score impact has been logged and the automated underwriting pipeline is now processing the remaining documents."
        case .reject: return "The rejection reason has been logged for compliance and the file has been archived."
        case .sendBack: return "The loan officer has been alerted to provide the missing details and will re-submit."
        }
    }
    
    var updateIcon: String {
        switch actionType {
        case .approve: return "checkmark.shield.fill"
        case .reject: return "xmark.shield.fill"
        case .sendBack: return "clock.fill"
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.gray)
                
                Text("Dashboard")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(navyBlue)
                    .padding(.leading, 8)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bell")
                        .foregroundColor(navyBlue)
                }
            }
            .padding()
            .background(Color.white)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    Spacer().frame(height: 40)
                    
                    // Success Icon
                    ZStack {
                        Circle()
                            .fill(themeColor)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: iconName)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Text Details
                    VStack(spacing: 12) {
                        Text(titleText)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(navyBlue)
                        
                        Text(subtitleText)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Actions
                    VStack(spacing: 16) {
                        NavigationLink(destination: ManagerDashboardView().navigationBarBackButtonHidden(true)) {
                            Text("Back to Dashboard")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(navyBlue)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {}) {
                            HStack {
                                Text("Review Next Application")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .foregroundColor(navyBlue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    Spacer().frame(height: 20)
                    
                    // Institutional Update Card
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: updateIcon)
                            .font(.title2)
                            .foregroundColor(themeColor)
                            .padding(12)
                            .background(themeColor.opacity(0.15))
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(updateTitle)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(navyBlue)
                            
                            Text(updateText)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.02), radius: 5, y: 5)
                    
                }
                .padding(.bottom, 20)
            }
            
        }
        .background(bgLight.ignoresSafeArea())
    }
}

struct SuccessStateView_Previews: PreviewProvider {
    static var previews: some View {
        SuccessStateView()
    }
}
