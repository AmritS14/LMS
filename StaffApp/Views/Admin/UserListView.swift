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
                Menu {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.currentFilter = .all
                        }
                    } label: {
                        Label("All", systemImage: viewModel.currentFilter == .all ? "checkmark" : "person.3")
                    }

                    Divider()

                    ForEach(UserRole.allCases, id: \.self) { role in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.currentFilter = .role(role)
                            }
                        } label: {
                            Label(role.displayName, systemImage: viewModel.currentFilter == .role(role) ? "checkmark" : "person")
                        }
                    }
                } label: {
                    Image(systemName: viewModel.currentFilter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Filter users")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddStaff = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                }
                .accessibilityLabel("Add staff user")
            }
        }
        .sheet(isPresented: $showAddStaff) {
            AddStaffSheet(viewModel: viewModel)
        }
    }

}

#Preview {
    NavigationStack {
        UserListView(viewModel: UserManagementViewModel())
    }
}
