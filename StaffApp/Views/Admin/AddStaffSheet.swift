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
                Section("Identity") {
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                    TextField("Work Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Role & Employment") {
                    Picker("Role", selection: $role) {
                        ForEach(creatableRoles, id: \.self) { r in
                            Text(r.displayName).tag(r)
                        }
                    }
                    TextField("Employee ID (e.g. EMP-1002)", text: $employeeID)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                }

                Section {
                    SecureField("Temporary Password", text: $temporaryPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("Initial Credentials")
                } footer: {
                    Text("Minimum 8 characters. The staff member signs in with this and can change it later.")
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("New Staff User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        submit()
                    } label: {
                        if isSaving { ProgressView() } else { Text("Create").fontWeight(.bold) }
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
