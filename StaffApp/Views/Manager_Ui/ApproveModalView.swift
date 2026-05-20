import SwiftUI

public struct ApproveModalView: View {
    @Environment(\.presentationMode) var presentationMode
    let navyBlue = Color(red: 0.0, green: 0.2, blue: 0.4)
    let successGreen = Color(red: 0.0, green: 0.5, blue: 0.2)
    
    @State private var remarks = "Excellent credit profile, approved for full amount"
    @State private var notifyBorrower = true
    
    var onComplete: () -> Void = {}
    
    public init(onComplete: @escaping () -> Void = {}) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 16)
            
            // Header
            VStack(spacing: 8) {
                Text("Approve Application")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Reviewing LN-90210 for Sarah Jenkins")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Remarks
            VStack(alignment: .leading, spacing: 8) {
                Text("Remarks")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.black.opacity(0.8))
                
                TextEditor(text: $remarks)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(.horizontal)
            
            // Notify Borrower Toggle
            HStack {
                Image(systemName: "bell")
                    .foregroundColor(navyBlue)
                Text("Notify Borrower")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $notifyBorrower)
                    .labelsHidden()
                    .tint(successGreen)
            }
            .padding()
            .background(Color(red: 0.98, green: 0.98, blue: 0.99))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Actions
            VStack(spacing: 16) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                    onComplete()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Confirm Approval")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(navyBlue)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            
            Spacer()
        }
        .background(Color.white)
    }
}

struct ApproveModalView_Previews: PreviewProvider {
    static var previews: some View {
        ApproveModalView()
    }
}
