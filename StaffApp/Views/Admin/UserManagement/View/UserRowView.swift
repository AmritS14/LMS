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

    // Fetch the updated user state from viewModel to react to toggle changes
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
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                switch currentUser.role {
                case .borrower:
                    borrowerProfileView
                case .loanOfficer:
                    loanOfficerProfileView
                case .manager:
                    managerProfileView
                case .admin:
                    adminProfileView
                }
            }
            .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
            .padding(.vertical, AdminSpacing.cardRowHorizontalInset)
        }
        .background(AdminColor.background)
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
            "Are you sure you want to delete this account?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                Task {
                    await viewModel.deleteUser(for: user.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Shared Management Card View Helper

    private var manageAccountCard: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            SectionHeaderView(title: "Manage Account", systemImage: "gearshape")
            
            VStack(spacing: Spacing.s) {
                Toggle(isOn: Binding(
                    get: { currentUser.isActive },
                    set: { _ in
                        Task {
                            await viewModel.toggleUserStatus(for: currentUser.id)
                        }
                    }
                )) {
                    Text("Active Status")
                        .font(.lmsSubheadline)
                        .foregroundStyle(.secondary)
                }
                .tint(AdminColor.accent)
                
                Divider()
                
                HStack {
                    Text("System Role")
                        .font(.lmsSubheadline)
                        .foregroundStyle(.secondary)
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
                    .tint(AdminColor.accent)
                }
                
                Divider()
                
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Text("Delete Account")
                            .font(.lmsSubheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                        Spacer()
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(AdminSpacing.cardPadding)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
    }

    // MARK: - Role-Specific Views

    /// Borrower Admin View: Displays assigned staff and complete loan/payment history
    private var borrowerProfileView: some View {
        VStack(spacing: AdminSpacing.sectionGap) {
            // Card 0: Account Details
            VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                SectionHeaderView(title: "Account Details", systemImage: "info.circle")
                
                VStack(spacing: Spacing.s) {
                    KeyValueRow(key: "User ID", value: currentUser.uniqueID)
                    Divider()
                    KeyValueRow(key: "Email", value: currentUser.email)
                    Divider()
                    KeyValueRow(key: "Phone", value: currentUser.phone)
                }
                .padding(AdminSpacing.cardPadding)
                .background(
                    AdminColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }

            // Card 1: Assigned Staff
            VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                SectionHeaderView(title: "Assigned Staff", systemImage: "person.2")
                
                VStack(spacing: Spacing.s) {
                    if let officer = viewModel.getAssignedOfficer(for: currentUser.id) {
                        NavigationKeyValueRow(key: "Loan Officer", value: officer.fullName, destinationUser: officer, viewModel: viewModel)
                        
                        Divider()
                        
                        if let manager = viewModel.getSupervisingManager(for: officer.id) {
                            NavigationKeyValueRow(key: "Manager", value: manager.fullName, destinationUser: manager, viewModel: viewModel)
                        } else {
                            KeyValueRow(key: "Manager", value: "None")
                        }
                    } else {
                        KeyValueRow(key: "Loan Officer", value: "Unassigned")
                        Divider()
                        KeyValueRow(key: "Manager", value: "None")
                    }
                }
                .padding(AdminSpacing.cardPadding)
                .background(
                    AdminColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }

            // Card 3: Loan Stats
            let history = viewModel.getLoanHistory(for: currentUser.id)
            VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                SectionHeaderView(title: "Loan Summary", systemImage: "doc.text")
                
                VStack(spacing: Spacing.s) {
                    KeyValueRow(key: "Total Loans Taken", value: "\(history.count)")
                    Divider()
                    KeyValueRow(key: "Active Loans", value: "\(history.filter { $0.outstandingBalance > 0 }.count)")
                }
                .padding(AdminSpacing.cardPadding)
                .background(
                    AdminColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }

            // Loan List Cards
            if !history.isEmpty {
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Loan Records", systemImage: "list.bullet")
                    
                    ForEach(history) { loan in
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            HStack {
                                Text(loan.disbursementDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.lmsHeadline)
                                Spacer()
                                StatusBadge(
                                    loan.outstandingBalance == 0 ? "Fully Paid" : "Active",
                                    tone: loan.outstandingBalance == 0 ? .success : .warning
                                )
                            }
                            
                            Divider()
                            
                            KeyValueRow(key: "Principal Amount", value: "₹\(loan.principal.formatted())")
                            KeyValueRow(key: "Interest Rate", value: "\(loan.interestRate)% p.a.")
                            KeyValueRow(key: "Outstanding", value: "₹\(loan.outstandingBalance.formatted())")
                            
                            Divider()
                            
                            Text("Repayment Behavior")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            ForEach(loan.emiSchedule) { emi in
                                HStack {
                                    Text("Installment \(emi.installmentNumber)")
                                        .font(.lmsSubheadline)
                                    Spacer()
                                    Text(emi.status == .paid ? "Paid" : "Overdue")
                                        .font(.lmsCaption)
                                        .foregroundStyle(emi.status == .paid ? .green : .red)
                                }
                                .padding(.leading, 8)
                            }
                        }
                        .padding(AdminSpacing.cardPadding)
                        .background(
                            AdminColor.cardBackground,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                    }
                }
            }
        }
    }

    /// Loan Officer Admin View: Handles status, reportsTo lookups, delete/deactivate options, and assigned borrowers list
    private var loanOfficerProfileView: some View {
        VStack(spacing: AdminSpacing.sectionGap) {
            // Card 1: Info & Management
            VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                SectionHeaderView(title: "Account Details", systemImage: "info.circle")
                
                VStack(spacing: Spacing.s) {
                    KeyValueRow(key: "User ID", value: currentUser.uniqueID)
                    Divider()
                    KeyValueRow(key: "Email", value: currentUser.email)
                    Divider()
                    KeyValueRow(key: "Phone", value: currentUser.phone)
                }
                .padding(AdminSpacing.cardPadding)
                .background(
                    AdminColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }

            // Card 2: Assigned Borrowers
            let borrowers = viewModel.getBorrowers(for: currentUser.id)
            VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                SectionHeaderView(title: "Assigned Borrowers", systemImage: "person.2")
                
                VStack(spacing: Spacing.s) {
                    if borrowers.isEmpty {
                        Text("No borrowers assigned to this officer.")
                            .font(.lmsSubheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
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
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            if borrower.id != borrowers.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .padding(AdminSpacing.cardPadding)
                .background(
                    AdminColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }

            // Card 3: Supervising Manager
            VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                SectionHeaderView(title: "Supervisor", systemImage: "person.badge.shield")
                
                VStack(spacing: Spacing.s) {
                    if let manager = viewModel.getSupervisingManager(for: currentUser.id) {
                        NavigationKeyValueRow(key: "Reports To", value: manager.fullName, destinationUser: manager, viewModel: viewModel)
                    } else {
                        KeyValueRow(key: "Reports To", value: "No Manager Assigned")
                    }
                }
                .padding(AdminSpacing.cardPadding)
                .background(
                    AdminColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }

            // Card 4: Manage Account
            manageAccountCard
        }
    }

    /// Manager Admin View: Displays reports, permissions management, and supervising staff list
    private var managerProfileView: some View {
        VStack(spacing: AdminSpacing.sectionGap) {
            // Card 1: Details
            VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                SectionHeaderView(title: "Manager Details", systemImage: "info.circle")
                
                VStack(spacing: Spacing.s) {
                    KeyValueRow(key: "User ID", value: currentUser.uniqueID)
                    Divider()
                    KeyValueRow(key: "Email", value: currentUser.email)
                    Divider()
                    KeyValueRow(key: "Phone", value: currentUser.phone)
                }
                .padding(AdminSpacing.cardPadding)
                .background(
                    AdminColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }

            // Card 2: Supervised Loan Officers
            let officers = viewModel.getLoanOfficers(for: currentUser.id)
            VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                SectionHeaderView(title: "Supervised Officers", systemImage: "person.2")
                
                VStack(spacing: Spacing.s) {
                    if officers.isEmpty {
                        Text("No officers reporting to this manager.")
                            .font(.lmsSubheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
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
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            if officer.id != officers.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .padding(AdminSpacing.cardPadding)
                .background(
                    AdminColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }

            // Card 3: Permissions Configuration
            VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                SectionHeaderView(title: "Permissions", systemImage: "lock.shield")
                
                VStack(spacing: Spacing.s) {
                    ForEach(Permission.allCases) { permission in
                        Toggle(isOn: permissionBinding(for: permission)) {
                            Text(permission.rawValue)
                                .font(.lmsSubheadline)
                        }
                        .tint(AdminColor.accent)
                        
                        if permission.id != Permission.allCases.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(AdminSpacing.cardPadding)
                .background(
                    AdminColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }

            // Card 4: Manage Account
            manageAccountCard
        }
    }

    /// Admin Profile View
    private var adminProfileView: some View {
        VStack(spacing: AdminSpacing.sectionGap) {
            VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                SectionHeaderView(title: "Admin Account Details", systemImage: "info.circle")
                
                VStack(spacing: Spacing.s) {
                    KeyValueRow(key: "User ID", value: currentUser.uniqueID)
                    Divider()
                    KeyValueRow(key: "Email", value: currentUser.email)
                    Divider()
                    KeyValueRow(key: "Phone", value: currentUser.phone)
                }
                .padding(AdminSpacing.cardPadding)
                .background(
                    AdminColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
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
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
