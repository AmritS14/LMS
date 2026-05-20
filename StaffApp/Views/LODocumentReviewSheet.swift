import SwiftUI

struct LODocumentReviewSheet: View {
    let documentName: String
    @Environment(\.dismiss) var dismiss
    @State private var isFlagged = false
    @State private var resolutionNotes = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.m) {
                // Mock Document Viewer
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                    
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Document Preview: \(documentName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxHeight: 250)
                
                VStack(spacing: Spacing.s) {
                    Toggle("Flag as Irregular", isOn: $isFlagged.animation())
                        .tint(.lmsWarning)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isFlagged ? Color.lmsWarning.opacity(0.1) : Color.lmsSurface)
                        )
                    
                    if isFlagged {
                        VStack(alignment: .leading) {
                            Text("Resolution Notes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $resolutionNotes)
                                .frame(height: 100)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.secondary.opacity(0.3))
                                )
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                
                Spacer()
                
                PrimaryButton("Save Review") {
                    dismiss()
                }
            }
            .padding()
            .navigationTitle("Review Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
