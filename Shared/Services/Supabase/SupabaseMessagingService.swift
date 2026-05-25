import Foundation
import Supabase

actor SupabaseMessagingService: MessagingService {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    // DB Models
    private struct DBMessageThread: Decodable {
        let id: UUID
        let participant_ids: [UUID]
        let application_id: UUID?
        let last_message_preview: String?
        let updated_at: Date
    }
    
    private struct DBChatMessage: Decodable {
        let id: UUID
        let thread_id: UUID
        let sender_id: UUID
        let body: String
        let sent_at: Date
        let read_at: Date?
    }
    
    // Mappers
    private func toDomainThread(_ dbThread: DBMessageThread) -> MessageThread {
        MessageThread(
            id: dbThread.id,
            participantIDs: dbThread.participant_ids,
            applicationID: dbThread.application_id,
            lastMessagePreview: dbThread.last_message_preview,
            updatedAt: dbThread.updated_at
        )
    }
    
    private func toDomainMessage(_ dbMessage: DBChatMessage) -> ChatMessage {
        ChatMessage(
            id: dbMessage.id,
            threadID: dbMessage.thread_id,
            senderID: dbMessage.sender_id,
            body: dbMessage.body,
            sentAt: dbMessage.sent_at,
            readAt: dbMessage.read_at
        )
    }
    
    func threads(for userID: UUID) async throws -> [MessageThread] {
        // Fetch threads where user is a participant
        let response = try await client
            .from("message_threads")
            .select()
            .contains("participant_ids", value: [userID])
            .order("updated_at", ascending: false)
            .execute()
            
        let dbThreads = try SupabaseManager.shared.decoder.decode([DBMessageThread].self, from: response.data)
        return dbThreads.map(toDomainThread)
    }
    
    func messages(threadID: UUID) async throws -> [ChatMessage] {
        let response = try await client
            .from("chat_messages")
            .select()
            .eq("thread_id", value: threadID)
            .order("sent_at", ascending: true)
            .execute()
            
        let dbMessages = try SupabaseManager.shared.decoder.decode([DBChatMessage].self, from: response.data)
        return dbMessages.map(toDomainMessage)
    }
    
    func send(_ message: ChatMessage) async throws -> ChatMessage {
        let insertData: [String: AnyJSON] = [
            "thread_id": .string(message.threadID.uuidString),
            "sender_id": .string(message.senderID.uuidString),
            "body": .string(message.body)
        ]
        
        let response = try await client
            .from("chat_messages")
            .insert(insertData)
            .select()
            .single()
            .execute()
            
        let dbMessage = try SupabaseManager.shared.decoder.decode(DBChatMessage.self, from: response.data)
        
        // Also update thread's last_message_preview
        let updateData: [String: AnyJSON] = [
            "last_message_preview": .string(message.body),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        _ = try? await client
            .from("message_threads")
            .update(updateData)
            .eq("id", value: message.threadID)
            .execute()
            
        return toDomainMessage(dbMessage)
    }
    
    func markRead(threadID: UUID, upTo: Date) async throws {
        let updateData: [String: AnyJSON] = [
            "read_at": .string(ISO8601DateFormatter().string(from: upTo))
        ]
        
        _ = try await client
            .from("chat_messages")
            .update(updateData)
            .eq("thread_id", value: threadID)
            .is("read_at", value: nil)
            .execute()
    }
}
