import Foundation
import Observation
import SwiftUI

// MARK: - UnreadMessageStore

/// Tracks per-thread unread message counts for the borrower.
///
/// Designed to be created once at app root and injected as an
/// `@Environment` dependency so every tab and view shares the
/// same source of truth.
///
/// **Unread definition**: a message whose `sentAt` is later than the
/// last-read timestamp for that thread AND whose `senderID` is not
/// the current user (i.e. messages from the other party).
///
/// **Persistence**: last-read timestamps are stored in `UserDefaults`
/// under a namespaced key so they survive app restarts without any
/// additional database schema.
@MainActor
@Observable
final class UnreadMessageStore {

    // MARK: - Public state

    /// Per-thread unread counts.  Key = thread UUID string.
    private(set) var unreadCounts: [String: Int] = [:]

    /// Sum of all unread messages across every thread.
    var totalUnread: Int {
        unreadCounts.values.reduce(0, +)
    }

    // MARK: - Private state

    /// Tracks whether a background polling loop is active.
    private var pollingTask: Task<Void, Never>?

    /// Tracks which thread (if any) is currently open, so we can
    /// suppress badge updates while the user is actively reading.
    private(set) var activeThreadID: UUID?

    // MARK: - UserDefaults persistence

    /// Key prefix for last-read timestamp storage.
    private static let udKeyPrefix = "unread_lastRead_"

    /// Returns the UserDefaults key for a given thread ID.
    private func udKey(for threadID: UUID) -> String {
        Self.udKeyPrefix + threadID.uuidString
    }

    /// Reads the persisted last-read timestamp for a thread, or
    /// `.distantPast` if the thread has never been opened.
    private func lastReadDate(for threadID: UUID) -> Date {
        let stored = UserDefaults.standard.double(forKey: udKey(for: threadID))
        guard stored > 0 else { return .distantPast }
        return Date(timeIntervalSince1970: stored)
    }

    /// Persists the last-read timestamp for a thread.
    private func saveLastReadDate(_ date: Date, for threadID: UUID) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: udKey(for: threadID))
    }

    // MARK: - Core refresh

    /// Fetches all threads and recomputes unread counts.
    ///
    /// - Parameters:
    ///   - messagingService: The live (or mock) messaging back-end.
    ///   - currentUserID: The authenticated borrower's UUID.
    func refresh(messagingService: any MessagingService, currentUserID: UUID) async {
        guard let threads = try? await messagingService.threads(for: currentUserID) else { return }

        var newCounts: [String: Int] = [:]

        await withTaskGroup(of: (String, Int).self) { group in
            for thread in threads {
                group.addTask {
                    let key = thread.id.uuidString

                    // Skip counting if this thread is currently open —
                    // the user is actively reading it.
                    if await self.activeThreadID == thread.id {
                        return (key, 0)
                    }

                    guard let messages = try? await messagingService.messages(threadID: thread.id) else {
                        return (key, 0)
                    }

                    let lastRead = await self.lastReadDate(for: thread.id)
                    let count = messages.filter { msg in
                        msg.senderID != currentUserID && msg.sentAt > lastRead
                    }.count

                    return (key, count)
                }
            }

            for await (key, count) in group {
                newCounts[key] = count
            }
        }

        unreadCounts = newCounts
    }

    // MARK: - Mark as read

    /// Marks all messages in a thread as read:
    /// - Zeroes the in-memory unread count immediately (instant UI update).
    /// - Saves the current timestamp as the last-read date for persistence.
    /// - Calls `markRead` on the messaging service so the server state is
    ///   updated (e.g. for push notification suppression / future badge sync).
    ///
    /// Call this when the user **opens** a conversation.
    func markRead(
        threadID: UUID,
        messagingService: any MessagingService
    ) async {
        // Zero immediately so the badge updates the instant the view appears.
        unreadCounts[threadID.uuidString] = 0

        let now = Date()
        saveLastReadDate(now, for: threadID)

        // Best-effort server sync — ignore errors (will retry on next open).
        try? await messagingService.markRead(threadID: threadID, upTo: now)
    }

    // MARK: - Active thread tracking

    /// Tells the store which thread is currently open so it won't
    /// inflate that thread's count during background refreshes.
    func setActiveThread(_ threadID: UUID?) {
        activeThreadID = threadID
    }

    // MARK: - Background polling

    /// Starts a repeating background task that refreshes unread counts
    /// every `interval` seconds.  Safe to call multiple times — an
    /// existing polling task is cancelled and replaced.
    ///
    /// - Parameters:
    ///   - messagingService: The messaging back-end.
    ///   - currentUserID: The authenticated borrower's UUID.
    ///   - interval: Polling cadence in seconds (default 15).
    func startPolling(
        messagingService: any MessagingService,
        currentUserID: UUID,
        interval: TimeInterval = 15
    ) {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            // Immediate first refresh so the badge is populated right away.
            await self?.refresh(messagingService: messagingService, currentUserID: currentUserID)

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                await self?.refresh(messagingService: messagingService, currentUserID: currentUserID)
            }
        }
    }

    /// Cancels the background polling task.
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - Reset

    /// Clears all in-memory state (called on sign-out so counts don't
    /// bleed into the next session).
    func reset() {
        stopPolling()
        unreadCounts = [:]
        activeThreadID = nil
    }
}
