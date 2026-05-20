import SwiftUI

struct StaffProfileView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        NavigationStack {
            List {

                // Avatar header
                Section {
                    HStack(spacing: Spacing.m) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.lmsNavyBlue, .lmsPrimary], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 68, height: 68)
                            Text(session.currentUser?.fullName.prefix(1) ?? "?")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.currentUser?.fullName ?? "—")
                                .font(.lmsTitle2)
                            Text(session.role?.displayName ?? "—")
                                .font(.lmsSubheadline)
                                .foregroundStyle(Color.lmsPrimary)
                            if let empID = session.staffProfile?.employeeID {
                                Text("Employee ID: \(empID)")
                                    .font(.lmsCaption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.s)
                }

                // Account Details
                Section("Account") {
                    LabeledContent("Email", value: session.currentUser?.email ?? "—")
                    LabeledContent("Phone", value: session.currentUser?.phone ?? "—")
                    LabeledContent("Role", value: session.role?.displayName ?? "—")
                }

                // Staff Details
                if let staff = session.staffProfile {
                    Section("Department") {
                        LabeledContent("Employee ID", value: staff.employeeID)
                        if let dept = staff.department {
                            LabeledContent("Department", value: dept)
                        }
                    }
                }

                // Settings
                Section("App") {
                    NavigationLink {
                        Text("Notification preferences coming soon")
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Notification Preferences", systemImage: "bell.badge")
                    }
                    NavigationLink {
                        Text("Security settings coming soon")
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Security & Passkeys", systemImage: "lock.shield")
                    }
                }

                // Sign Out
                Section {
                    Button(role: .destructive) {
                        session.currentUser = nil
                        session.staffProfile = nil
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

extension UserRole {
    var displayName: String {
        switch self {
        case .borrower: return "Borrower"
        case .loanOfficer: return "Loan Officer"
        case .manager: return "Manager"
        case .admin: return "Administrator"
        }
    }
}

#Preview {
    StaffProfileView()
        .environment(SessionStore(currentUser: MockData.loanOfficerUser, staffProfile: MockData.loanOfficerStaff))
}
