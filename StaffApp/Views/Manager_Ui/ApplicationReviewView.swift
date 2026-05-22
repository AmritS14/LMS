import SwiftUI

public struct ApplicationReviewView: View {
    let navyBlue = Color.lmsNavyBlue
    let bgLight = Color.lmsSurface
    let cardBg = Color.lmsCardBackground
    let successGreen = Color.lmsSuccess
    
    @Environment(\.dismiss) var dismiss
    @State private var showingApprove = false
    @State private var showingReject = false
    @State private var showingSendBack = false
    @State private var showSuccess = false
    @State private var completedAction: ApplicationActionType = .approve
    @State private var navigateToProfile = false
    @State private var navigateToNotifications = false
    
    // Dynamic Document Verification State
    @State private var verifiedGovID = true
    @State private var verifiedTaxReturns = true
    @State private var verifiedCollateral = true
    
    var verifiedCount: Int {
        [verifiedGovID, verifiedTaxReturns, verifiedCollateral].filter { $0 }.count
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    
                    // Borrower Profile
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Borrower Profile")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "checkmark.shield")
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Jonathan Aris")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Lead Tech Architect")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ANNUAL INCOME")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                Text("₹1,85,000")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("EXPERIENCE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                Text("12 Years")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(cardBg)
                    .cornerRadius(12)
                    
                    // Loan Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Loan Configuration")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Requested Amount")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("₹1,20,000")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Loan Term")
                                .font(.caption)
                                .foregroundColor(.gray)
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(navyBlue)
                                Text("15 Years")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Primary Purpose")
                                .font(.caption)
                                .foregroundColor(.gray)
                            HStack {
                                Image(systemName: "briefcase")
                                    .foregroundColor(navyBlue)
                                Text("Business Expansion")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(cardBg)
                    .cornerRadius(12)
                    
                    // Verified Documents
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Verified Documents")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(verifiedCount) of 3 Verified")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(verifiedCount == 3 ? successGreen : .orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(verifiedCount == 3 ? successGreen.opacity(0.1) : Color.orange.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        documentRow(icon: "person.text.rectangle", title: "Government ID", isVerified: $verifiedGovID)
                        documentRow(icon: "doc.text", title: "Tax Returns (3 yrs)", isVerified: $verifiedTaxReturns)
                        documentRow(icon: "building.columns", title: "Collateral Proof", isVerified: $verifiedCollateral)
                    }
                    .padding()
                    .background(cardBg)
                    .cornerRadius(12)
                    
                    // Officer Evaluation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Officer Evaluation")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "quote.opening")
                                .font(.title)
                                .foregroundColor(navyBlue)
                            
                            Text("\"Strong collateral position with a debt-to-income ratio well below the risk threshold. Borrower has a stable 12-year employment history in the tech sector. Recommend immediate approval for the requested amount.\"")
                                .font(.subheadline)
                                .italic()
                                .foregroundColor(.black.opacity(0.8))
                        }
                    }
                    .padding()
                    .background(cardBg)
                    .cornerRadius(12)
                    
                }
                .padding()
            }
            .background(bgLight)
            
            // Bottom Action Bar
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: { showingReject = true }) {
                        HStack {
                            Image(systemName: "slash.circle")
                            Text("Reject")
                        }
                        .font(.headline)
                        .foregroundColor(Color.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    
                    Button(action: { showingSendBack = true }) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward.square")
                            Text("Send Back")
                        }
                        .font(.headline)
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.1))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
                
                Button(action: { showingApprove = true }) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Approve")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(navyBlue)
                    .clipShape(Capsule())
                }
            }
            .padding()
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: -5)
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle("Review Application")
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
                Button(action: { navigateToNotifications = true }) {
                    Image(systemName: "bell")
                        .foregroundColor(.primary)
                }
                Button(action: { navigateToProfile = true }) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToProfile) {
            StaffProfileView()
        }
        .navigationDestination(isPresented: $navigateToNotifications) {
            LONotificationsView()
        }
        .sheet(isPresented: $showingApprove) {
            ApproveModalView(onComplete: { 
                completedAction = .approve
                showSuccess = true 
            })
        }
        .sheet(isPresented: $showingReject) {
            RejectModalView(onComplete: { 
                completedAction = .reject
                showSuccess = true 
            })
        }
        .sheet(isPresented: $showingSendBack) {
            SendBackModalView(onComplete: { 
                completedAction = .sendBack
                showSuccess = true 
            })
        }
        .navigationDestination(isPresented: $showSuccess) {
            SuccessStateView(actionType: completedAction)
                .navigationBarBackButtonHidden(true)
        }
    }
    
    private func documentRow(icon: String, title: String, isVerified: Binding<Bool>) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isVerified.wrappedValue.toggle()
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(navyBlue)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.8))
                Spacer()
                Image(systemName: isVerified.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isVerified.wrappedValue ? successGreen : .gray.opacity(0.5))
                    .font(.system(size: 20))
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct ApplicationReviewView_Previews: PreviewProvider {
    static var previews: some View {
        ApplicationReviewView()
            .environment(SessionStore())
    }
}

#Preview {
    NavigationStack {
        ApplicationReviewView()
            .environment(SessionStore())
    }
}
