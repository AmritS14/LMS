import SwiftUI

public enum ApplicationActionType {
    case approve, reject, sendBack
}

public struct SuccessStateView: View {
    var actionType: ApplicationActionType
    
    public init(actionType: ApplicationActionType = .approve) {
        self.actionType = actionType
    }
    
    var themeColor: Color {
        switch actionType {
        case .approve: return .lmsSuccess
        case .reject: return .lmsDanger
        case .sendBack: return .lmsWarning
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
            Spacer()
            
            VStack(spacing: Spacing.l) {
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
                VStack(spacing: Spacing.s) {
                    Text(titleText)
                        .font(.lmsTitle)
                        .foregroundColor(.primary)
                    
                    Text(subtitleText)
                        .font(.lmsSubheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
                
                // Actions
                VStack(spacing: Spacing.m) {
                    NavigationLink(destination: ManagerDashboardView().navigationBarBackButtonHidden(true)) {
                        Text("Back to Dashboard")
                            .font(.lmsHeadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.lmsNavyBlue)
                            .clipShape(Capsule())
                    }
                    
                    NavigationLink(destination: ManagerApplicationsView().navigationBarBackButtonHidden(true)) {
                        HStack {
                            Text("Review Next Application")
                            Image(systemName: "arrow.right")
                        }
                        .font(.lmsHeadline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, Spacing.m)
            }
            .padding(.bottom, Spacing.xl)
            
            Spacer()
            Spacer()
        }
        .background(Color.lmsSurface.ignoresSafeArea())
    }
}

struct SuccessStateView_Previews: PreviewProvider {
    static var previews: some View {
        SuccessStateView()
    }
}
