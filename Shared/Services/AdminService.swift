import Foundation

protocol AdminService: Sendable {
    /// All users in the system (admin-only; gated by RLS).
    func listUsers() async throws -> [User]
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
    /// Admin-only: change a user's system role. Persisted via Supabase under
    /// the "Admins update users" RLS policy.
    func updateUserRole(userID: UUID, role: UserRole) async throws
    /// Admin-only: activate or deactivate a user account (soft enable/disable;
    /// accounts are never hard-deleted to preserve referential integrity).
    func setUserActive(userID: UUID, isActive: Bool) async throws
}

protocol ReportingService: Sendable {
    func portfolioSummary(branchID: UUID?) async throws -> PortfolioSummary
    func exportReport(kind: ReportKind, range: DateInterval, format: ReportFormat) async throws -> URL
}
