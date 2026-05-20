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

                Text("@\(user.email.components(separatedBy: "@").last ?? "lms.com")")
                    .font(.lmsCaption)
                    .foregroundStyle(.secondary)

                Text(user.phone)
                    .font(.lmsCaption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Spacing.s) {
                StatusBadge(user.role.rawValue, tone: roleBadgeTone)
                
                if let empId = profile?.employeeID {
                    Text(empId)
                        .font(.lmsCaption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(Spacing.m)
        .background(
            Color(UIColor.systemBackground),
            in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
        )
        .shadow(color: .black.opacity(0.02), radius: 5, y: 2)
    }

    private var initialsAvatar: some View {
        let initials = user.fullName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()

        return Text(initials)
            .font(.system(.title3, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
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
    
    private var roleBadgeTone: StatusBadge.Tone {
        switch user.role {
        case .admin: return .danger
        case .manager: return .warning
        case .loanOfficer: return .info
        case .borrower: return .success
        }
    }
}

// MARK: - User Details View (Editing)

struct UserDetailsView: View {
    @Bindable var viewModel: UserManagementViewModel
    let user: User
    
    var body: some View {
        Form {
            Section("Account Details") {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(user.fullName).foregroundStyle(.secondary)
                }
                HStack {
                    Text("Email")
                    Spacer()
                    Text(user.email).foregroundStyle(.secondary)
                }
                HStack {
                    Text("Phone")
                    Spacer()
                    Text(user.phone).foregroundStyle(.secondary)
                }
            }
            
            Section("Role") {
                Picker("Role", selection: roleBinding) {
                    ForEach(UserRole.allCases) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
                .disabled(user.role == .admin)
            }
            
            if user.role != .borrower {
                Section("Custom Permissions") {
                    ForEach(Permission.allCases) { permission in
                        Toggle(permission.rawValue, isOn: permissionBinding(for: permission))
                    }
                }
                .disabled(user.role == .admin)
            }
        }
        .navigationTitle("Manage User")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.successMessage)
        }
    }
    
    // MARK: - Bindings
    
    private var roleBinding: Binding<UserRole> {
        Binding(
            get: { user.role },
            set: { newRole in
                Task {
                    await viewModel.updateRole(for: user.id, to: newRole)
                }
            }
        )
    }

    private func permissionBinding(for permission: Permission) -> Binding<Bool> {
        let currentPermissions = viewModel.staffProfiles[user.id]?.permissions ?? []
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
                    await viewModel.updatePermissions(for: user.id, to: newPermissions)
                }
            }
        )
    }
}
