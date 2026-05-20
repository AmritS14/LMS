//
//  UserManagementViewModel.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI
import Observation

// MARK: - User Management ViewModel

@Observable
@MainActor
final class UserManagementViewModel {

    enum UserFilter: Equatable {
        case all
        case role(UserRole)
    }

    var users: [User]
    var staffProfiles: [UUID: StaffProfile]
    
    var currentFilter: UserFilter = .all
    var searchText: String = ""

    var showSuccessAlert: Bool = false
    var successMessage: String = ""
    var showConfirmationAlert: Bool = false
    var userToToggle: User?

    var filteredUsers: [User] {
        let baseUsers: [User]
        switch currentFilter {
        case .all: baseUsers = users
        case .role(let r): baseUsers = users.filter { $0.role == r }
        }
        
        guard !searchText.isEmpty else { return baseUsers }
        let query = searchText.lowercased()
        return baseUsers.filter { user in
            user.fullName.lowercased().contains(query) ||
            user.email.lowercased().contains(query) ||
            user.role.rawValue.lowercased().contains(query)
        }
    }

    // Active user counts removed since isActive is removed

    init() {
        // Mock data
        let user1 = User(fullName: "Aarav Mehta", email: "aarav.mehta@lms.com", phone: "+91 98657 87368", role: .admin)
        let user2 = User(fullName: "Priya Sharma", email: "priya.sharma@lms.com", phone: "+91 98657 87368", role: .manager)
        let user3 = User(fullName: "Rohan Verma", email: "rohan.verma@lms.com", phone: "+91 98657 87368", role: .borrower)
        let user4 = User(fullName: "Sneha Patel", email: "sneha.patel@lms.com", phone: "+91 98657 87368", role: .loanOfficer)
        
        self.users = [user1, user2, user3, user4]
        
        var profiles: [UUID: StaffProfile] = [:]
        profiles[user1.id] = StaffProfile(id: user1.id, employeeID: "EMP001", permissions: Set(Permission.allCases))
        profiles[user2.id] = StaffProfile(id: user2.id, employeeID: "EMP002", permissions: [.processLoans, .manageLoans])
        profiles[user4.id] = StaffProfile(id: user4.id, employeeID: "EMP004", permissions: [.processLoans])
        self.staffProfiles = profiles
    }

    func updateRole(for userID: UUID, to newRole: UserRole) async {
        try? await Task.sleep(for: .milliseconds(200))

        guard let index = users.firstIndex(where: { $0.id == userID }) else { return }
        let oldRole = users[index].role
        users[index].role = newRole
        
        if newRole != .borrower {
            if staffProfiles[userID] == nil {
                staffProfiles[userID] = StaffProfile(id: userID, employeeID: "EMP-\(Int.random(in: 100...999))")
            }
            switch newRole {
            case .admin:
                staffProfiles[userID]?.permissions = Set(Permission.allCases)
            case .manager, .loanOfficer:
                staffProfiles[userID]?.permissions = [.processLoans, .manageLoans]
            case .borrower:
                break
            }
        }

        AuditLogger.log(action: "Role Updated", details: "User: \(users[index].fullName), Changed from \(oldRole.rawValue) to \(newRole.rawValue)")

        successMessage = "\(users[index].fullName)'s role changed to \(newRole.rawValue)."
        showSuccessAlert = true
    }
    
    func updatePermissions(for userID: UUID, to newPermissions: Set<Permission>) async {
        try? await Task.sleep(for: .milliseconds(200))

        guard let index = users.firstIndex(where: { $0.id == userID }) else { return }
        staffProfiles[userID]?.permissions = newPermissions

        AuditLogger.log(action: "Permissions Updated", details: "User: \(users[index].fullName), New Permissions: \(newPermissions.map(\.rawValue).joined(separator: ", "))")

        successMessage = "Permissions for \(users[index].fullName) updated successfully."
        showSuccessAlert = true
    }
    
    // Removing confirmToggleUserStatus and executeToggleStatus since isActive was removed
}
