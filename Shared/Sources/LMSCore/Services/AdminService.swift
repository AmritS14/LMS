import Foundation

public protocol AdminService: Sendable {
    func listUsers(role: UserRole?) async throws -> [User]
    func updateRole(userID: UUID, role: UserRole) async throws
    func deactivateUser(userID: UUID) async throws
    func auditTrail(entityID: UUID?, limit: Int) async throws -> [AuditEntry]
}

public protocol ReportingService: Sendable {
    func portfolioSummary(branchID: UUID?) async throws -> PortfolioSummary
    func exportReport(kind: ReportKind, range: DateInterval, format: ReportFormat) async throws -> URL
}
