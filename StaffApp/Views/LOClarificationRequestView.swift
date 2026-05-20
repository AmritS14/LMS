import SwiftUI

struct LOClarificationRequestView: View {
    @Environment(\.dismiss) var dismiss
    @State private var remarks = ""
    
    let flaggedItems = [
        "Income Statement - Needs clearer scan",
        "Identity Proof - Missing signature page"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    
                    // Borrower Context
                    HStack {
                        VStack(alignment: .leading) {
                            Text("To: Jane Doe")
                                .font(.lmsHeadline)
                            Text("App ID: #APP-991")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.lmsNavyBlue.opacity(0.05))
                    .cornerRadius(8)
                    
                    // Read-only Checklist
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("Flagged Items")
                            .font(.lmsHeadline)
                        
                        ForEach(flaggedItems, id: \.self) { item in
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.lmsWarning)
                                Text(item)
                                    .font(.lmsBody)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.secondary.opacity(0.2))
                    )
                    
                    // Text Editor
                    VStack(alignment: .leading) {
                        Text("Personal Remarks")
                            .font(.lmsHeadline)
                        TextEditor(text: $remarks)
                            .frame(minHeight: 120)
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.secondary.opacity(0.3))
                            )
                    }
                    
                    Spacer(minLength: 40)
                    
                    PrimaryButton("Send Request to Borrower") {
                        dismiss()
                    }
                }
                .padding()
            }
            .navigationTitle("Request Clarification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
