import SwiftUI

struct LoanAssistantView: View {
    @StateObject private var viewModel = LoanAssistantViewModel()
    let borrowerId: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.chatHistory) { message in
                            HStack {
                                if message.role == "user" { Spacer() }
                                Text(message.text)
                                    .padding()
                                    .background(message.role == "user" ? Color.blue : Color(UIColor.secondarySystemBackground))
                                    .foregroundColor(message.role == "user" ? .white : .primary)
                                    .cornerRadius(10)
                                if message.role == "model" { Spacer() }
                            }.padding(.horizontal)
                        }
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .accessibilityLabel("AI is typing")
                                Spacer()
                            }.padding()
                        }
                    }
                }
                
                HStack {
                    TextField("Ask about loans...", text: $viewModel.inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Send") {
                        Task {
                            await viewModel.sendMessage(borrowerId: borrowerId)
                        }
                    }.disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
                }.padding()
            }
            .navigationTitle("AI Assistant")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
