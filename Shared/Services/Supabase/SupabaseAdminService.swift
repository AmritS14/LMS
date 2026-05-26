import Foundation
import Supabase

actor SupabaseAdminService: AdminService {
    private let client: SupabaseClient
    private let apiBase = "https://arshitsinghal-lms-backend.hf.space"

    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    // MARK: - DB models

    private struct DBUser: Decodable {
        let id: UUID
        let full_name: String?
        let email: String?
        let phone: String?
        let role: String?
        let is_active: Bool?
        let created_at: Date?
    }

    private struct DBStaffProfile: Decodable {
        let id: UUID
        let employee_id: String?
        let branch_id: UUID?
        let department: String?
        let reports_to_id: UUID?
    }

    private func mapRole(_ raw: String?) -> UserRole {
        switch (raw ?? "").lowercased() {
        case "loan_officer", "loanofficer": return .loanOfficer
        case "manager": return .manager
        case "admin": return .admin
        default: return .borrower
        }
    }

    private func backendRole(_ role: UserRole) -> String {
        switch role {
        case .loanOfficer: return "loan_officer"
        case .manager: return "manager"
        case .admin: return "admin"
        case .borrower: return "borrower"
        }
    }

    // MARK: - AdminService

    func listUsers() async throws -> [User] {
        let response = try await client
            .from("users")
            .select("id, full_name, email, phone, role, is_active, created_at")
            .order("created_at", ascending: true)
            .execute()

        let dbUsers = try SupabaseManager.shared.decoder.decode([DBUser].self, from: response.data)
        return dbUsers.map { db in
            User(
                id: db.id,
                fullName: (db.full_name?.isEmpty == false ? db.full_name! : "—"),
                email: db.email ?? "",
                phone: db.phone ?? "",
                role: mapRole(db.role),
                isActive: db.is_active ?? true,
                createdAt: db.created_at ?? .now
            )
        }
    }

    func listStaffProfiles() async throws -> [StaffProfile] {
        let response = try await client
            .from("staff_profiles")
            .select("id, employee_id, branch_id, department, reports_to_id")
            .execute()

        let dbProfiles = try SupabaseManager.shared.decoder.decode([DBStaffProfile].self, from: response.data)
        return dbProfiles.map { db in
            StaffProfile(
                id: db.id,
                employeeID: db.employee_id ?? "—",
                branchID: db.branch_id,
                department: db.department,
                reportsToID: db.reports_to_id,
                permissions: []
            )
        }
    }

    func createStaff(
        email: String,
        fullName: String,
        role: UserRole,
        employeeID: String,
        temporaryPassword: String
    ) async throws -> UUID {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let url = URL(string: "\(apiBase)/admin/staff")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "email": email,
            "fullName": fullName,
            "role": backendRole(role),
            "employeeId": employeeID,
            "temporaryPassword": temporaryPassword
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        if let httpRes = httpResponse as? HTTPURLResponse, !(200...299).contains(httpRes.statusCode) {
            let errorStr = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "API", code: httpRes.statusCode, userInfo: [NSLocalizedDescriptionKey: "Create staff failed: \(errorStr)"])
        }

        struct CreateStaffResponse: Decodable { let userId: UUID? }
        if let decoded = try? JSONDecoder().decode(CreateStaffResponse.self, from: data), let id = decoded.userId {
            return id
        }
        return UUID()
    }

    func updateUserRole(userID: UUID, role: UserRole) async throws {
        try await client
            .from("users")
            .update(["role": backendRole(role)])
            .eq("id", value: userID)
            .execute()
    }

    func setUserActive(userID: UUID, isActive: Bool) async throws {
        try await client
            .from("users")
            .update(["is_active": isActive])
            .eq("id", value: userID)
            .execute()
    }
}
