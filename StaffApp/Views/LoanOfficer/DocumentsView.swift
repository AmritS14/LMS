import SwiftUI

// MARK: - Documents View

struct DocumentsView: View {
    
    @EnvironmentObject var viewModel: AppViewModel
    
    @State private var selectedDocument: DigitalDocument?
    @State private var showSignatureSheet = false
    @State private var selectedCategory = "All"
    
    private let categories = [
        "All",
        "Sanction Letters",
        "Reports",
        "Policies"
    ]
    
    private var filteredDocuments: [DigitalDocument] {
        
        if selectedCategory == "All" {
            return viewModel.digitalDocuments
        }
        
        return viewModel.digitalDocuments.filter { document in
            
            switch selectedCategory {
                
            case "Sanction Letters":
                return document.title.localizedCaseInsensitiveContains("sanction")
                
            case "Reports":
                return document.title.localizedCaseInsensitiveContains("report")
                
            case "Policies":
                return document.title.localizedCaseInsensitiveContains("policy")
                
            default:
                return true
            }
        }
    }
    
    var body: some View {
        
        ScrollView(.vertical, showsIndicators: false) {
            
            VStack(spacing: 16) {
                
                // Categories
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    HStack(spacing: 10) {
                        
                        ForEach(categories, id: \.self) { category in
                            
                            Button {
                                
                                selectedCategory = category
                                
                            } label: {
                                
                                Text(category)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(
                                        selectedCategory == category
                                        ? .white
                                        : .primary
                                    )
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(
                                                selectedCategory == category
                                                ? Color.blue
                                                : Color(.tertiarySystemGroupedBackground)
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Documents
                ForEach(filteredDocuments) { document in
                    
                    Button {
                        
                        selectedDocument = document
                        
                    } label: {
                        
                        documentCard(document)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedDocument) { document in
            
            //            DocumentPreviewSheet(
            //                document: document,
            //                showSignatureSheet: $showSignatureSheet
            //            )
            //            .environmentObject(viewModel)
            //        }
            //        .sheet(isPresented: $showSignatureSheet) {
            //
            //            SignatureSheet(
            //                showSignatureSheet: $showSignatureSheet
            //            )
        }
    }
        
        // MARK: Document Card
        
        private func documentCard(_ document: DigitalDocument) -> some View {
            
            HStack(spacing: 14) {
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: document.icon)
                            .font(.system(size: 22))
                            .foregroundStyle(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 5) {
                    
                    Text(document.title)
                        .font(.system(size: 15, weight: .semibold))
                    
                    HStack(spacing: 6) {
                        
                        Text(document.type)
                        Text("•")
                        Text(document.fileSize)
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    
                    Text(AppFormatters.formatDate(document.generatedDate))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    
                    if document.isSigned {
                        
                        Label("Signed", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.green)
                    }
                    
                    if document.borrowerAcknowledged {
                        
                        Label("Acknowledged", systemImage: "hand.thumbsup.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Preview
    
    #Preview {
        NavigationStack {
            DocumentsView()
                .environmentObject(AppViewModel())
        }
    }

