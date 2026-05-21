import SwiftUI

public struct RejectModalView: View {
    @Environment(\.dismiss) var dismiss
    
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
                    .font(.lmsTitle)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.lmsHeadline)
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(Color.lmsNavyBlue.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(Spacing.m)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.l) {
                    
                    // Profile Header
                    SectionCard {
                        HStack(spacing: Spacing.s) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(CornerRadius.small)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Marcus Thorne")
                                    .font(.lmsHeadline)
                                    .foregroundColor(.primary)
                                Text("Loan App #4920-BT • $45,000.00")
                                    .font(.lmsCaption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                    }
                    
                    // Reasons
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("SELECT PRIMARY REASON")
                            .font(.lmsCaption)
                            .foregroundColor(.gray)
                        
                        VStack(spacing: Spacing.s) {
                            ForEach(reasons, id: \.0) { reason, icon in
                                Button(action: { selectedReason = reason }) {
                                    HStack {
                                        Image(systemName: icon)
                                            .foregroundColor(.primary)
                                            .frame(width: 24)
                                        Text(reason)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        
                                        if selectedReason == reason {
                                            ZStack {
                                                Circle().stroke(Color.lmsNavyBlue, lineWidth: 2).frame(width: 20, height: 20)
                                                Circle().fill(Color.lmsNavyBlue).frame(width: 10, height: 10)
                                            }
                                        } else {
                                            Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2).frame(width: 20, height: 20)
                                        }
                                    }
                                    .padding(Spacing.m)
                                    .background(selectedReason == reason ? Color.white : Color.gray.opacity(0.05))
                                    .cornerRadius(CornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                                            .stroke(selectedReason == reason ? Color.lmsNavyBlue : Color.clear, lineWidth: selectedReason == reason ? 1.5 : 0)
                                    )
                                }
                            }
                        }
                    }
                    
                    // Remarks
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        HStack {
                            Text("REASONING & REMARKS")
                                .font(.lmsCaption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Optional")
                                .font(.lmsCaption)
                                .foregroundColor(.gray)
                        }
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $remarks)
                                .frame(height: 100)
                                .padding(Spacing.s)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(CornerRadius.small)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.small)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            
                            if remarks.isEmpty {
                                Text("Provide detailed context for this rejection...")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, Spacing.m)
                                    .padding(.vertical, Spacing.m)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    
                }
                .padding(.horizontal, Spacing.m)
            }
            
            // Bottom Buttons
            VStack(spacing: Spacing.s) {
                Button(action: { 
                    dismiss()
                    onComplete() 
                }) {
                    Text("Reject Application")
                        .font(.lmsHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.lmsDanger)
                        .clipShape(Capsule())
                }
                
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.lmsHeadline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(Spacing.m)
            .background(Color.lmsSurface)
        }
        .background(Color.lmsSurface)
    }
}

struct RejectModalView_Previews: PreviewProvider {
    static var previews: some View {
        RejectModalView()
    }
}
