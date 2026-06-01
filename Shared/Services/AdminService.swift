import Foundation

protocol AdminService: Sendable {
    /// All users in the system (admin-only; gated by RLS).
    func listUsers(ids: [UUID]?) async throws -> [User]
    /// Staff profiles (employee id, department, reporting line) keyed by user id.
    func listStaffProfiles() async throws -> [StaffProfile]
    /// Creates a staff account (loan officer / manager / admin) via the backend
    /// admin endpoint. Returns the new user's id.
    func createStaff(
        email: String,
        fullName: String,
        role: UserRole,
        employeeID: String,
        temporaryPassword: String
    ) async throws -> UUID
}

protocol ReportingService: Sendable {
    func portfolioSummary(branchID: UUID?) async throws -> PortfolioSummary
    func exportReport(kind: ReportKind, range: DateInterval, format: ReportFormat) async throws -> URL
}
