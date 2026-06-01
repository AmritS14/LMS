import Foundation

// MARK: - MockAadhaarKYCService

actor MockAadhaarKYCService: AadhaarKYCService {
    func verify(zipData: Data, sharePhrase: String, applicationID: UUID?) async throws -> AadhaarVerificationReport {
        try await Task.sleep(for: .seconds(1))
        return AadhaarVerificationReport(
            documentId: UUID().uuidString,
            signatureValid: true,
            signerCert: AadhaarSignerCert(
                subject: "CN=UIDAI, O=Unique Identification Authority of India, C=IN",
                signingTime: ISO8601DateFormatter().string(from: .now)
            ),
            mobileHashMatch: .match,
            emailHashMatch: .match,
            referenceId: "1\(Int.random(in: 10000000000000...99999999999999))123",
            xmlGeneratedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 30)),
            xmlAgeDays: 30,
            demographics: AadhaarDemographics(
                name: "Ravi Kumar",
                dob: "1990-06-15",
                gender: "M",
                careOf: "Sh. Ramesh Kumar",
                address: [
                    "house": "12A",
                    "street": "MG Road",
                    "city": "Bengaluru",
                    "state": "Karnataka",
                    "pinCode": "560001",
                    "country": "INDIA"
                ]
            ),
            photoUrl: nil,
            autoDecision: .auto_verified,
            rejectionReason: nil
        )
    }

    func report(documentID: UUID) async throws -> AadhaarVerificationReport? {
        try await Task.sleep(for: .milliseconds(500))
        return nil
    }
}

// MARK: - MockAdminService

actor MockAdminService: AdminService {
    func listUsers(ids: [UUID]?) async throws -> [User] { [] }
    func listStaffProfiles() async throws -> [StaffProfile] { [] }
    func createStaff(email: String, fullName: String, role: UserRole, employeeID: String, temporaryPassword: String) async throws -> UUID {
        UUID()
    }
}

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

    func documents(forApplication applicationID: UUID) async throws -> [LoanDocument] {
        // Mock store isn't application-scoped; return everything for previews.
        return documents
    }

    func delete(documentID: UUID) async throws {
                documents.removeAll { $0.id == documentID }
            }

    func updateStatus(documentID: UUID, status: DocumentVerificationStatus) async throws {
                if let idx = documents.firstIndex(where: { $0.id == documentID }) {
            documents[idx].status = status
        }
            }

    func signedURL(documentID: UUID) async throws -> URL {
        URL(string: "https://example.com/mock/\(documentID.uuidString)")!
    }

    func verifyDocument(documentID: UUID, remark: String?) async throws {
        if let idx = documents.firstIndex(where: { $0.id == documentID }) {
            documents[idx].status = .verified
        }
    }

    func rejectDocument(documentID: UUID, reason: String) async throws {
        if let idx = documents.firstIndex(where: { $0.id == documentID }) {
            documents[idx].status = .rejected
        }
    }
}

// MARK: - MockMessagingService

actor MockMessagingService: MessagingService {

    
    private let borrowerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let officerID  = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private let homeThreadID     = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
    private let personalThreadID = UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!
    private let supportThreadID  = UUID(uuidString: "ffffffff-ffff-ffff-ffff-ffffffffffff")!
    private let homeAppID     = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
    private let personalAppID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!

    private var threadList: [MessageThread]
    private var messageStore: [UUID: [ChatMessage]]

    init() {
        let homeThread = MessageThread(
            id: homeThreadID,
            participantIDs: [borrowerID, officerID],
            applicationID: homeAppID,
            lastMessagePreview: "Please share your bank statement.",
            updatedAt: Date().addingTimeInterval(-60 * 80)
        )
        let personalThread = MessageThread(
            id: personalThreadID,
            participantIDs: [borrowerID, officerID],
            applicationID: personalAppID,
            lastMessagePreview: "Your application is now under review.",
            updatedAt: Date().addingTimeInterval(-60 * 60 * 24)
        )
        let supportThread = MessageThread(
            id: supportThreadID,
            participantIDs: [borrowerID, officerID],
            applicationID: nil,
            lastMessagePreview: "How can we help you today?",
            updatedAt: Date().addingTimeInterval(-60 * 60 * 24 * 3)
        )
        threadList = [homeThread, personalThread, supportThread]

        let t: (Int) -> Date = { Date().addingTimeInterval(Double($0) * 60) }
        messageStore = [
            homeThreadID: [
                ChatMessage(id: UUID(), threadID: homeThreadID, senderID: officerID,
                            body: "Hi Naman, I've reviewed your Home Loan application. Could you clarify the source of your ₹5 L down payment?",
                            sentAt: t(-120)),
                ChatMessage(id: UUID(), threadID: homeThreadID, senderID: borrowerID,
                            body: "Hi Sarah, it's from my savings account. I can share the bank statement.",
                            sentAt: t(-110)),
                ChatMessage(id: UUID(), threadID: homeThreadID, senderID: officerID,
                            body: "That would be great. Also, the property valuation needs a second review.",
                            sentAt: t(-100)),
                ChatMessage(id: UUID(), threadID: homeThreadID, senderID: borrowerID,
                            body: "Understood. Should I get an independent valuation report?",
                            sentAt: t(-90)),
                ChatMessage(id: UUID(), threadID: homeThreadID, senderID: officerID,
                            body: "Yes, please do. Please share your bank statement as well.",
                            sentAt: t(-80))
            ],
            personalThreadID: [
                ChatMessage(id: UUID(), threadID: personalThreadID, senderID: borrowerID,
                            body: "Hello, when can I expect a decision on my personal loan?",
                            sentAt: t(-60 * 25)),
                ChatMessage(id: UUID(), threadID: personalThreadID, senderID: officerID,
                            body: "Your application is now under review. We'll update you within 48 hours.",
                            sentAt: t(-60 * 24))
            ],
            supportThreadID: [
                ChatMessage(id: UUID(), threadID: supportThreadID, senderID: officerID,
                            body: "How can we help you today?",
                            sentAt: t(-60 * 24 * 3))
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

    func ensureThread(applicationID: UUID, participantIDs: [UUID]) async throws -> MessageThread {
        if let existing = threadList.first(where: { $0.applicationID == applicationID }) {
            return existing
        }
        let thread = MessageThread(
            id: UUID(),
            participantIDs: participantIDs,
            applicationID: applicationID,
            lastMessagePreview: nil,
            updatedAt: .now
        )
        threadList.insert(thread, at: 0)
        messageStore[thread.id] = []
        return thread
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
