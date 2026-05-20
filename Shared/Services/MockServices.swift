import Foundation

struct MockLoanService: LoanService {
    func createApplication(_ draft: LoanApplication) async throws -> LoanApplication { return draft }
    func submitApplication(id: UUID) async throws -> LoanApplication { fatalError() }
    func fetchApplications(for borrowerID: UUID) async throws -> [LoanApplication] { return [] }
    func fetchAssignedApplications(officerID: UUID) async throws -> [LoanApplication] { return [] }
    func updateStatus(applicationID: UUID, to status: ApplicationStatus, note: String?) async throws {}
    func fetchActiveLoans(borrowerID: UUID) async throws -> [Loan] { return [] }
    func fetchEMISchedule(loanID: UUID) async throws -> [EMI] { return [] }
}

struct MockDocumentService: DocumentService {
    func upload(_ data: Data, fileName: String, mimeType: String, kind: DocumentKind, ownerID: UUID) async throws -> LoanDocument { fatalError() }
    func list(ownerID: UUID) async throws -> [LoanDocument] { return [] }
    func delete(documentID: UUID) async throws {}
    func updateStatus(documentID: UUID, status: DocumentVerificationStatus) async throws {}
}

struct MockNotificationService: NotificationService {
    func registerDeviceToken(_ token: Data) async throws {}
    func requestAuthorization() async throws -> Bool { return true }
    func subscribe(to topic: NotificationTopic) async throws {}
    func unsubscribe(from topic: NotificationTopic) async throws {}
    func fetchHistory(limit: Int) async throws -> [PushNotification] { return [] }
}

struct MockMessagingService: MessagingService {
    func threads(for userID: UUID) async throws -> [MessageThread] { return [] }
    func messages(threadID: UUID) async throws -> [ChatMessage] { return [] }
    func send(_ message: ChatMessage) async throws -> ChatMessage { return message }
    func markRead(threadID: UUID, upTo: Date) async throws {}
}

struct MockKeychainService: KeychainService {
    func set(_ value: Data, for key: String) throws {}
    func get(_ key: String) throws -> Data? { return nil }
    func remove(_ key: String) throws {}
}
