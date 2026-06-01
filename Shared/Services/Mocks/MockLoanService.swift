import Foundation

/// Mock implementation of `LoanService` for development.
/// Seeded with one active Home Loan and two applications.
actor MockLoanService: LoanService {

    
    // Fixed IDs
    private let borrowerID   = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let officerID    = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private let loanID       = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
    private let app1ID       = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
    private let app2ID       = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!

    private var applications: [LoanApplication]
    private var loans: [Loan]

    init() {
        let disbursedDate = Calendar.current.date(byAdding: .month, value: -3, to: .now)!

        // Application 1 — disbursed (matches the active loan)
        let app1 = LoanApplication(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            borrowerID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            assignedOfficerID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            loanType: .home,
            requestedAmount: 2_500_000,
            tenureMonths: 240,
            interestRate: 8.5,
            status: .disbursed,
            documentIDs: [],
            createdAt: Calendar.current.date(byAdding: .month, value: -4, to: .now)!,
            updatedAt: disbursedDate
        )

        // Application 2 — under review
        let app2 = LoanApplication(
            id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            borrowerID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            assignedOfficerID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            loanType: .personal,
            requestedAmount: 300_000,
            tenureMonths: 36,
            interestRate: 10.5,
            status: .underReview,
            documentIDs: [],
            createdAt: Calendar.current.date(byAdding: .day, value: -5, to: .now)!,
            updatedAt: .now
        )

        self.applications = [app1, app2]

        // Active Loan — generated from Application 1
        let emiResult = EMICalculator.calculate(
            principal: 2_500_000,
            annualInterestRate: 8.5,
            tenureMonths: 240,
            startDate: disbursedDate
        )

        // Override first 2 as paid, 3rd as overdue
        var schedule = emiResult.schedule
        for i in schedule.indices {
            if i < 45 {
                schedule[i].status = .paid
                schedule[i].paidAt = schedule[i].dueDate
            } else if i == 2 {
                schedule[i].status = .overdue
            } else {
                schedule[i].status = .upcoming
            }
        }

        let paidPrincipal = schedule.prefix(45).reduce(Decimal.zero) { $0 + $1.principalComponent }
        let outstanding = Decimal(2_500_000) - paidPrincipal

        let loan = Loan(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            applicationID: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            borrowerID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            loanType: .home,
            principal: 2_500_000,
            interestRate: 8.5,
            tenureMonths: 240,
            disbursementDate: disbursedDate,
            outstandingBalance: outstanding,
            emiSchedule: schedule,
            status: .active
        )

        // Active Loan 2 — Education Loan
        let eduDisbursed = Calendar.current.date(byAdding: .month, value: -12, to: .now)!
        let eduEmi = EMICalculator.calculate(principal: 500_000, annualInterestRate: 11.0, tenureMonths: 60, startDate: eduDisbursed)
        var eduSchedule = eduEmi.schedule
        for i in eduSchedule.indices {
            if i < 11 {
                eduSchedule[i].status = .paid
                eduSchedule[i].paidAt = eduSchedule[i].dueDate
            } else {
                eduSchedule[i].status = .upcoming
            }
        }
        let eduPaidPrincipal = eduSchedule.prefix(11).reduce(Decimal.zero) { $0 + $1.principalComponent }
        let eduOutstanding = Decimal(500_000) - eduPaidPrincipal
        let eduLoan = Loan(
            id: UUID(),
            applicationID: UUID(),
            borrowerID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            loanType: .education,
            principal: 500_000,
            interestRate: 11.0,
            tenureMonths: 60,
            disbursementDate: eduDisbursed,
            outstandingBalance: eduOutstanding,
            emiSchedule: eduSchedule,
            status: .active
        )

        // Active Loan 3 — Vehicle Loan
        let vehicleDisbursed = Calendar.current.date(byAdding: .month, value: -6, to: .now)!
        let vehicleEmi = EMICalculator.calculate(principal: 800_000, annualInterestRate: 9.5, tenureMonths: 48, startDate: vehicleDisbursed)
        var vehicleSchedule = vehicleEmi.schedule
        for i in vehicleSchedule.indices {
            if i < 5 {
                vehicleSchedule[i].status = .paid
                vehicleSchedule[i].paidAt = vehicleSchedule[i].dueDate
            } else {
                vehicleSchedule[i].status = .upcoming
            }
        }
        let vehiclePaidPrincipal = vehicleSchedule.prefix(5).reduce(Decimal.zero) { $0 + $1.principalComponent }
        let vehicleOutstanding = Decimal(800_000) - vehiclePaidPrincipal
        let vehicleLoan = Loan(
            id: UUID(),
            applicationID: UUID(),
            borrowerID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            loanType: .vehicle,
            principal: 800_000,
            interestRate: 9.5,
            tenureMonths: 48,
            disbursementDate: vehicleDisbursed,
            outstandingBalance: vehicleOutstanding,
            emiSchedule: vehicleSchedule,
            status: .active
        )

        // Settled Loan — Personal Loan
        let settledDisbursed = Calendar.current.date(byAdding: .month, value: -40, to: .now)!
        let settledEmi = EMICalculator.calculate(principal: 200_000, annualInterestRate: 14.0, tenureMonths: 36, startDate: settledDisbursed)
        var settledSchedule = settledEmi.schedule
        for i in settledSchedule.indices {
            settledSchedule[i].status = .paid
            settledSchedule[i].paidAt = settledSchedule[i].dueDate
        }
        let settledLoan = Loan(
            id: UUID(),
            applicationID: UUID(),
            borrowerID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            loanType: .personal,
            principal: 200_000,
            interestRate: 14.0,
            tenureMonths: 36,
            disbursementDate: settledDisbursed,
            outstandingBalance: .zero,
            emiSchedule: settledSchedule,
            status: .settled
        )

        // Settled Loan 2 — Business Loan
        let settledDisbursed2 = Calendar.current.date(byAdding: .month, value: -60, to: .now)!
        let settledEmi2 = EMICalculator.calculate(principal: 5_000_000, annualInterestRate: 12.0, tenureMonths: 48, startDate: settledDisbursed2)
        var settledSchedule2 = settledEmi2.schedule
        for i in settledSchedule2.indices {
            settledSchedule2[i].status = .paid
            settledSchedule2[i].paidAt = settledSchedule2[i].dueDate
        }
        let settledLoan2 = Loan(
            id: UUID(),
            applicationID: UUID(),
            borrowerID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            loanType: .business,
            principal: 5_000_000,
            interestRate: 12.0,
            tenureMonths: 48,
            disbursementDate: settledDisbursed2,
            outstandingBalance: .zero,
            emiSchedule: settledSchedule2,
            status: .settled
        )

        self.loans = [loan, eduLoan, vehicleLoan, settledLoan, settledLoan2]
    }

    // MARK: - LoanService Protocol

    func fetchLoanProducts() async throws -> [LoanProduct] {
        try await Task.sleep(for: .milliseconds(200))
        return [
            LoanProduct(name: "Home Loan", minimumAmount: 500_000, maximumAmount: 50_000_000, minimumTenureMonths: 60, maximumTenureMonths: 360, minimumInterestRate: 6, maximumInterestRate: 12),
            LoanProduct(name: "Personal Loan", minimumAmount: 10_000, maximumAmount: 1_000_000, minimumTenureMonths: 6, maximumTenureMonths: 60, minimumInterestRate: 10, maximumInterestRate: 24),
            LoanProduct(name: "Vehicle Loan", minimumAmount: 50_000, maximumAmount: 5_000_000, minimumTenureMonths: 12, maximumTenureMonths: 84, minimumInterestRate: 7, maximumInterestRate: 15)
        ]
    }

    func createLoanProduct(_ product: LoanProduct) async throws -> LoanProduct {
        try await Task.sleep(for: .milliseconds(200))
        return product
    }

    func updateLoanProduct(_ product: LoanProduct) async throws -> LoanProduct {
        try await Task.sleep(for: .milliseconds(200))
        return product
    }
    
    func deleteLoanProduct(id: UUID) async throws {
        try await Task.sleep(for: .milliseconds(200))
    }

    func createApplication(productID: UUID, requestedAmount: Decimal, tenureMonths: Int) async throws -> LoanApplication {
        try await Task.sleep(for: .milliseconds(400))
        let app = LoanApplication(
            borrowerID: borrowerID,
            loanType: .personal,
            requestedAmount: requestedAmount,
            tenureMonths: tenureMonths,
            interestRate: 10.5,
            status: .submitted
        )
        applications.append(app)
        return app
    }

    func submitApplication(id: UUID) async throws -> LoanApplication {
        try await Task.sleep(for: .milliseconds(300))
                        guard let idx = applications.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "Loan", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Application not found."])
        }
        applications[idx].status = .submitted
        applications[idx].updatedAt = .now
        return applications[idx]
    }

    func fetchApplications(for borrowerID: UUID) async throws -> [LoanApplication] {
        try await Task.sleep(for: .milliseconds(200))
                        return applications
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchAssignedApplications(officerID: UUID) async throws -> [LoanApplication] {
        try await Task.sleep(for: .milliseconds(200))
                        return applications
            .filter { $0.assignedOfficerID == officerID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchApplications(statuses: [String]) async throws -> [LoanApplication] {
        try await Task.sleep(for: .milliseconds(200))
        let wanted = Set(statuses)
        return applications.filter { app in
            switch app.status {
            case .escalated: return wanted.contains("manager_review")
            case .underReview: return wanted.contains("under_review")
            case .approved: return wanted.contains("approved")
            case .rejected: return wanted.contains("rejected")
            case .disbursed: return wanted.contains("disbursed")
            default: return false
            }
        }
    }

    func updateStatus(applicationID: UUID, to status: ApplicationStatus, note: String?) async throws {
        try await Task.sleep(for: .milliseconds(200))
                        guard let idx = applications.firstIndex(where: { $0.id == applicationID }) else { return }
        applications[idx].status = status
        applications[idx].updatedAt = .now
    }

    func fetchActiveLoans(borrowerID: UUID) async throws -> [Loan] {
        try await Task.sleep(for: .milliseconds(200))
                        return loans
    }

    func fetchEMISchedule(loanID: UUID) async throws -> [EMI] {
        try await Task.sleep(for: .milliseconds(200))
                        return loans.first(where: { $0.id == loanID })?.emiSchedule ?? []
    }

    func payEMI(emiID: UUID) async throws -> EMI {
        try await Task.sleep(for: .milliseconds(400))
        for loanIdx in loans.indices {
            if let emiIdx = loans[loanIdx].emiSchedule.firstIndex(where: { $0.id == emiID }) {
                loans[loanIdx].emiSchedule[emiIdx].status = .paid
                loans[loanIdx].emiSchedule[emiIdx].paidAt = .now
                return loans[loanIdx].emiSchedule[emiIdx]
            }
        }
        throw NSError(domain: "Loan", code: 404, userInfo: [NSLocalizedDescriptionKey: "EMI not found"])
    }

    func startReview(applicationID: UUID) async throws {
        try await Task.sleep(for: .milliseconds(200))
        guard let idx = applications.firstIndex(where: { $0.id == applicationID }) else { return }
        applications[idx].status = .underReview
        applications[idx].updatedAt = .now
    }

    func requestDocuments(applicationID: UUID, documentTypes: [String], remark: String?) async throws {
        try await Task.sleep(for: .milliseconds(200))
        guard let idx = applications.firstIndex(where: { $0.id == applicationID }) else { return }
        applications[idx].status = .additionalInfoRequired
        applications[idx].updatedAt = .now
    }

    func documentsUploaded(applicationID: UUID, documentIDs: [UUID]) async throws {
        try await Task.sleep(for: .milliseconds(200))
        guard let idx = applications.firstIndex(where: { $0.id == applicationID }) else { return }
        applications[idx].status = .underReview
        applications[idx].updatedAt = .now
    }

    func sendToManager(applicationID: UUID, remark: String?) async throws {
        try await Task.sleep(for: .milliseconds(200))
        guard let idx = applications.firstIndex(where: { $0.id == applicationID }) else { return }
        applications[idx].status = .escalated
        applications[idx].updatedAt = .now
    }

    func approveApplication(applicationID: UUID, remark: String?) async throws {
        try await Task.sleep(for: .milliseconds(200))
        guard let idx = applications.firstIndex(where: { $0.id == applicationID }) else { return }
        applications[idx].status = .approved
        applications[idx].updatedAt = .now
    }

    func rejectApplication(applicationID: UUID, remark: String?) async throws {
        try await Task.sleep(for: .milliseconds(200))
        guard let idx = applications.firstIndex(where: { $0.id == applicationID }) else { return }
        applications[idx].status = .rejected
        applications[idx].updatedAt = .now
    }

    func disburseLoan(applicationID: UUID) async throws {
        try await Task.sleep(for: .milliseconds(200))
        guard let idx = applications.firstIndex(where: { $0.id == applicationID }) else { return }
        applications[idx].status = .disbursed
        applications[idx].updatedAt = .now
    }

    func fetchApplicationDetails(applicationID: UUID) async throws -> LoanApplication {
        try await Task.sleep(for: .milliseconds(200))
        guard let app = applications.first(where: { $0.id == applicationID }) else {
            throw NSError(domain: "Loan", code: 404, userInfo: [NSLocalizedDescriptionKey: "Application not found"])
        }
        return app
    }

    func fetchApplicationEvents(applicationID: UUID) async throws -> [ApplicationEvent] {
        try await Task.sleep(for: .milliseconds(200))
        return []
    }
}
