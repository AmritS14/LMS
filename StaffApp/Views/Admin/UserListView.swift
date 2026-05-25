//
//  UserListView.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI

// MARK: - User List View

/// The main view for User Management (US-39 & US-40).
/// Displays a searchable list of all system users with role-based filters.
struct UserListView: View {
    @Bindable var viewModel: UserManagementViewModel
    @State private var showCreateUserSheet = false

    var body: some View {
        List {
            // Horizontal filter pills
            filterPills
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.bottom, Spacing.m)

            // User list section
            if viewModel.filteredUsers.isEmpty {
                EmptyStateView(
                    title: "No Users Found",
                    subtitle: "No users match your criteria.",
                    systemImage: "person.slash"
                )
                .padding(.top, 40)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(viewModel.filteredUsers) { user in
                    ZStack {
                        NavigationLink(destination: UserDetailsView(viewModel: viewModel, user: user)) {
                            EmptyView()
                        }
                        .opacity(0)
                        
                        UserRowView(user: user, profile: viewModel.staffProfiles[user.id])
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: Spacing.m, bottom: AdminSpacing.cardGap, trailing: Spacing.m))
                }
            }
        }
        .listStyle(.plain)
        .background(AdminColor.background)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search"
        )
        .navigationTitle("Users")
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.successMessage)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateUserSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showCreateUserSheet) {
            CreateUserSheet(viewModel: viewModel)
        }
    }

    // MARK: - Sections

    /// Horizontal scrollable list of filter pills.
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                filterPill(title: "All", isSelected: viewModel.currentFilter == .all) {
                    viewModel.currentFilter = .all
                }

                ForEach(UserRole.allCases, id: \.self) { role in
                    filterPill(title: role.displayName, isSelected: viewModel.currentFilter == .role(role)) {
                        viewModel.currentFilter = .role(role)
                    }
                }
            }
            .padding(.horizontal, Spacing.m)
        }
    }

    /// A single filter pill.
    private func filterPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        }) {
            Text(title)
                .font(.lmsSubheadline)
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.s)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(
                    isSelected ? AdminColor.accent : Color(.secondarySystemGroupedBackground),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1)
                )
        }
    }
}

struct CreateUserSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: UserManagementViewModel

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var role: UserRole = .loanOfficer

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Email ID", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.emailAddress)
                    
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                } header: {
                    Text("Staff Information")
                }

                Section {
                    Picker("Assign Role", selection: $role) {
                        Text("Loan Officer").tag(UserRole.loanOfficer)
                        Text("Manager").tag(UserRole.manager)
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Role Assignment")
                }
            }
            .navigationTitle("Create Staff Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createUser(fullName: name, email: email, phone: phone, role: role)
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserListView(viewModel: UserManagementViewModel())
    }
}
