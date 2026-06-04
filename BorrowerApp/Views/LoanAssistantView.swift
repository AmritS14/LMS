import SwiftUI

struct LoanAssistantView: View {
    @StateObject private var viewModel = LoanAssistantViewModel()
    let borrowerId: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    ForEach(viewModel.chatHistory) { message in
                        HStack {
                            if message.role == "user" { Spacer() }
                            Text(message.text)
                                .padding()
                                .background(message.role == "user" ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(message.role == "user" ? .white : .black)
                                .cornerRadius(10)
                            if message.role == "model" { Spacer() }
                        }.padding(.horizontal)
                    }
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                            Spacer()
                        }.padding()
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
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
