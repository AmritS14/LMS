//
//  UserRowView.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI

// MARK: - Reusable User Row Component

struct UserRowView: View {
    let user: User
    let profile: StaffProfile?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            initialsAvatar
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(user.fullName)
                    .font(.lmsHeadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(user.email)
                    .font(.lmsCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(user.phone)
                    .font(.lmsCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(user.uniqueID)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .padding(AdminSpacing.cardPadding)
        .background(
            AdminColor.cardBackground,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var initialsAvatar: some View {
        let initials = user.fullName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()

        return Text(initials)
            .font(.system(.callout, design: .default, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(avatarColor.gradient, in: Circle())
    }

    private var avatarColor: Color {
        switch user.role {
        case .admin: return .indigo
        case .manager: return .orange
        case .loanOfficer: return .teal
        case .borrower: return .cyan
        }
    }
}

// MARK: - User Details View (Editing)

struct UserDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: UserManagementViewModel
    let user: User

    @State private var showDeleteConfirmation = false

    private var currentUser: User {
        viewModel.users.first { $0.id == user.id } ?? user
    }

    private var allowedRoles: [UserRole] {
        switch currentUser.role {
        case .loanOfficer:
            return [.loanOfficer, .manager, .admin]
        case .manager:
            return [.manager, .admin]
        default:
            return [currentUser.role]
        }
    }

    var body: some View {
        List {
            switch currentUser.role {
            case .borrower:
                borrowerSections
            case .loanOfficer:
                loanOfficerSections
            case .manager:
                managerSections
            case .admin:
                adminSections
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(currentUser.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK", role: .cancel) {
                if !viewModel.users.contains(where: { $0.id == user.id }) {
                    dismiss()
                }
            }
        } message: {
            Text(viewModel.successMessage)
        }
        .confirmationDialog(
            "Deactivate this account? They will lose access until reactivated. Accounts are never permanently deleted, to keep loan records intact.",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Deactivate Account", role: .destructive) {
                Task {
                    await viewModel.deleteUser(for: user.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Shared Manage Account Section

    @ViewBuilder
    private var manageAccountSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { currentUser.isActive },
                set: { _ in
                    Task {
                        await viewModel.toggleUserStatus(for: currentUser.id)
                    }
                }
            )) {
                Text("Active Status")
            }
            .tint(.blue)
            
            HStack {
                Text("System Role")
                Spacer()
                Picker("Role", selection: Binding(
                    get: { currentUser.role },
                    set: { newRole in
                        Task {
                            await viewModel.updateRole(for: currentUser.id, to: newRole)
                        }
                    }
                )) {
                    ForEach(allowedRoles, id: \.self) { role in
                        Text(role.displayName).tag(role)
                    }
                }
                .pickerStyle(.menu)
                .tint(.blue)
            }
            
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Text("Deactivate Account")
            }
        } header: {
            Text("Manage Account").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
        }
    }

    // MARK: - Borrower Sections

    @ViewBuilder
    private var borrowerSections: some View {
        Section {
            KeyValueRow(key: "User ID", value: currentUser.uniqueID)
            KeyValueRow(key: "Email", value: currentUser.email)
            KeyValueRow(key: "Phone", value: currentUser.phone)
        } header: {
            Text("Account Details").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
        }

        Section {
            if let officer = viewModel.getAssignedOfficer(for: currentUser.id) {
                NavigationKeyValueRow(key: "Loan Officer", value: officer.fullName, destinationUser: officer, viewModel: viewModel)
                if let manager = viewModel.getSupervisingManager(for: officer.id) {
                    NavigationKeyValueRow(key: "Manager", value: manager.fullName, destinationUser: manager, viewModel: viewModel)
                } else {
                    KeyValueRow(key: "Manager", value: "None")
                }
            } else {
                KeyValueRow(key: "Loan Officer", value: "Unassigned")
                KeyValueRow(key: "Manager", value: "None")
            }
        } header: {
            Text("Assigned Staff").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
        }

        let history = viewModel.getLoanHistory(for: currentUser.id)
        Section {
            KeyValueRow(key: "Total Loans Taken", value: "\(history.count)")
            KeyValueRow(key: "Active Loans", value: "\(history.filter { $0.outstandingBalance > 0 }.count)")
        } header: {
            Text("Loan Summary").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
        }

        if !history.isEmpty {
            ForEach(history) { loan in
                Section {
                    HStack {
                        Text(loan.disbursementDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.lmsHeadline)
                        Spacer()
                        StatusBadge(
                            loan.outstandingBalance == 0 ? "Fully Paid" : "Active",
                            tone: loan.outstandingBalance == 0 ? .success : .warning
                        )
                    }
                    KeyValueRow(key: "Principal Amount", value: "₹\(loan.principal.formatted())")
                    KeyValueRow(key: "Interest Rate", value: "\(loan.interestRate)% p.a.")
                    KeyValueRow(key: "Outstanding", value: "₹\(loan.outstandingBalance.formatted())")
                    
                    ForEach(loan.emiSchedule) { emi in
                        HStack {
                            Text("Installment \(emi.installmentNumber)")
                                .font(.lmsSubheadline)
                            Spacer()
                            Text(emi.status == .paid ? "Paid" : "Overdue")
                                .font(.lmsCaption)
                                .foregroundStyle(emi.status == .paid ? .green : .red)
                        }
                    }
                } header: {
                    Text("Loan Record").font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary).textCase(nil)
                }
            }
        }
    }

    // MARK: - Loan Officer Sections

    @ViewBuilder
    private var loanOfficerSections: some View {
        Section {
            KeyValueRow(key: "User ID", value: currentUser.uniqueID)
            KeyValueRow(key: "Email", value: currentUser.email)
            KeyValueRow(key: "Phone", value: currentUser.phone)
        } header: {
            Text("Account Details").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
        }

        let borrowers = viewModel.getBorrowers(for: currentUser.id)
        Section {
            if borrowers.isEmpty {
                Text("No borrowers assigned to this officer.")
                    .font(.lmsSubheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(borrowers) { borrower in
                    NavigationLink(destination: UserDetailsView(viewModel: viewModel, user: borrower)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(borrower.fullName)
                                    .font(.lmsHeadline)
                                    .foregroundStyle(.primary)
                                Text(borrower.uniqueID)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(borrower.email)
                                .font(.lmsCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } header: {
            Text("Assigned Borrowers").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
        }

        Section {
            if let manager = viewModel.getSupervisingManager(for: currentUser.id) {
                NavigationKeyValueRow(key: "Reports To", value: manager.fullName, destinationUser: manager, viewModel: viewModel)
            } else {
                KeyValueRow(key: "Reports To", value: "No Manager Assigned")
            }
        } header: {
            Text("Supervisor").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
        }

        manageAccountSection
    }

    // MARK: - Manager Sections

    @ViewBuilder
    private var managerSections: some View {
        Section {
            KeyValueRow(key: "User ID", value: currentUser.uniqueID)
            KeyValueRow(key: "Email", value: currentUser.email)
            KeyValueRow(key: "Phone", value: currentUser.phone)
        } header: {
            Text("Manager Details").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
        }

        let officers = viewModel.getLoanOfficers(for: currentUser.id)
        Section {
            if officers.isEmpty {
                Text("No officers reporting to this manager.")
                    .font(.lmsSubheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(officers) { officer in
                    NavigationLink(destination: UserDetailsView(viewModel: viewModel, user: officer)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(officer.fullName)
                                    .font(.lmsHeadline)
                                    .foregroundStyle(.primary)
                                Text(officer.uniqueID)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(officer.email)
                                .font(.lmsCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } header: {
            Text("Supervised Officers").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
        }

        Section {
            ForEach(Permission.allCases) { permission in
                Toggle(isOn: permissionBinding(for: permission)) {
                    Text(permission.rawValue)
                }
                .tint(.blue)
            }
        } header: {
            Text("Permissions").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
        }

        manageAccountSection
    }

    // MARK: - Admin Sections

    @ViewBuilder
    private var adminSections: some View {
        Section {
            KeyValueRow(key: "User ID", value: currentUser.uniqueID)
            KeyValueRow(key: "Email", value: currentUser.email)
            KeyValueRow(key: "Phone", value: currentUser.phone)
        } header: {
            Text("Admin Account Details").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
        }
    }

    // MARK: - Custom Bindings

    private func permissionBinding(for permission: Permission) -> Binding<Bool> {
        let currentPermissions = viewModel.staffProfiles[currentUser.id]?.permissions ?? []
        return Binding(
            get: { currentPermissions.contains(permission) },
            set: { isEnabled in
                var newPermissions = currentPermissions
                if isEnabled {
                    newPermissions.insert(permission)
                } else {
                    newPermissions.remove(permission)
                }
                Task {
                    await viewModel.updatePermissions(for: currentUser.id, to: newPermissions)
                }
            }
        )
    }
}

// MARK: - Reusable Key Value Display Row
struct KeyValueRow: View {
    let key: String
    let value: String

    var body: some View {
        HStack {
            Text(key)
                .font(.lmsSubheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.lmsHeadline)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Tappable Navigation Key Value Row
struct NavigationKeyValueRow: View {
    let key: String
    let value: String
    let destinationUser: User
    @Bindable var viewModel: UserManagementViewModel

    var body: some View {
        NavigationLink(destination: UserDetailsView(viewModel: viewModel, user: destinationUser)) {
            HStack {
                Text(key)
                    .font(.lmsSubheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.lmsHeadline)
                    .foregroundStyle(AdminColor.accent)
            }
        }
    }
}
