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
    var isResetPending: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            initialsAvatar

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(user.fullName)
                    .font(.adminCardTitle)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(user.email)
                    .font(.adminCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if isResetPending {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "key.fill")
                            .font(.adminCaption)
                        Text("Password Reset Pending")
                            .font(.adminStatus)
                    }
                    .foregroundStyle(Color.lmsWarning)
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, 3)
                    .background(Color.lmsWarning.opacity(0.1), in: Capsule())
                    .padding(.top, Spacing.xxs)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(user.uniqueID)
                    .font(.adminCaption.monospacedDigit())
                    .foregroundStyle(.tertiary)

                roleBadge
            }
        }
        .padding(AdminSpacing.cardPadding)
        .background(
            AdminColor.cardBackground,
            in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
        )
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    private var initialsAvatar: some View {
        let initials = user.fullName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()

        return Text(initials)
            .font(.adminCardTitle)
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(avatarGradient, in: Circle())
            .shadow(color: avatarColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    private var roleBadge: some View {
        Text(user.role.displayName)
            .font(.adminStatus)
            .foregroundStyle(avatarColor)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 2)
            .background(avatarColor.opacity(0.1), in: Capsule())
    }

    private var avatarColor: Color {
        switch user.role {
        case .admin: return Color(hue: 0.72, saturation: 0.55, brightness: 0.6)
        case .manager: return Color(hue: 0.08, saturation: 0.6, brightness: 0.7)
        case .loanOfficer: return Color(hue: 0.5, saturation: 0.5, brightness: 0.6)
        case .borrower: return Color(hue: 0.55, saturation: 0.45, brightness: 0.65)
        }
    }

    private var avatarGradient: LinearGradient {
        LinearGradient(
            colors: [avatarColor, avatarColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - User Details View (Editing)

struct UserDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: UserManagementViewModel
    let user: User

    @State private var showDeleteConfirmation = false
    @State private var showResetConfirmation = false
    @State private var isResetting = false
    @State private var generatedPassword: String? = nil
    @State private var showResetSuccessSheet = false
    @State private var showResetFailureAlert = false
    @State private var resetAttempts = 0

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
        .alert("Reset Password?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                resetPassword()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Account: \(currentUser.fullName)\nRole: \(currentUser.role.displayName)\n\nA temporary password will be generated. The user must change it on next login.")
        }
        .alert("Reset Failed", isPresented: $showResetFailureAlert) {
            Button("Retry") {
                resetPassword()
            }
            Button("Cancel", role: .cancel) {
                resetAttempts = 0
            }
        } message: {
            Text("A network error occurred. Please check your connection and try again.")
        }
        .sheet(isPresented: $showResetSuccessSheet) {
            if let tempPassword = generatedPassword {
                PasswordResetSuccessSheet(temporaryPassword: tempPassword, userName: currentUser.fullName)
            }
        }
    }

    private func resetPassword() {
        isResetting = true

        Task {
            try? await Task.sleep(for: .seconds(1.2))

            await MainActor.run {
                isResetting = false
                if resetAttempts == 0 {
                    resetAttempts += 1
                    showResetFailureAlert = true
                } else {
                    generatedPassword = "LMS-Temp-\(Int.random(in: 100000...999999))"
                    viewModel.usersPendingReset.insert(currentUser.id)
                    showResetSuccessSheet = true
                }
            }
        }
    }

    // MARK: - Shared Manage Account Section

    @ViewBuilder
    private var manageAccountSection: some View {
        Section {
            // Active toggle
            HStack {
                HStack(spacing: Spacing.s) {
                    Image(systemName: currentUser.isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(currentUser.isActive ? Color.lmsSuccess : Color.lmsDanger)
                    Text("Account Status")
                        .font(.adminBody)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { currentUser.isActive },
                    set: { _ in
                        Task {
                            await viewModel.toggleUserStatus(for: currentUser.id)
                        }
                    }
                ))
                .labelsHidden()
                .tint(.lmsSuccess)
            }

            // Role picker
            HStack {
                HStack(spacing: Spacing.s) {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .foregroundStyle(Color.lmsInfo)
                    Text("System Role")
                        .font(.adminBody)
                }
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
                .tint(.lmsInfo)
            }

            // Password Reset
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack {
                    HStack(spacing: Spacing.s) {
                        Image(systemName: "key.fill")
                            .foregroundStyle(Color.lmsWarning)
                        Text("Reset Password")
                            .font(.adminBody)
                    }
                    Spacer()
                    if isResetting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button(viewModel.usersPendingReset.contains(currentUser.id) ? "Reset Again" : "Reset") {
                            showResetConfirmation = true
                        }
                        .font(.adminSecondary)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs_s)
                        .background(Color.lmsWarning.gradient, in: Capsule())
                    }
                }

                if viewModel.usersPendingReset.contains(currentUser.id) {
                    HStack(spacing: Spacing.xs_s) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.adminCaption)
                            .foregroundStyle(Color.lmsWarning)
                        Text("Password change required at next login")
                            .font(.adminCaption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs_s)
                    .background(Color.lmsWarning.opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.small))
                }
            }

            // Delete
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: Spacing.s) {
                    Image(systemName: "trash.fill")
                    Text("Delete Account")
                }
            }
        } header: {
            Text("Manage Account")
                .font(.adminSectionHeader)
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .padding(.leading, 8)
        }
    }

    // MARK: - Borrower Sections

    @ViewBuilder
    private var borrowerSections: some View {
        Section {
            accountDetailRow(label: "User ID", value: currentUser.uniqueID)
            accountDetailRow(label: "Email", value: currentUser.email)
            accountDetailRow(label: "Phone", value: currentUser.phone)
        } header: {
            Text("Account Details")
                .font(.adminSectionHeader)
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .padding(.leading, 8)
        }

        let history = viewModel.getLoanHistory(for: currentUser.id)
        Section {
            accountDetailRow(label: "Total Loans", value: "\(history.count)")
            accountDetailRow(label: "Active Loans", value: "\(history.filter { $0.outstandingBalance > 0 }.count)")
        } header: {
            Text("Loan Summary")
                .font(.adminSectionHeader)
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .padding(.leading, 8)
        }

        Section {
            NavigationLink(destination: ReportsDashboardView(preselectedBorrowerName: currentUser.fullName)) {
                HStack(spacing: Spacing.s) {
                    Text("Borrower Report")
                        .font(.lmsSubheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Report")
                .font(.adminSectionHeader)
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .padding(.leading, 8)
        }

        if !history.isEmpty {
            ForEach(history) { loan in
                Section {
                    HStack {
                        Text(loan.disbursementDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.adminCardTitle)
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
                                .font(.adminSecondary)
                            Spacer()
                            Text(emi.status == .paid ? "Paid" : "Overdue")
                                .font(.adminCaption)
                                .fontWeight(.semibold)
                                .foregroundStyle(emi.status == .paid ? Color.lmsSuccess : Color.lmsDanger)
                        }
                    }
                } header: {
                    Text("Loan Record")
                        .font(.adminSectionHeader)
                        .foregroundStyle(Color.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, 8)
                }
            }
        }
    }

    // MARK: - Loan Officer Sections

    @ViewBuilder
    private var loanOfficerSections: some View {
        Section {
            accountDetailRow(label: "User ID", value: currentUser.uniqueID)
            accountDetailRow(label: "Email", value: currentUser.email)
            accountDetailRow(label: "Phone", value: currentUser.phone)
        } header: {
            Text("Account Details")
                .font(.adminSectionHeader)
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .padding(.leading, 8)
        }

        let borrowers = viewModel.getBorrowers(for: currentUser.id)
        Section {
            if borrowers.isEmpty {
                Text("No borrowers assigned to this officer.")
                    .font(.adminSecondary)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(borrowers) { borrower in
                    NavigationLink(destination: SimpleUserDetailsView(user: borrower)) {
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(borrower.fullName)
                                    .font(.adminCardTitle)
                                    .foregroundStyle(.primary)
                                Text(borrower.uniqueID)
                                    .font(.adminCaption.monospacedDigit())
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Text(borrower.email)
                                .font(.adminCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } header: {
            Text("Assigned Borrowers (\(borrowers.count))")
                .font(.adminSectionHeader)
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .padding(.leading, 8)
        }

        Section {
            if let manager = viewModel.getSupervisingManager(for: currentUser.id) {
                NavigationKeyValueRow(key: "Reports To", value: manager.fullName, destinationUser: manager, viewModel: viewModel)
            } else {
                KeyValueRow(key: "Reports To", value: "No Manager Assigned")
            }
        } header: {
            Text("Supervisor")
                .font(.adminSectionHeader)
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .padding(.leading, 8)
        }

        manageAccountSection
    }

    // MARK: - Manager Sections

    @ViewBuilder
    private var managerSections: some View {
        Section {
            accountDetailRow(label: "User ID", value: currentUser.uniqueID)
            accountDetailRow(label: "Email", value: currentUser.email)
            accountDetailRow(label: "Phone", value: currentUser.phone)
        } header: {
            Text("Manager Details")
                .font(.adminSectionHeader)
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .padding(.leading, 8)
        }

        let officers = viewModel.getLoanOfficers(for: currentUser.id)
        Section {
            if officers.isEmpty {
                Text("No officers reporting to this manager.")
                    .font(.adminSecondary)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(officers) { officer in
                    NavigationLink(destination: SimpleUserDetailsView(user: officer)) {
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(officer.fullName)
                                    .font(.adminCardTitle)
                                    .foregroundStyle(.primary)
                                Text(officer.uniqueID)
                                    .font(.adminCaption.monospacedDigit())
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Text(officer.email)
                                .font(.adminCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } header: {
            Text("Supervised Officers (\(officers.count))")
                .font(.adminSectionHeader)
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .padding(.leading, 8)
        }

        manageAccountSection
    }

    // MARK: - Admin Sections

    @ViewBuilder
    private var adminSections: some View {
        Section {
            accountDetailRow(label: "User ID", value: currentUser.uniqueID)
            accountDetailRow(label: "Email", value: currentUser.email)
            accountDetailRow(label: "Phone", value: currentUser.phone)
        } header: {
            Text("Admin Account Details")
                .font(.adminSectionHeader)
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .padding(.leading, 8)
        }
    }

    // MARK: - Helpers

    private func accountDetailRow(label: String, value: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(label)
                .font(.adminSecondary)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.adminSecondary)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }

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
                .font(.adminSecondary)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.adminSecondary)
                .fontWeight(.medium)
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
        NavigationLink(destination: SimpleUserDetailsView(user: destinationUser)) {
            HStack {
                Text(key)
                    .font(.adminSecondary)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.adminSecondary)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.lmsInfo)
            }
        }
    }
}

// MARK: - Password Reset Success Sheet
struct PasswordResetSuccessSheet: View {
    let temporaryPassword: String
    let userName: String
    @Environment(\.dismiss) private var dismiss
    @State private var isCopied = false

    var body: some View {
        VStack(spacing: Spacing.l) {
            // Header
            VStack(spacing: Spacing.m) {
                ZStack {
                    Circle()
                        .fill(Color.lmsSuccess.opacity(0.1))
                        .frame(width: 88, height: 88)
                    Image(systemName: "checkmark.shield.fill")
                        .font(.adminLargeTitle)
                        .foregroundStyle(Color.lmsSuccess)
                }
                .padding(.top, Spacing.l)

                Text("Password Reset Complete")
                    .font(.adminScreenTitle)

                Text("Temporary password generated for \(userName)")
                    .font(.adminSecondary)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Password Display Card
            VStack(spacing: Spacing.sm) {
                Text("TEMPORARY PASSWORD")
                    .font(.adminCaption)
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                HStack {
                    Text(temporaryPassword)
                        .font(.adminScreenTitle.monospacedDigit())
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)

                    Spacer()

                    Button {
                        UIPasteboard.general.string = temporaryPassword
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { isCopied = false }
                        }
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc.fill")
                            Text(isCopied ? "Copied" : "Copy")
                        }
                        .font(.adminCaption)
                        .fontWeight(.semibold)
                        .foregroundStyle(isCopied ? Color.lmsSuccess : Color.lmsInfo)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs_s)
                        .background((isCopied ? Color.lmsSuccess : Color.lmsInfo).opacity(0.1), in: Capsule())
                    }
                }
                .padding(Spacing.m)
                .background(Color.lmsTertiaryFill, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
            .padding(.horizontal)

            // Warning Banner
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.adminCardTitle)
                    .foregroundStyle(Color.lmsWarning)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Next Login Required")
                        .font(.adminSecondary)
                        .fontWeight(.semibold)
                    Text("The user must change this password during their next sign-in.")
                        .font(.adminCaption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Spacing.m)
            .background(Color.lmsWarning.opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.medium))
            .padding(.horizontal)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.adminCardTitle)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.bottom, Spacing.l)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Simple User Details View
struct SimpleUserDetailsView: View {
    let user: User
    
    var body: some View {
        List {
            Section {
                accountDetailRow(label: "Name", value: user.fullName)
                accountDetailRow(label: "Role", value: user.role.displayName)
                accountDetailRow(label: "Email", value: user.email)
                accountDetailRow(label: "Phone", value: user.phone)
                accountDetailRow(label: "Employee ID", value: user.uniqueID)
                
                HStack {
                    HStack(spacing: Spacing.s) {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(user.isActive ? Color.lmsSuccess : Color.lmsDanger)
                        Text("Status")
                            .font(.adminBody)
                    }
                    Spacer()
                    Text(user.isActive ? "Active" : "Inactive")
                        .font(.adminSecondary)
                        .fontWeight(.semibold)
                        .foregroundStyle(user.isActive ? Color.lmsSuccess : Color.lmsDanger)
                }
            } header: {
                Text("User Details")
                    .font(.adminSectionHeader)
                    .foregroundStyle(Color.secondary)
                    .textCase(.uppercase)
                    .padding(.leading, 8)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(user.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func accountDetailRow(label: String, value: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(label)
                .font(.adminBody)
            Spacer()
            Text(value)
                .font(.adminSecondary)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}
