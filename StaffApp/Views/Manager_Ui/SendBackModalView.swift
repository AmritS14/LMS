import SwiftUI

public struct SendBackModalView: View {
    @Environment(\.presentationMode) var presentationMode
    let navyBlue = Color(red: 0.05, green: 0.12, blue: 0.25)
    let bgLight = Color(red: 0.96, green: 0.97, blue: 0.98)
    
    @State private var selectedReasons: Set<String> = []
    @State private var assignee = "Marcus Reed"
    @State private var remarks = ""
    
    let reasons = [
        "Missing Documents",
        "Incorrect Data",
        "Verification Required",
        "Clarification Needed"
    ]
    
    var onComplete: () -> Void = {}
    
    public init(onComplete: @escaping () -> Void = {}) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline)
                    .foregroundColor(navyBlue)
                }
                Spacer()
            }
            .padding()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Send Back")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(navyBlue)
                    Text("Application")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(navyBlue)
                }
                Spacer()
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("Select reasons for returning this application to the loan officer.")
                        .font(.subheadline)
                        .foregroundColor(Color.black.opacity(0.7))
                        .padding(.top, 8)
                    
                    // Reasons List
                    VStack(spacing: 0) {
                        ForEach(reasons, id: \.self) { reason in
                            Button(action: {
                                if selectedReasons.contains(reason) {
                                    selectedReasons.remove(reason)
                                } else {
                                    selectedReasons.insert(reason)
                                }
                            }) {
                                HStack {
                                    Text(reason)
                                        .foregroundColor(Color.black.opacity(0.8))
                                    Spacer()
                                    Circle()
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1.5)
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Circle()
                                                .fill(selectedReasons.contains(reason) ? navyBlue : Color.clear)
                                                .frame(width: 12, height: 12)
                                        )
                                }
                                .padding(.vertical, 16)
                            }
                            if reason != reasons.last {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Assignee
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assign to Loan Officer")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text(assignee)
                                .foregroundColor(.black)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Remarks
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Remarks")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $remarks)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            
                            if remarks.isEmpty {
                                Text("Provide specific details about the required changes...")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    
                    // Submit Button
                    Button(action: { 
                        presentationMode.wrappedValue.dismiss()
                        onComplete()
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Back to Officer")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(navyBlue)
                        .cornerRadius(10)
                    }
                    .padding(.top, 10)
                    
                }
                .padding()
            }
            
        }
        .background(bgLight.ignoresSafeArea())
    }
}

struct SendBackModalView_Previews: PreviewProvider {
    static var previews: some View {
        SendBackModalView()
    }
}
