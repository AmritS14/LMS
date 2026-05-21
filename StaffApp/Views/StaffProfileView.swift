import SwiftUI

struct StaffProfileView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                
                // Profile Avatar & Name
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 90, height: 90)
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text(session.currentUser?.fullName ?? "Manager")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(session.role?.rawValue.capitalized ?? "Branch Manager")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(session.currentUser?.email ?? "manager@lms.com")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.top, 16)
                
                // Stats Row
                HStack(spacing: 0) {
                    statItem(value: "156", label: "Reviewed")
                    Divider().frame(height: 40)
                    statItem(value: "23", label: "Pending")
                    Divider().frame(height: 40)
                    statItem(value: "4.1h", label: "Avg. TAT")
                }
                .padding()
                .background(Color.gray.opacity(0.06))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Account Section
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader("Account")
                    
                    profileRow(icon: "person.fill", title: "Full Name", value: session.currentUser?.fullName ?? "Manager")
                    profileRow(icon: "envelope.fill", title: "Email", value: session.currentUser?.email ?? "manager@lms.com")
                    profileRow(icon: "shield.fill", title: "Role", value: session.role?.rawValue.capitalized ?? "Branch Manager")
                    profileRow(icon: "building.2.fill", title: "Branch", value: "Main Branch")
                    profileRow(icon: "number", title: "Employee ID", value: "EMP-1042")
                }
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal)
                
                // Preferences Section
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader("Preferences")
                    
                    profileRow(icon: "bell.fill", title: "Notifications", value: "Enabled")
                    profileRow(icon: "lock.fill", title: "Change Password", value: "")
                    profileRow(icon: "questionmark.circle.fill", title: "Help & Support", value: "")
                }
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal)
                
                // Sign Out
                Button(action: {
                    // TODO: AuthService.signOut
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
    
    private func profileRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.blue)
                .frame(width: 28, height: 28)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            if !value.isEmpty {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        StaffProfileView()
            .environment(SessionStore())
    }
}
