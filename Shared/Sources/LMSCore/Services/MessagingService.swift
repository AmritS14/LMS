import Foundation

public protocol MessagingService: Sendable {
    func threads(for userID: UUID) async throws -> [MessageThread]
    func messages(threadID: UUID) async throws -> [ChatMessage]
    func send(_ message: ChatMessage) async throws -> ChatMessage
    func markRead(threadID: UUID, upTo: Date) async throws
}
