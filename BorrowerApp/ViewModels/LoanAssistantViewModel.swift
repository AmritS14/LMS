import Foundation

// MARK: - Model

struct AIChatMessage: Identifiable, Codable {
    var id: UUID = UUID()
    let role: String   // "user" | "model"
    let text: String
    let sentAt: Date

    init(role: String, text: String) {
        self.role = role
        self.text = text
        self.sentAt = .now
    }

    // Exclude `id` and `sentAt` from the payload sent to the backend
    enum CodingKeys: String, CodingKey {
        case role, text
    }

    // Custom decode so we preserve `id`/`sentAt` when loading from UserDefaults
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: PersistKeys.self)
        id     = (try? c.decode(UUID.self,   forKey: .id))    ?? UUID()
        role   = try c.decode(String.self,   forKey: .role)
        text   = try c.decode(String.self,   forKey: .text)
        sentAt = (try? c.decode(Date.self,   forKey: .sentAt)) ?? .now
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: PersistKeys.self)
        try c.encode(id,     forKey: .id)
        try c.encode(role,   forKey: .role)
        try c.encode(text,   forKey: .text)
        try c.encode(sentAt, forKey: .sentAt)
    }

    private enum PersistKeys: String, CodingKey {
        case id, role, text, sentAt
    }
}

// Payload types for the backend
private struct AIChatRequest: Encodable {
    let borrowerId: String
    let chatHistory: [AIChatMessagePayload]
}

private struct AIChatMessagePayload: Codable {
    let role: String
    let text: String
}

// MARK: - ViewModel

private let backendURL = "https://arshitsinghal-lms-backend-new.hf.space/ai/chat"

@MainActor
class LoanAssistantViewModel: ObservableObject {
    @Published var chatHistory: [AIChatMessage] = []
    @Published var isLoading = false
    @Published var inputText = ""

    private let borrowerId: String
    private let persistenceKey: String

    init(borrowerId: String) {
        self.borrowerId = borrowerId
        self.persistenceKey = "ai_chat_history_\(borrowerId)"
        loadHistory()
    }

    func sendMessage() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = AIChatMessage(role: "user", text: trimmed)
        chatHistory.append(userMessage)
        inputText = ""
        isLoading = true
        defer { isLoading = false }

        // Build payload — send only role + text to backend
        let payload = AIChatRequest(
            borrowerId: borrowerId,
            chatHistory: chatHistory.map { AIChatMessagePayload(role: $0.role, text: $0.text) }
        )

        guard let url = URL(string: backendURL) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(payload)
        request.timeoutInterval = 60

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 201 || http.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            // Backend returns { role, text } — decode into AIChatMessage
            let decoded = try JSONDecoder().decode(AIChatMessagePayload.self, from: data)
            chatHistory.append(AIChatMessage(role: decoded.role, text: decoded.text))
        } catch {
            chatHistory.append(AIChatMessage(
                role: "model",
                text: "I'm having trouble connecting right now. Please try again in a moment."
            ))
        }

        saveHistory()
    }

    func clearHistory() {
        chatHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: persistenceKey)
    }

    // MARK: - Persistence

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(chatHistory) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }

    private func loadHistory() {
        guard
            let data = UserDefaults.standard.data(forKey: persistenceKey),
            let saved = try? JSONDecoder().decode([AIChatMessage].self, from: data)
        else { return }
        chatHistory = saved
    }
}
