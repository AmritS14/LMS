import Foundation

// MARK: - MockDocumentService

actor MockDocumentService: DocumentService {

        private var documents: [LoanDocument] = []

    func upload(_ data: Data, fileName: String, mimeType: String,
                kind: DocumentKind, ownerID: UUID) async throws -> LoanDocument {
        try await Task.sleep(for: .milliseconds(600))
        let doc = LoanDocument(
            ownerID: ownerID, kind: kind,
            fileName: fileName, mimeType: mimeType,
            remoteURL: nil, status: .pending
        )
                documents.append(doc)
                return doc
    }

    func list(ownerID: UUID) async throws -> [LoanDocument] {
                        return documents.filter { $0.ownerID == ownerID }
    }

    func delete(documentID: UUID) async throws {
                documents.removeAll { $0.id == documentID }
            }

    func updateStatus(documentID: UUID, status: DocumentVerificationStatus) async throws {
                if let idx = documents.firstIndex(where: { $0.id == documentID }) {
            documents[idx].status = status
        }
            }
}

// MARK: - MockMessagingService

actor MockMessagingService: MessagingService {

    
    private let borrowerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let officerID  = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private let threadID   = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
    private let appID      = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!

    private var threadList: [MessageThread]
    private var messageStore: [UUID: [ChatMessage]]

    init() {
        let thread = MessageThread(
            id: threadID,
            participantIDs: [borrowerID, officerID],
            applicationID: appID,
            lastMessagePreview: "Please share your bank statement.",
            updatedAt: .now
        )
        threadList = [thread]

        let t: (Int) -> Date = { Date().addingTimeInterval(Double($0) * 60) }
        messageStore = [
            threadID: [
                ChatMessage(id: UUID(), threadID: threadID, senderID: officerID,
                            body: "Hi Naman, I've reviewed your Home Loan application. Could you clarify the source of your ₹5 L down payment?",
                            sentAt: t(-120)),
                ChatMessage(id: UUID(), threadID: threadID, senderID: borrowerID,
                            body: "Hi Sarah, it's from my savings account. I can share the bank statement.",
                            sentAt: t(-110)),
                ChatMessage(id: UUID(), threadID: threadID, senderID: officerID,
                            body: "That would be great. Also, the property valuation needs a second review.",
                            sentAt: t(-100)),
                ChatMessage(id: UUID(), threadID: threadID, senderID: borrowerID,
                            body: "Understood. Should I get an independent valuation report?",
                            sentAt: t(-90)),
                ChatMessage(id: UUID(), threadID: threadID, senderID: officerID,
                            body: "Yes, please do. Please share your bank statement as well.",
                            sentAt: t(-80))
            ]
        ]
    }

    func threads(for userID: UUID) async throws -> [MessageThread] {
        try await Task.sleep(for: .milliseconds(200))
        return threadList
    }

    func messages(threadID: UUID) async throws -> [ChatMessage] {
        try await Task.sleep(for: .milliseconds(150))
                        return (messageStore[threadID] ?? []).sorted { $0.sentAt < $1.sentAt }
    }

    func send(_ message: ChatMessage) async throws -> ChatMessage {
        try await Task.sleep(for: .milliseconds(200))
                var msgs = messageStore[message.threadID] ?? []
        msgs.append(message)
        messageStore[message.threadID] = msgs

        // Update thread preview
        if let idx = threadList.firstIndex(where: { $0.id == message.threadID }) {
            threadList[idx].lastMessagePreview = message.body
            threadList[idx].updatedAt = message.sentAt
        }
                return message
    }

    func markRead(threadID: UUID, upTo: Date) async throws {
                if var msgs = messageStore[threadID] {
            for i in msgs.indices where msgs[i].readAt == nil && msgs[i].sentAt <= upTo {
                msgs[i].readAt = .now
            }
            messageStore[threadID] = msgs
        }
            }
}

// MARK: - MockNotificationService

actor MockNotificationService: NotificationService {

        private var history: [PushNotification]

    init() {
        history = [
            PushNotification(
                topic: .emiDue,
                title: "EMI Due Tomorrow",
                body: "Your Home Loan EMI of ₹21,653 is due on \(Formatting.date(.now.addingTimeInterval(86400))).",
                receivedAt: .now.addingTimeInterval(-3600)
            ),
            PushNotification(
                topic: .applicationStatus,
                title: "Application Update",
                body: "Your Personal Loan application is now under review.",
                receivedAt: .now.addingTimeInterval(-86400)
            ),
            PushNotification(
                topic: .disbursement,
                title: "Loan Disbursed",
                body: "Your Home Loan of ₹25,00,000 has been disbursed to your account.",
                receivedAt: .now.addingTimeInterval(-86400 * 90)
            )
        ]
    }

    func registerDeviceToken(_ token: Data) async throws { }
    func requestAuthorization() async throws -> Bool { true }
    func subscribe(to topic: NotificationTopic) async throws { }
    func unsubscribe(from topic: NotificationTopic) async throws { }

    func fetchHistory(limit: Int) async throws -> [PushNotification] {
        try await Task.sleep(for: .milliseconds(150))
                        return Array(history.sorted { $0.receivedAt > $1.receivedAt }.prefix(limit))
    }
}

// MARK: - MockKeychainService

final class MockKeychainService: KeychainService, @unchecked Sendable {

    private let lock = NSLock()
    private var store: [String: Data] = [:]

    func set(_ value: Data, for key: String) throws {
        lock.lock()
        store[key] = value
        lock.unlock()
    }

    func get(_ key: String) throws -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return store[key]
    }

    func remove(_ key: String) throws {
        lock.lock()
        store.removeValue(forKey: key)
        lock.unlock()
    }
}
