import Foundation

protocol MessagingService: Sendable {
    func threads(for userID: UUID) async throws -> [MessageThread]
    func messages(threadID: UUID) async throws -> [ChatMessage]
    func send(_ message: ChatMessage) async throws -> ChatMessage
    func markRead(threadID: UUID, upTo: Date) async throws

    /// Returns the existing conversation for an application, creating one (with
    /// the given participants) the first time. Idempotent — safe to call on
    /// every review open.
    func ensureThread(applicationID: UUID, participantIDs: [UUID]) async throws -> MessageThread
}
