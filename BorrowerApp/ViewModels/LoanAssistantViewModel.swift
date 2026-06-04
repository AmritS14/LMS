import Foundation

struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    let role: String
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case role, text
    }
}

class LoanAssistantViewModel: ObservableObject {
    @Published var chatHistory: [ChatMessage] = []
    @Published var isLoading = false
    @Published var inputText = ""
    
    func sendMessage(borrowerId: String) {
        let userMessage = ChatMessage(role: "user", text: inputText)
        chatHistory.append(userMessage)
        inputText = ""
        isLoading = true
        
        let payload: [String: Any] = [
            "borrowerId": borrowerId,
            "chatHistory": chatHistory.map { ["role": $0.role, "text": $0.text] }
        ]
        
        guard let url = URL(string: "http://localhost:3000/ai/chat") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data, let aiMessage = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                    self.chatHistory.append(aiMessage)
                } else {
                    self.chatHistory.append(ChatMessage(role: "model", text: "Unable to reach the assistant right now. Please try again."))
                }
            }
        }.resume()
    }
}
