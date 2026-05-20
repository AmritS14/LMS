import SwiftUI

public struct RejectModalView: View {
    @Environment(\.presentationMode) var presentationMode
    let navyBlue = Color(red: 0.05, green: 0.12, blue: 0.25)
    let redColor = Color(red: 0.75, green: 0.1, blue: 0.1)
    
    @State private var selectedReason = "Documentation"
    @State private var remarks = ""
    
    let reasons = [
        ("Credit Risk", "creditcard"),
        ("Income Risk", "banknote"),
        ("Documentation", "doc.text"),
        ("Other", "ellipsis")
    ]
    
    var onComplete: () -> Void = {}
    
    public init(onComplete: @escaping () -> Void = {}) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Text("Reject Application")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(navyBlue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // Profile Header
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .foregroundColor(navyBlue)
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Marcus Thorne")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(navyBlue)
                            Text("Loan App #4920-BT • $45,000.00")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Reasons
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SELECT PRIMARY REASON")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 8) {
                            ForEach(reasons, id: \.0) { reason, icon in
                                Button(action: { selectedReason = reason }) {
                                    HStack {
                                        Image(systemName: icon)
                                            .foregroundColor(navyBlue)
                                            .frame(width: 24)
                                        Text(reason)
                                            .foregroundColor(.black)
                                        Spacer()
                                        
                                        if selectedReason == reason {
                                            ZStack {
                                                Circle().stroke(navyBlue, lineWidth: 2).frame(width: 20, height: 20)
                                                Circle().fill(navyBlue).frame(width: 10, height: 10)
                                            }
                                        } else {
                                            Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2).frame(width: 20, height: 20)
                                        }
                                    }
                                    .padding()
                                    .background(selectedReason == reason ? Color.white : Color(red: 0.95, green: 0.96, blue: 0.98))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedReason == reason ? navyBlue : Color.clear, lineWidth: selectedReason == reason ? 1.5 : 0)
                                    )
                                }
                            }
                        }
                    }
                    
                    // Remarks
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("REASONING & REMARKS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Optional")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        TextEditor(text: $remarks)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(red: 0.98, green: 0.98, blue: 0.99))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        
                        if remarks.isEmpty {
                            Text("Provide detailed context for this rejection...")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 12)
                                .padding(.top, -90)
                                .allowsHitTesting(false)
                        }
                    }
                    
                }
                .padding(.horizontal)
            }
            
            // Bottom Buttons
            VStack(spacing: 12) {
                Button(action: { 
                    presentationMode.wrappedValue.dismiss()
                    onComplete() 
                }) {
                    Text("Reject Application")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(redColor)
                        .cornerRadius(10)
                }
                
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(navyBlue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.95, green: 0.96, blue: 0.98))
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color.white)
        }
        .background(Color.white)
    }
}

struct RejectModalView_Previews: PreviewProvider {
    static var previews: some View {
        RejectModalView()
    }
}
