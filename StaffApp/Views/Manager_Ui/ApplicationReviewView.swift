import SwiftUI

public struct ApplicationReviewView: View {
    let navyBlue = Color(red: 0.05, green: 0.12, blue: 0.25)
    let bgLight = Color(red: 0.96, green: 0.97, blue: 0.98)
    let cardBg = Color.white
    let successGreen = Color(red: 0.13, green: 0.77, blue: 0.36)
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showingApprove = false
    @State private var showingReject = false
    @State private var showingSendBack = false
    @State private var showSuccess = false
    @State private var completedAction: ApplicationActionType = .approve
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(navyBlue)
                        .font(.system(size: 18, weight: .medium))
                }
                
                Text("Review Application")
                    .font(.headline)
                    .foregroundColor(navyBlue)
                    .padding(.leading, 8)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bell")
                        .foregroundColor(navyBlue)
                }
                
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
            }
            .padding()
            .background(Color.white)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    
                    // Borrower Profile
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Borrower Profile")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(navyBlue)
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
                                    .foregroundColor(navyBlue)
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
                                    .foregroundColor(navyBlue)
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
                            .foregroundColor(navyBlue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Requested Amount")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("₹1,20,000")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(navyBlue)
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
                                    .foregroundColor(navyBlue)
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
                                    .foregroundColor(navyBlue)
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
                                .foregroundColor(navyBlue)
                            
                            Spacer()
                            
                            Text("3 of 3 Verified")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(successGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(successGreen.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        documentRow(icon: "person.text.rectangle", title: "Government ID")
                        documentRow(icon: "doc.text", title: "Tax Returns (3 yrs)")
                        documentRow(icon: "building.columns", title: "Collateral Proof")
                    }
                    .padding()
                    .background(cardBg)
                    .cornerRadius(12)
                    
                    // Officer Evaluation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Officer Evaluation")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(navyBlue)
                        
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
                        .cornerRadius(10)
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
                        .cornerRadius(10)
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
                    .cornerRadius(10)
                }
            }
            .padding()
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: -5)
        }
        .edgesIgnoringSafeArea(.bottom)
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
    
    private func documentRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(navyBlue)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.8))
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(successGreen)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct ApplicationReviewView_Previews: PreviewProvider {
    static var previews: some View {
        ApplicationReviewView()
    }
}

#Preview {
    ApplicationReviewView()
}
