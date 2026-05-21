import SwiftUI

public struct ApproveModalView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var remarks = "Excellent credit profile, approved for full amount"
    @State private var notifyBorrower = true
    
    var onComplete: () -> Void = {}
    
    public init(onComplete: @escaping () -> Void = {}) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: Spacing.l) {
            // Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, Spacing.m)
            
            // Header
            VStack(spacing: Spacing.s) {
                Text("Approve Application")
                    .font(.lmsTitle)
                
                Text("Reviewing LN-90210 for Sarah Jenkins")
                    .font(.lmsSubheadline)
                    .foregroundColor(.gray)
            }
            
            // Remarks
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Remarks")
                    .font(.lmsSubheadline)
                    .foregroundColor(.primary)
                
                TextEditor(text: $remarks)
                    .frame(height: 100)
                    .padding(Spacing.s)
                    .background(Color.lmsSurface)
                    .cornerRadius(CornerRadius.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.small)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(.horizontal, Spacing.m)
            
            // Notify Borrower Toggle
            SectionCard {
                HStack {
                    Image(systemName: "bell")
                        .foregroundColor(.primary)
                    Text("Notify Borrower")
                        .font(.lmsHeadline)
                    Spacer()
                    Toggle("", isOn: $notifyBorrower)
                        .labelsHidden()
                        .tint(.lmsSuccess)
                }
            }
            .padding(.horizontal, Spacing.m)
            
            // Actions
            VStack(spacing: Spacing.m) {
                PrimaryButton("Confirm Approval") {
                    dismiss()
                    onComplete()
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.lmsSubheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.l)
            
            Spacer()
        }
        .background(Color.lmsSurface)
    }
}

struct ApproveModalView_Previews: PreviewProvider {
    static var previews: some View {
        ApproveModalView()
    }
}
