import SwiftUI

public struct SendBackModalView: View {
    @Environment(\.dismiss) var dismiss
    
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
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.lmsHeadline)
                    .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding(Spacing.m)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Send Back")
                        .font(.lmsTitle)
                        .foregroundColor(.primary)
                    Text("Application")
                        .font(.lmsTitle)
                        .foregroundColor(.primary)
                }
                Spacer()
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, Spacing.m)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    
                    Text("Select reasons for returning this application to the loan officer.")
                        .font(.lmsSubheadline)
                        .foregroundColor(.primary)
                        .padding(.top, Spacing.s)
                    
                    // Reasons List
                    SectionCard {
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
                                            .font(.lmsSubheadline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Circle()
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1.5)
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                Circle()
                                                    .fill(selectedReasons.contains(reason) ? Color.lmsNavyBlue : Color.clear)
                                                    .frame(width: 12, height: 12)
                                            )
                                    }
                                    .padding(.vertical, Spacing.m)
                                }
                                if reason != reasons.last {
                                    Divider()
                                }
                            }
                        }
                    }
                    
                    // Assignee
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("Assign to Loan Officer")
                            .font(.lmsCaption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text(assignee)
                                .font(.lmsSubheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding(Spacing.m)
                        .background(Color.white)
                        .cornerRadius(CornerRadius.small)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Remarks
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("Additional Remarks")
                            .font(.lmsCaption)
                            .foregroundColor(.gray)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $remarks)
                                .frame(height: 100)
                                .padding(Spacing.s)
                                .background(Color.white)
                                .cornerRadius(CornerRadius.small)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.small)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            
                            if remarks.isEmpty {
                                Text("Provide specific details about the required changes...")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, Spacing.m)
                                    .padding(.vertical, Spacing.m)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    
                    // Submit Button
                    Button(action: { 
                        dismiss()
                        onComplete()
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Back to Officer")
                        }
                        .font(.lmsHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.lmsNavyBlue)
                        .clipShape(Capsule())
                    }
                    .padding(.top, Spacing.s)
                    
                }
                .padding(Spacing.m)
            }
            
        }
        .background(Color.lmsSurface.ignoresSafeArea())
    }
}

struct SendBackModalView_Previews: PreviewProvider {
    static var previews: some View {
        SendBackModalView()
    }
}
