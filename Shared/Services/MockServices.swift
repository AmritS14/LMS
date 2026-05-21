import Foundation

// MARK: - Mock Data Fixtures

enum MockData {

    // MARK: Users & Profiles

    static let loanOfficerUser = User(
        id: UUID(uuidString: "11111111-0000-0000-0000-000000000001")!,
        fullName: "Arjun Mehta",
        email: "arjun.mehta@lmsbank.in",
        phone: "+91-9876543210",
        role: .loanOfficer
    )

    static let loanOfficerStaff = StaffProfile(
        id: loanOfficerUser.id,
        employeeID: "EMP-00231",
        branchID: UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000001")!,
        department: "Retail Lending",
        reportsToID: managerUser.id
    )

    static let managerUser = User(
        id: UUID(uuidString: "22222222-0000-0000-0000-000000000002")!,
        fullName: "Priya Sharma",
        email: "priya.sharma@lmsbank.in",
        phone: "+91-9000000002",
        role: .manager
    )

    // MARK: Borrowers

    static let borrowerJane = User(
        id: UUID(uuidString: "33333333-0000-0000-0000-000000000003")!,
        fullName: "Jane Doe",
        email: "jane.doe@email.com",
        phone: "+91-9111111111",
        role: .borrower
    )
    static let profileJane = BorrowerProfile(
        id: borrowerJane.id,
        dateOfBirth: Calendar.current.date(from: DateComponents(year: 1990, month: 4, day: 15))!,
        address: PostalAddress(line1: "12 Maple Ave", line2: nil, city: "Mumbai", state: "Maharashtra", pinCode: 400001, country: "India"),
        panNumber: "ABCDE1234F",
        aadhaarLast4: "7821",
        employmentType: .salaried,
        monthlyIncome: 85000,
        kycStatus: .verified,
        creditScore: 750
    )

    static let borrowerRobert = User(
        id: UUID(uuidString: "44444444-0000-0000-0000-000000000004")!,
        fullName: "Robert King",
        email: "robert.king@email.com",
        phone: "+91-9222222222",
        role: .borrower
    )
    static let profileRobert = BorrowerProfile(
        id: borrowerRobert.id,
        dateOfBirth: Calendar.current.date(from: DateComponents(year: 1985, month: 11, day: 3))!,
        address: PostalAddress(line1: "45 Industrial Road", line2: nil, city: "Pune", state: "Maharashtra", pinCode: 411001, country: "India"),
        panNumber: "XYZAB9876C",
        aadhaarLast4: "4512",
        employmentType: .business,
        monthlyIncome: 120000,
        kycStatus: .submitted,
        creditScore: 610
    )

    static let borrowerAmelie = User(
        id: UUID(uuidString: "55555555-0000-0000-0000-000000000005")!,
        fullName: "Amelie Fernandez",
        email: "amelie.fernandez@email.com",
        phone: "+91-9333333333",
        role: .borrower
    )
    static let profileAmelie = BorrowerProfile(
        id: borrowerAmelie.id,
        dateOfBirth: Calendar.current.date(from: DateComponents(year: 1995, month: 7, day: 22))!,
        address: PostalAddress(line1: "67 College Street", line2: "Apt 2B", city: "Bangalore", state: "Karnataka", pinCode: 560001, country: "India"),
        panNumber: "PQRST5678G",
        aadhaarLast4: "9034",
        employmentType: .selfEmployed,
        monthlyIncome: 62000,
        kycStatus: .verified,
        creditScore: 690
    )

    static let borrowerDaniel = User(
        id: UUID(uuidString: "66666666-0000-0000-0000-000000000006")!,
        fullName: "Daniel Sharma",
        email: "daniel.sharma@email.com",
        phone: "+91-9444444444",
        role: .borrower
    )
    static let profileDaniel = BorrowerProfile(
        id: borrowerDaniel.id,
        dateOfBirth: Calendar.current.date(from: DateComponents(year: 1980, month: 2, day: 18))!,
        address: PostalAddress(line1: "88 Park Lane", line2: nil, city: "Chennai", state: "Tamil Nadu", pinCode: 600001, country: "India"),
        panNumber: "LMNOP2345H",
        aadhaarLast4: "1167",
        employmentType: .salaried,
        monthlyIncome: 95000,
        kycStatus: .verified,
        creditScore: 720
    )

    static let borrowerSophia = User(
        id: UUID(uuidString: "77777777-0000-0000-0000-000000000007")!,
        fullName: "Sophia Iyer",
        email: "sophia.iyer@email.com",
        phone: "+91-9555555555",
        role: .borrower
    )
    static let profileSophia = BorrowerProfile(
        id: borrowerSophia.id,
        dateOfBirth: Calendar.current.date(from: DateComponents(year: 1992, month: 9, day: 8))!,
        address: PostalAddress(line1: "23 West View", line2: nil, city: "Hyderabad", state: "Telangana", pinCode: 500001, country: "India"),
        panNumber: "GHIJK6789J",
        aadhaarLast4: "3348",
        employmentType: .salaried,
        monthlyIncome: 72000,
        kycStatus: .verified,
        creditScore: 760
    )

    // MARK: Documents

    static let janeDocuments: [LoanDocument] = [
        LoanDocument(id: UUID(uuidString: "D1111111-0000-0000-0000-000000000001")!,
                     ownerID: borrowerJane.id, kind: .identityProof,
                     fileName: "Passport_Jane.pdf", mimeType: "application/pdf",
                     remoteURL: URL(string: "https://example.com/docs/passport_jane.pdf"),
                     status: .verified),
        LoanDocument(id: UUID(uuidString: "D1111111-0000-0000-0000-000000000002")!,
                     ownerID: borrowerJane.id, kind: .incomeProof,
                     fileName: "Salary_Slip_Jane.pdf", mimeType: "application/pdf",
                     status: .pending),
        LoanDocument(id: UUID(uuidString: "D1111111-0000-0000-0000-000000000003")!,
                     ownerID: borrowerJane.id, kind: .collateral,
                     fileName: "Property_Papers_Jane.pdf", mimeType: "application/pdf",
                     status: .verified)
    ]

    static let robertDocuments: [LoanDocument] = [
        LoanDocument(id: UUID(uuidString: "D2222222-0000-0000-0000-000000000001")!,
                     ownerID: borrowerRobert.id, kind: .identityProof,
                     fileName: "Aadhaar_Robert.pdf", mimeType: "application/pdf",
                     status: .pending),
        LoanDocument(id: UUID(uuidString: "D2222222-0000-0000-0000-000000000002")!,
                     ownerID: borrowerRobert.id, kind: .incomeProof,
                     fileName: "Income_Statement_Robert.pdf", mimeType: "application/pdf",
                     status: .rejected),  // ← flagged as tampered
        LoanDocument(id: UUID(uuidString: "D2222222-0000-0000-0000-000000000003")!,
                     ownerID: borrowerRobert.id, kind: .bankStatement,
                     fileName: "BankStatement_Robert.pdf", mimeType: "application/pdf",
                     status: .pending)
    ]

    static let amelieDocuments: [LoanDocument] = [
        LoanDocument(id: UUID(uuidString: "D3333333-0000-0000-0000-000000000001")!,
                     ownerID: borrowerAmelie.id, kind: .identityProof,
                     fileName: "PAN_Amelie.pdf", mimeType: "application/pdf",
                     status: .verified),
        LoanDocument(id: UUID(uuidString: "D3333333-0000-0000-0000-000000000002")!,
                     ownerID: borrowerAmelie.id, kind: .addressProof,
                     fileName: "Utility_Bill_Amelie.pdf", mimeType: "application/pdf",
                     status: .verified)
    ]

    // MARK: Loan Applications

    static let appJane = LoanApplication(
        id: UUID(uuidString: "A1111111-0000-0000-0000-000000000001")!,
        borrowerID: borrowerJane.id,
        assignedOfficerID: loanOfficerUser.id,
        loanType: .home,
        requestedAmount: 3_500_000,
        tenureMonths: 240,
        interestRate: 8.5,
        status: .underReview,
        documentIDs: janeDocuments.map(\.id),
        createdAt: Date(timeIntervalSinceNow: -3 * 86400),
        updatedAt: Date(timeIntervalSinceNow: -3600)
    )

    static let appRobert = LoanApplication(
        id: UUID(uuidString: "A2222222-0000-0000-0000-000000000002")!,
        borrowerID: borrowerRobert.id,
        assignedOfficerID: loanOfficerUser.id,
        loanType: .business,
        requestedAmount: 1_800_000,
        tenureMonths: 60,
        interestRate: 12.0,
        status: .submitted,
        documentIDs: robertDocuments.map(\.id),
        createdAt: Date(timeIntervalSinceNow: -1 * 86400),
        updatedAt: Date(timeIntervalSinceNow: -7200)
    )

    static let appAmelie = LoanApplication(
        id: UUID(uuidString: "A3333333-0000-0000-0000-000000000003")!,
        borrowerID: borrowerAmelie.id,
        assignedOfficerID: loanOfficerUser.id,
        loanType: .education,
        requestedAmount: 500_000,
        tenureMonths: 84,
        interestRate: 9.0,
        status: .additionalInfoRequired,
        documentIDs: amelieDocuments.map(\.id),
        createdAt: Date(timeIntervalSinceNow: -5 * 86400),
        updatedAt: Date(timeIntervalSinceNow: -12 * 3600)
    )

    static let appDaniel = LoanApplication(
        id: UUID(uuidString: "A4444444-0000-0000-0000-000000000004")!,
        borrowerID: borrowerDaniel.id,
        assignedOfficerID: loanOfficerUser.id,
        loanType: .vehicle,
        requestedAmount: 700_000,
        tenureMonths: 60,
        interestRate: 9.5,
        status: .recommended,
        documentIDs: [],
        createdAt: Date(timeIntervalSinceNow: -10 * 86400),
        updatedAt: Date(timeIntervalSinceNow: -2 * 86400)
    )

    static let appSophia = LoanApplication(
        id: UUID(uuidString: "A5555555-0000-0000-0000-000000000005")!,
        borrowerID: borrowerSophia.id,
        assignedOfficerID: loanOfficerUser.id,
        loanType: .personal,
        requestedAmount: 250_000,
        tenureMonths: 36,
        interestRate: 13.5,
        status: .approved,
        documentIDs: [],
        createdAt: Date(timeIntervalSinceNow: -15 * 86400),
        updatedAt: Date(timeIntervalSinceNow: -5 * 86400)
    )

    static let allApplications: [LoanApplication] = [appJane, appRobert, appAmelie, appDaniel, appSophia]

    // MARK: Active Loans (overdue)

    static let loanDaniel: Loan = {
        let result = EMICalculator.calculate(
            principal: 700_000,
            annualInterestRate: 9.5,
            tenureMonths: 60,
            startDate: Calendar.current.date(byAdding: .month, value: -14, to: .now)!
        )
        return Loan(
            id: UUID(uuidString: "L4444444-0000-0000-0000-000000000004")!,
            applicationID: appDaniel.id,
            borrowerID: borrowerDaniel.id,
            principal: 700_000,
            interestRate: 9.5,
            tenureMonths: 60,
            disbursementDate: Date(timeIntervalSinceNow: -14 * 30 * 86400),
            outstandingBalance: 580_000,
            emiSchedule: result.schedule
        )
    }()

    static let loanSophia: Loan = {
        let result = EMICalculator.calculate(
            principal: 250_000,
            annualInterestRate: 13.5,
            tenureMonths: 36,
            startDate: Calendar.current.date(byAdding: .month, value: -6, to: .now)!
        )
        return Loan(
            id: UUID(uuidString: "L5555555-0000-0000-0000-000000000005")!,
            applicationID: appSophia.id,
            borrowerID: borrowerSophia.id,
            principal: 250_000,
            interestRate: 13.5,
            tenureMonths: 36,
            disbursementDate: Date(timeIntervalSinceNow: -6 * 30 * 86400),
            outstandingBalance: 195_000,
            emiSchedule: result.schedule
        )
    }()

    // MARK: Notifications

    static let notifications: [PushNotification] = [
        PushNotification(
            id: UUID(),
            topic: .applicationStatus,
            title: "New Assignment",
            body: "Application #A2222222 (Robert King) has been assigned to you.",
            receivedAt: Date(timeIntervalSinceNow: -600)
        ),
        PushNotification(
            id: UUID(),
            topic: .message,
            title: "Document Re-uploaded",
            body: "Jane Doe re-uploaded her Income Proof.",
            receivedAt: Date(timeIntervalSinceNow: -3600)
        ),
        PushNotification(
            id: UUID(),
            topic: .emiOverdue,
            title: "Fraud Risk Alert 🚨",
            body: "Robert King's income statement is flagged as potentially tampered.",
            receivedAt: Date(timeIntervalSinceNow: -7200)
        ),
        PushNotification(
            id: UUID(),
            topic: .applicationStatus,
            title: "Application Returned",
            body: "Manager sent back Daniel Sharma's application with remarks.",
            receivedAt: Date(timeIntervalSinceNow: -86400)
        ),
        PushNotification(
            id: UUID(),
            topic: .emiDue,
            title: "EMI Overdue",
            body: "Sophia Iyer's EMI is overdue by 2 days.",
            receivedAt: Date(timeIntervalSinceNow: -2 * 86400)
        )
    ]

    // MARK: Messages

    static let thread1 = MessageThread(
        id: UUID(uuidString: "T1111111-0000-0000-0000-000000000001")!,
        participantIDs: [loanOfficerUser.id, borrowerJane.id],
        applicationID: appJane.id,
        lastMessagePreview: "Please re-upload your income statement.",
        updatedAt: Date(timeIntervalSinceNow: -1800)
    )

    static let thread2 = MessageThread(
        id: UUID(uuidString: "T2222222-0000-0000-0000-000000000002")!,
        participantIDs: [loanOfficerUser.id, borrowerRobert.id],
        applicationID: appRobert.id,
        lastMessagePreview: "I can clarify the discrepancy tomorrow.",
        updatedAt: Date(timeIntervalSinceNow: -5 * 3600)
    )

    static let thread3 = MessageThread(
        id: UUID(uuidString: "T3333333-0000-0000-0000-000000000003")!,
        participantIDs: [loanOfficerUser.id, borrowerAmelie.id],
        applicationID: appAmelie.id,
        lastMessagePreview: "Documents have been submitted successfully.",
        updatedAt: Date(timeIntervalSinceNow: -12 * 3600)
    )

    static let messagesThread1: [ChatMessage] = [
        ChatMessage(id: UUID(), threadID: thread1.id, senderID: loanOfficerUser.id,
                    body: "Hi Jane, your income statement needs to be re-uploaded with a clearer scan.",
                    sentAt: Date(timeIntervalSinceNow: -5400)),
        ChatMessage(id: UUID(), threadID: thread1.id, senderID: borrowerJane.id,
                    body: "Sure, I will upload it by evening today.",
                    sentAt: Date(timeIntervalSinceNow: -4200)),
        ChatMessage(id: UUID(), threadID: thread1.id, senderID: loanOfficerUser.id,
                    body: "Please re-upload your income statement.",
                    sentAt: Date(timeIntervalSinceNow: -1800))
    ]

    static let messagesThread2: [ChatMessage] = [
        ChatMessage(id: UUID(), threadID: thread2.id, senderID: loanOfficerUser.id,
                    body: "Mr. King, we have flagged a discrepancy in your income statement. Could you clarify?",
                    sentAt: Date(timeIntervalSinceNow: -7200)),
        ChatMessage(id: UUID(), threadID: thread2.id, senderID: borrowerRobert.id,
                    body: "I can clarify the discrepancy tomorrow.",
                    sentAt: Date(timeIntervalSinceNow: -5 * 3600))
    ]

    static let messagesThread3: [ChatMessage] = [
        ChatMessage(id: UUID(), threadID: thread3.id, senderID: borrowerAmelie.id,
                    body: "Documents have been submitted successfully.",
                    sentAt: Date(timeIntervalSinceNow: -12 * 3600))
    ]

    static func messages(for threadID: UUID) -> [ChatMessage] {
        if threadID == thread1.id { return messagesThread1 }
        if threadID == thread2.id { return messagesThread2 }
        if threadID == thread3.id { return messagesThread3 }
        return []
    }

    // Aux: borrower lookup
    static func borrowerUser(for id: UUID) -> User? {
        [borrowerJane, borrowerRobert, borrowerAmelie, borrowerDaniel, borrowerSophia].first { $0.id == id }
    }
    static func borrowerProfile(for id: UUID) -> BorrowerProfile? {
        [profileJane, profileRobert, profileAmelie, profileDaniel, profileSophia].first { $0.id == id }
    }
    static func documents(for ownerID: UUID) -> [LoanDocument] {
        if ownerID == borrowerJane.id { return janeDocuments }
        if ownerID == borrowerRobert.id { return robertDocuments }
        if ownerID == borrowerAmelie.id { return amelieDocuments }
        return []
    }
}

// MARK: - Mock Auth Service

actor MockAuthService: AuthService {
    var currentUser: User? { MockData.loanOfficerUser }

    func requestOTP(identifier: String) async throws { /* no-op */ }

    func verifyOTP(identifier: String, code: String) async throws -> User {
        MockData.loanOfficerUser
    }

    func signInWithPasskey() async throws -> User {
        try await Task.sleep(for: .milliseconds(600))
        return MockData.loanOfficerUser
    }

    func signOut() async throws { /* no-op */ }
}

// MARK: - Mock Loan Service

actor MockLoanService: LoanService {

    func createApplication(_ draft: LoanApplication) async throws -> LoanApplication { draft }

    func submitApplication(id: UUID) async throws -> LoanApplication {
        guard let app = MockData.allApplications.first(where: { $0.id == id }) else {
            throw URLError(.badURL)
        }
        return app
    }

    func fetchApplications(for borrowerID: UUID) async throws -> [LoanApplication] {
        MockData.allApplications.filter { $0.borrowerID == borrowerID }
    }

    func fetchAssignedApplications(officerID: UUID) async throws -> [LoanApplication] {
        try await Task.sleep(for: .milliseconds(400))
        return MockData.allApplications
    }

    func updateStatus(applicationID: UUID, to status: ApplicationStatus, note: String?) async throws {
        // In a real implementation this would mutate local state or call the backend.
    }

    func fetchActiveLoans(borrowerID: UUID) async throws -> [Loan] {
        [MockData.loanDaniel, MockData.loanSophia].filter { $0.borrowerID == borrowerID }
    }

    func fetchEMISchedule(loanID: UUID) async throws -> [EMI] {
        if loanID == MockData.loanDaniel.id { return MockData.loanDaniel.emiSchedule }
        if loanID == MockData.loanSophia.id { return MockData.loanSophia.emiSchedule }
        return []
    }

    // Extended helpers (called directly from view-models)
    func fetchAllOverdueLoans() async throws -> [Loan] {
        try await Task.sleep(for: .milliseconds(300))
        return [MockData.loanDaniel, MockData.loanSophia]
    }

    func borrowerUser(for id: UUID) -> User? { MockData.borrowerUser(for: id) }
    func borrowerProfile(for id: UUID) -> BorrowerProfile? { MockData.borrowerProfile(for: id) }
    func allApplications() -> [LoanApplication] { MockData.allApplications }
}

// MARK: - Mock Document Service

actor MockDocumentService: DocumentService {

    func upload(_ data: Data, fileName: String, mimeType: String, kind: DocumentKind, ownerID: UUID) async throws -> LoanDocument {
        LoanDocument(id: UUID(), ownerID: ownerID, kind: kind, fileName: fileName, mimeType: mimeType, status: .pending)
    }

    func list(ownerID: UUID) async throws -> [LoanDocument] {
        MockData.documents(for: ownerID)
    }

    func delete(documentID: UUID) async throws { /* no-op */ }

    func updateStatus(documentID: UUID, status: DocumentVerificationStatus) async throws { /* no-op */ }
}

// MARK: - Mock Notification Service

actor MockNotificationService: NotificationService {

    func registerDeviceToken(_ token: Data) async throws { /* no-op */ }
    func requestAuthorization() async throws -> Bool { true }
    func subscribe(to topic: NotificationTopic) async throws { /* no-op */ }
    func unsubscribe(from topic: NotificationTopic) async throws { /* no-op */ }

    func fetchHistory(limit: Int) async throws -> [PushNotification] {
        Array(MockData.notifications.prefix(limit))
    }
}

// MARK: - Mock Messaging Service

actor MockMessagingService: MessagingService {

    private var _messages: [UUID: [ChatMessage]] = [
        MockData.thread1.id: MockData.messagesThread1,
        MockData.thread2.id: MockData.messagesThread2,
        MockData.thread3.id: MockData.messagesThread3
    ]

    func threads(for userID: UUID) async throws -> [MessageThread] {
        [MockData.thread1, MockData.thread2, MockData.thread3]
    }

    func messages(threadID: UUID) async throws -> [ChatMessage] {
        _messages[threadID] ?? []
    }

    func send(_ message: ChatMessage) async throws -> ChatMessage {
        _messages[message.threadID, default: []].append(message)
        return message
    }

    func markRead(threadID: UUID, upTo: Date) async throws { /* no-op */ }

    // Lookup helpers
    func borrowerName(for thread: MessageThread) -> String {
        let participantIDs = thread.participantIDs.filter { $0 != MockData.loanOfficerUser.id }
        return participantIDs.compactMap { MockData.borrowerUser(for: $0)?.fullName }.first ?? "Unknown"
    }
}

// MARK: - Mock Keychain Service

struct MockKeychainService: KeychainService {
    func set(_ value: Data, for key: String) throws { /* no-op */ }
    func get(_ key: String) throws -> Data? { nil }
    func remove(_ key: String) throws { /* no-op */ }
}

// MARK: - Convenience Accessors for Views

extension MockData {
    static let sharedLoanService = MockLoanService()
    static let sharedMessagingService = MockMessagingService()
    static let sharedNotificationService = MockNotificationService()
    static let sharedDocumentService = MockDocumentService()

    static func makeMockEnvironment() -> AppEnvironment {
        AppEnvironment(
            auth: MockAuthService(),
            loans: sharedLoanService,
            documents: sharedDocumentService,
            notifications: sharedNotificationService,
            messaging: sharedMessagingService,
            keychain: MockKeychainService()
        )
    }

    // Application detail helpers
    static func application(id: UUID) -> LoanApplication? {
        allApplications.first { $0.id == id }
    }

    static func fraudFlagged(_ app: LoanApplication) -> Bool {
        // Robert King's income statement is flagged
        app.borrowerID == borrowerRobert.id
    }

    static func allBorrowerProfiles() -> [(User, BorrowerProfile)] {
        [
            (borrowerJane, profileJane),
            (borrowerRobert, profileRobert),
            (borrowerAmelie, profileAmelie),
            (borrowerDaniel, profileDaniel),
            (borrowerSophia, profileSophia)
        ]
    }
}
