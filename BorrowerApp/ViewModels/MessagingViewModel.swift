import Foundation
import Observation

@MainActor
@Observable
final class MessagingViewModel {
    var threads: [MessageThread] = []
    var activeThreadMessages: [ChatMessage] = []
    var activeThread: MessageThread?
    var isLoading: Bool = false
    var isSending: Bool = false
    var errorMessage: String?
    var newMessageText: String = ""

    func fetchThreads(messagingService: any MessagingService, userID: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            self.threads = try await messagingService.threads(for: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func selectThread(_ thread: MessageThread, messagingService: any MessagingService) async {
        self.activeThread = thread
        isLoading = true
        errorMessage = nil
        do {
            self.activeThreadMessages = try await messagingService.messages(threadID: thread.id)
            try await messagingService.markRead(threadID: thread.id, upTo: Date())
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func sendMessage(messagingService: any MessagingService, senderID: UUID) async {
        guard let thread = activeThread, !newMessageText.isEmpty else { return }
        let text = newMessageText
        newMessageText = ""
        isSending = true
        
        let message = ChatMessage(
            threadID: thread.id,
            senderID: senderID,
            body: text,
            sentAt: Date()
        )
        
        do {
            let sentMessage = try await messagingService.send(message)
            activeThreadMessages.append(sentMessage)
        } catch {
            errorMessage = error.localizedDescription
            newMessageText = text // restore on failure
        }
        isSending = false
    }
}
