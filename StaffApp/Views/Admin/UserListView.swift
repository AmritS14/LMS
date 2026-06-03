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
    @State private var showAddStaff = false

    var body: some View {
        List {
            // Horizontal filter pills
            filterPills
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.bottom, Spacing.m)

            // User list section
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else if let error = viewModel.loadError {
                EmptyStateView(
                    title: "Failed to Load",
                    subtitle: error,
                    systemImage: "exclamationmark.triangle"
                )
                .padding(.top, 40)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else if viewModel.filteredUsers.isEmpty {
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
                        
                        UserRowView(
                            user: user,
                            profile: viewModel.staffProfiles[user.id],
                            isResetPending: viewModel.usersPendingReset.contains(user.id)
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: Spacing.m, bottom: AdminSpacing.cardGap, trailing: Spacing.m))
                }
            }
        }
        .listStyle(.plain)
        .background(AdminColor.background)
        .refreshable {
            await viewModel.load()
        }
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
                    showAddStaff = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.adminCardTitle)
                }
                .accessibilityLabel("Add staff user")
            }
        }
        .sheet(isPresented: $showAddStaff) {
            AddStaffSheet(viewModel: viewModel)
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
                .font(.adminSecondary)
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

#Preview {
    NavigationStack {
        UserListView(viewModel: UserManagementViewModel())
    }
}
