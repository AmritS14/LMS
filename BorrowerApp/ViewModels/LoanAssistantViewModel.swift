import Foundation

struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    let role: String
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case role, text
    }
}

struct ChatRequest: Codable {
    let borrowerId: String
    let chatHistory: [ChatMessage]
}

@MainActor
class LoanAssistantViewModel: ObservableObject {
    @Published var chatHistory: [ChatMessage] = []
    @Published var isLoading = false
    @Published var inputText = ""
    
    func sendMessage(borrowerId: String) async {
        let userMessage = ChatMessage(role: "user", text: inputText)
        chatHistory.append(userMessage)
        inputText = ""
        isLoading = true
        
        defer { isLoading = false }
        
        let payload = ChatRequest(borrowerId: borrowerId, chatHistory: chatHistory)
        
        guard let url = URL(string: "http://localhost:3000/ai/chat") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(payload)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let aiMessage = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                chatHistory.append(aiMessage)
            } else {
                throw URLError(.cannotDecodeRawData)
            }
        } catch {
            chatHistory.append(ChatMessage(role: "model", text: "Unable to reach the assistant right now. Please try again."))
        }
    }
}
