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

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.m) {
                // Horizontal filter pills
                filterPills

                // User list section
                LazyVStack(spacing: Spacing.s) {
                    if viewModel.filteredUsers.isEmpty {
                        EmptyStateView(
                            title: "No Users Found",
                            subtitle: "No users match your criteria.",
                            systemImage: "person.slash"
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(viewModel.filteredUsers) { user in
                            NavigationLink(destination: UserDetailsView(viewModel: viewModel, user: user)) {
                                UserRowView(user: user, profile: viewModel.staffProfiles[user.id])
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, Spacing.m)
            }
            .padding(.vertical, Spacing.m)
        }
        .background(Color(.systemGroupedBackground))
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
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .bold))
                }
            }
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

                ForEach(UserRole.allCases) { role in
                    filterPill(title: role.rawValue, isSelected: viewModel.currentFilter == .role(role)) {
                        viewModel.currentFilter = .role(role)
                    }
                }
            }
            .padding(.horizontal, Spacing.m)
        }
    }

    /// A single filter pill.
    private func filterPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.lmsSubheadline)
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.s)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(
                    isSelected ? Color.lmsAccent : Color(.systemBackground),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

#Preview {
    NavigationStack {
        UserListView(viewModel: UserManagementViewModel())
    }
}
