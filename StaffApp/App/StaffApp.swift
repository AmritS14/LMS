import SwiftUI

@main
struct StaffApp: App {
    // Until staff auth is wired, seed the session with the mock loan officer
    // so the new screens have a current user to read.
    @State private var session = SessionStore(
        currentUser: User(
            id: MockOfficerData.officerUserID,
            fullName: MockOfficerData.officerProfile.name,
            email: "sarah.mehta@example.com",
            phone: "+91 99887 76543",
            role: .loanOfficer
        ),
        staffProfile: StaffProfile(
            id: MockOfficerData.officerUserID,
            employeeID: MockOfficerData.officerProfile.employeeID,
            branchID: nil,
            department: "Loan Origination",
            reportsToID: nil
        )
    )

    private let appEnvironment = AppEnvironment(
        auth: SupabaseAuthService(),
        loans: SupabaseLoanService(client: SupabaseManager.shared.client),
        documents: SupabaseDocumentService(client: SupabaseManager.shared.client),
        notifications: MockNotificationService(),
        messaging: SupabaseMessagingService(client: SupabaseManager.shared.client),
        keychain: MockKeychainService(),
        admin: SupabaseAdminService(client: SupabaseManager.shared.client),
        aadhaarKYC: SupabaseAadhaarKYCService(client: SupabaseManager.shared.client)
    )

    var body: some Scene {
        WindowGroup {
            StaffRootView()
                .environment(session)
                .environment(\.appEnvironment, appEnvironment)
        }
    }
}
