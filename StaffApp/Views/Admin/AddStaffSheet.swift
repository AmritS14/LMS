import SwiftUI

/// Admin form to create a new staff account (loan officer / manager / admin)
/// via the backend `/admin/staff` endpoint.
struct AddStaffSheet: View {
    @Bindable var viewModel: UserManagementViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var employeeID = ""
    @State private var temporaryPassword = ""
    @State private var role: UserRole = .loanOfficer

    @State private var isSaving = false
    @State private var errorMessage: String?

    // Only staff roles can be created here.
    private let creatableRoles: [UserRole] = [.loanOfficer, .manager]

    private var canSubmit: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") &&
        !employeeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        temporaryPassword.count >= 8 &&
        !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                    TextField("Work Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Identity")
                        .font(.adminSectionHeader)
                        .foregroundStyle(Color.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, 8)
                }

                Section {
                    Picker("Role", selection: $role) {
                        ForEach(creatableRoles, id: \.self) { r in
                            Text(r.displayName).tag(r)
                        }
                    }
                    TextField("Employee ID (e.g. EMP-1002)", text: $employeeID)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                } header: {
                    Text("Role & Employment")
                        .font(.adminSectionHeader)
                        .foregroundStyle(Color.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, 8)
                }

                Section {
                    SecureField("Temporary Password", text: $temporaryPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("Initial Credentials")
                        .font(.adminSectionHeader)
                        .foregroundStyle(Color.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, 8)
                } footer: {
                    Text("Minimum 8 characters. The staff member signs in with this and can change it later.")
                        .font(.adminCaption)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.adminStatus)
                    }
                }
            }
            .navigationTitle("New Staff User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) { Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.primary).padding(8).background(Color(uiColor: .systemGray5), in: Circle()) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        submit()
                    } label: {
                        if isSaving { ProgressView().progressViewStyle(.circular) } else { Text("Create").fontWeight(.bold) }
                    }
                    .disabled(!canSubmit)
                }
            }
        }
    }

    private func submit() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await viewModel.createStaff(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                    role: role,
                    employeeID: employeeID.trimmingCharacters(in: .whitespacesAndNewlines),
                    temporaryPassword: temporaryPassword
                )
                viewModel.successMessage = "\(fullName) created as \(role.displayName)."
                viewModel.showSuccessAlert = true
                isSaving = false
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}
