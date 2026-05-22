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

    // Relationships
    var borrowerToOfficer: [UUID: UUID] = [:]
    var borrowerLoans: [UUID: [Loan]] = [:]

    init() {
        // MARK: - 1. Admins
        let admin1 = User(fullName: "Aarav Mehta", email: "aarav.mehta@lms.com", phone: "+91 98657 87368", role: .admin, isActive: true)
        let admin2 = User(fullName: "Devendra Kumar", email: "devendra.kumar@lms.com", phone: "+91 91234 56789", role: .admin, isActive: true)
        let admin3 = User(fullName: "Shalini Iyer", email: "shalini.iyer@lms.com", phone: "+91 93456 78901", role: .admin, isActive: true)
        let admin4 = User(fullName: "Rajesh Gupta", email: "rajesh.gupta@lms.com", phone: "+91 94567 89012", role: .admin, isActive: true)

        // MARK: - 2. Managers
        let manager1 = User(fullName: "Priya Sharma", email: "priya.sharma@lms.com", phone: "+91 98765 43210", role: .manager, isActive: true)
        let manager2 = User(fullName: "Vikram Malhotra", email: "vikram.malhotra@lms.com", phone: "+91 98123 45678", role: .manager, isActive: true)
        let manager3 = User(fullName: "Kavita Joshi", email: "kavita.joshi@lms.com", phone: "+91 95432 10987", role: .manager, isActive: true)
        let manager4 = User(fullName: "Amit Singhania", email: "amit.singhania@lms.com", phone: "+91 96543 21098", role: .manager, isActive: true)

        // MARK: - 3. Loan Officers
        let officer1 = User(fullName: "Sneha Patel", email: "sneha.patel@lms.com", phone: "+91 97654 32109", role: .loanOfficer, isActive: true)
        let officer2 = User(fullName: "Rahul Nair", email: "rahul.nair@lms.com", phone: "+91 99123 88776", role: .loanOfficer, isActive: true)
        let officer3 = User(fullName: "Divya Sen", email: "divya.sen@lms.com", phone: "+91 90876 54321", role: .loanOfficer, isActive: true)
        let officer4 = User(fullName: "Sandeep Bansal", email: "sandeep.bansal@lms.com", phone: "+91 91765 43210", role: .loanOfficer, isActive: true)

        // MARK: - 4. Borrowers
        let borrower1 = User(fullName: "Rohan Verma", email: "rohan.verma@lms.com", phone: "+91 98761 23456", role: .borrower, isActive: true)
        let borrower2 = User(fullName: "Neha Kapoor", email: "neha.kapoor@gmail.com", phone: "+91 98112 23344", role: .borrower, isActive: true)
        let borrower3 = User(fullName: "Arjun Ranade", email: "arjun.ranade@yahoo.com", phone: "+91 92345 67890", role: .borrower, isActive: true)
        let borrower4 = User(fullName: "Anjali Nair", email: "anjali.nair@outlook.com", phone: "+91 93210 98765", role: .borrower, isActive: true)
        let borrower5 = User(fullName: "Manish Chawla", email: "manish.chawla@gmail.com", phone: "+91 94123 45678", role: .borrower, isActive: true)

        self.users = [
            admin1, manager2, officer1, borrower4,
            admin3, manager1, officer3, borrower2,
            admin2, manager4, officer2, borrower5,
            admin4, manager3, officer4, borrower3,
            borrower1
        ]

        // MARK: - 5. Staff Profiles & Permissions
        var profiles: [UUID: StaffProfile] = [:]
        
        // Admins
        profiles[admin1.id] = StaffProfile(id: admin1.id, employeeID: "EMP-101", permissions: Set(Permission.allCases))
        profiles[admin2.id] = StaffProfile(id: admin2.id, employeeID: "EMP-102", permissions: Set(Permission.allCases))
        profiles[admin3.id] = StaffProfile(id: admin3.id, employeeID: "EMP-103", permissions: Set(Permission.allCases))
        profiles[admin4.id] = StaffProfile(id: admin4.id, employeeID: "EMP-104", permissions: Set(Permission.allCases))
        
        // Managers
        profiles[manager1.id] = StaffProfile(id: manager1.id, employeeID: "EMP-201", permissions: [.processLoans, .manageLoans])
        profiles[manager2.id] = StaffProfile(id: manager2.id, employeeID: "EMP-202", permissions: [.processLoans, .manageLoans])
        profiles[manager3.id] = StaffProfile(id: manager3.id, employeeID: "EMP-203", permissions: [.processLoans])
        profiles[manager4.id] = StaffProfile(id: manager4.id, employeeID: "EMP-204", permissions: [.manageLoans])
        
        // Loan Officers reporting to Managers
        profiles[officer1.id] = StaffProfile(id: officer1.id, employeeID: "EMP-301", reportsToID: manager1.id, permissions: [.processLoans])
        profiles[officer2.id] = StaffProfile(id: officer2.id, employeeID: "EMP-302", reportsToID: manager1.id, permissions: [.processLoans])
        profiles[officer3.id] = StaffProfile(id: officer3.id, employeeID: "EMP-303", reportsToID: manager2.id, permissions: [.processLoans])
        profiles[officer4.id] = StaffProfile(id: officer4.id, employeeID: "EMP-304", reportsToID: manager3.id, permissions: [.processLoans])
        
        self.staffProfiles = profiles

        // MARK: - 6. Assignments (Borrowers to Loan Officers)
        self.borrowerToOfficer[borrower1.id] = officer1.id
        self.borrowerToOfficer[borrower2.id] = officer1.id
        self.borrowerToOfficer[borrower3.id] = officer2.id
        self.borrowerToOfficer[borrower4.id] = officer3.id
        self.borrowerToOfficer[borrower5.id] = officer4.id

        // MARK: - 7. Loan History & Schedules
        let calendar = Calendar.current
        let date1 = calendar.date(byAdding: .month, value: -12, to: Date()) ?? Date()
        let date2 = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()

        // Rohan Verma Loans
        let loanR1 = Loan(
            id: UUID(), applicationID: UUID(), borrowerID: borrower1.id,
            principal: 500000, interestRate: 10.5, tenureMonths: 12, disbursementDate: date1,
            outstandingBalance: 0,
            emiSchedule: [
                EMI(installmentNumber: 1, dueDate: date1, principalComponent: 40000, interestComponent: 4000, totalAmount: 44000, status: .paid, paidAt: date1),
                EMI(installmentNumber: 2, dueDate: date1, principalComponent: 40000, interestComponent: 4000, totalAmount: 44000, status: .paid, paidAt: date1)
            ]
        )
        let loanR2 = Loan(
            id: UUID(), applicationID: UUID(), borrowerID: borrower1.id,
            principal: 200000, interestRate: 9.75, tenureMonths: 6, disbursementDate: date2,
            outstandingBalance: 120000,
            emiSchedule: [
                EMI(installmentNumber: 1, dueDate: date2, principalComponent: 30000, interestComponent: 2000, totalAmount: 32000, status: .paid, paidAt: date2),
                EMI(installmentNumber: 2, dueDate: date2, principalComponent: 30000, interestComponent: 2000, totalAmount: 32000, status: .overdue, paidAt: nil)
            ]
        )
        self.borrowerLoans[borrower1.id] = [loanR1, loanR2]

        // Neha Kapoor Loan
        let loanN1 = Loan(
            id: UUID(), applicationID: UUID(), borrowerID: borrower2.id,
            principal: 350000, interestRate: 8.5, tenureMonths: 24, disbursementDate: date2,
            outstandingBalance: 310000,
            emiSchedule: [
                EMI(installmentNumber: 1, dueDate: date2, principalComponent: 15000, interestComponent: 2500, totalAmount: 17500, status: .paid, paidAt: date2)
            ]
        )
        self.borrowerLoans[borrower2.id] = [loanN1]

        // Arjun Ranade Loan
        let loanAr1 = Loan(
            id: UUID(), applicationID: UUID(), borrowerID: borrower3.id,
            principal: 150000, interestRate: 12.0, tenureMonths: 12, disbursementDate: date1,
            outstandingBalance: 0,
            emiSchedule: [
                EMI(installmentNumber: 1, dueDate: date1, principalComponent: 12500, interestComponent: 1500, totalAmount: 14000, status: .paid, paidAt: date1)
            ]
        )
        self.borrowerLoans[borrower3.id] = [loanAr1]

        // Anjali Nair Loans
        let loanAn1 = Loan(
            id: UUID(), applicationID: UUID(), borrowerID: borrower4.id,
            principal: 80000, interestRate: 11.0, tenureMonths: 6, disbursementDate: date1,
            outstandingBalance: 0,
            emiSchedule: [
                EMI(installmentNumber: 1, dueDate: date1, principalComponent: 13000, interestComponent: 700, totalAmount: 13700, status: .paid, paidAt: date1)
            ]
        )
        self.borrowerLoans[borrower4.id] = [loanAn1]
        
        // borrower5 (Manish Chawla) stays at 0 loans for new status simulation.
    }

    // Relationship Helpers
    func getSupervisingManager(for officerID: UUID) -> User? {
        guard let managerID = staffProfiles[officerID]?.reportsToID else { return nil }
        return users.first { $0.id == managerID }
    }

    func getBorrowers(for officerID: UUID) -> [User] {
        let borrowerIDs = borrowerToOfficer.filter { $0.value == officerID }.map { $0.key }
        return users.filter { borrowerIDs.contains($0.id) }
    }

    func getLoanOfficers(for managerID: UUID) -> [User] {
        let officerIDs = staffProfiles.filter { $0.value.reportsToID == managerID }.map { $0.key }
        return users.filter { officerIDs.contains($0.id) }
    }

    func getAssignedOfficer(for borrowerID: UUID) -> User? {
        guard let officerID = borrowerToOfficer[borrowerID] else { return nil }
        return users.first { $0.id == officerID }
    }

    func getLoanHistory(for borrowerID: UUID) -> [Loan] {
        return borrowerLoans[borrowerID] ?? []
    }

    // Actions
    func deleteUser(for userID: UUID) async {
        try? await Task.sleep(for: .milliseconds(200))
        guard let index = users.firstIndex(where: { $0.id == userID }) else { return }
        let userName = users[index].fullName
        users.remove(at: index)
        staffProfiles.removeValue(forKey: userID)
        borrowerToOfficer.removeValue(forKey: userID)
        borrowerLoans.removeValue(forKey: userID)
        
        AuditLogger.log(action: "User Deleted", details: "Deleted user profile: \(userName)")
        successMessage = "\(userName)'s account has been successfully deleted."
        showSuccessAlert = true
    }

    func toggleUserStatus(for userID: UUID) async {
        try? await Task.sleep(for: .milliseconds(200))
        guard let index = users.firstIndex(where: { $0.id == userID }) else { return }
        users[index].isActive.toggle()
        let state = users[index].isActive ? "Activated" : "Deactivated"
        
        AuditLogger.log(action: "User Status Changed", details: "User \(users[index].fullName) set to \(state)")
        successMessage = "\(users[index].fullName) status set to \(state.lowercased())."
        showSuccessAlert = true
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
}
