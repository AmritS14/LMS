import SwiftUI

// MARK: - Profile View

/// A native iOS Profile view matching the requested layout.
@MainActor
struct ProfileView: View {
    @Environment(\.appEnvironment) private var env
    @Environment(SessionStore.self) private var session

    @State private var isTwoFactorEnabled = true
    @State private var isBiometricEnabled = true
    @State private var showSignOutConfirmation = false
    @State private var showSignOutSuccess = false

    private func signOut() {
        Task {
            try? await env?.auth.signOut()
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    session.currentUser = nil
                }
            }
        }
    }

    var body: some View {
        List {
            // Header: Avatar, Name, Role
            headerView
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            
            // Account Section
            accountSection
            
            // Security Section
            securitySection
            
            // Preferences Section
//            preferencesSection
            
            Button(role: .destructive) { showSignOutConfirmation = true } label: {
                HStack {
                    Spacer()
                    Text("Sign out")
                    Spacer()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Log Out?", isPresented: $showSignOutConfirmation) {
            Button("Log Out", role: .destructive) { signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out from your account?")
        }
        .alert("Signed Out", isPresented: $showSignOutSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You have been successfully signed out of the LMS system.")
        }
    }
    
    // MARK: - Sections
    
    @MainActor
    private var headerView: some View {
        VStack(spacing: 14) {
            SystemProfileBadge()

            VStack(spacing: 6) {
                Text("Sarah Jenkins")
                    .font(.adminScreenTitle)
                    .fontWeight(.bold)
                
                Text("SYSTEM ADMIN")
                    .font(.adminCaption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.indigo.opacity(0.15), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s)
    }

    private var accountSection: some View {
        Section {
            NavigationLink("Personal Information", destination: PersonalInfoView())
        } header: {
            Text("Account")
                .font(.adminSectionHeader).foregroundStyle(Color.secondary).textCase(.uppercase).padding(.leading, 8)
        }
    }

    private var securitySection: some View {
        Section {
            NavigationLink("Change Password", destination: ChangePasswordView())
            Toggle("Two-Factor Authentication", isOn: $isTwoFactorEnabled)
                .tint(.blue)
            Toggle("Biometric Login", isOn: $isBiometricEnabled)
                .tint(.blue)
        } header: {
            Text("Security")
                .font(.adminSectionHeader).foregroundStyle(Color.secondary).textCase(.uppercase).padding(.leading, 8)
        }
    }

    private var preferencesSection: some View {
        Section {
            NavigationLink("Notification Settings", destination: NotificationSettingsDetailedView())
            NavigationLink(destination: LanguageSelectorView()) {
                HStack {
                    Text("Language")
                    Spacer()
                    Text("English").foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Preferences")
                .font(.adminSectionHeader).foregroundStyle(Color.secondary).textCase(.uppercase).padding(.leading, 8)
        }
    }


}

// MARK: - Detailed Subviews

// 1. Personal Information View
struct PersonalInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = "Sarah Jenkins"
    @State private var email = "sarah.jenkins@lms.com"
    @State private var phone = "+91 98765 43210"
    
    @State private var isEditing = false
    @State private var showCancelConfirmation = false
    @State private var showSaveSuccess = false
    
    @State private var originalName = "Sarah Jenkins"
    @State private var originalEmail = "sarah.jenkins@lms.com"
    @State private var originalPhone = "+91 98765 43210"
    
    private var isDirty: Bool {
        name != originalName || email != originalEmail || phone != originalPhone
    }
    
    var body: some View {
        List {
            Section {
                detailRow(title: "Employee ID", value: "EMP-00123")
                detailRow(title: "Department", value: "Administration")
                detailRow(title: "Office Location", value: "Mumbai Corporate HQ")
            } header: {
                Text("Staff Details").font(.adminSectionHeader).foregroundStyle(Color.secondary).textCase(.uppercase).padding(.leading, 8)
            }
            
            Section {
                if isEditing {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Full Name").font(.adminCaption).foregroundStyle(.secondary)
                        TextField("Full Name", text: $name).textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email Address").font(.adminCaption).foregroundStyle(.secondary)
                        TextField("Email Address", text: $email).textFieldStyle(.roundedBorder).keyboardType(.emailAddress).autocorrectionDisabled().textInputAutocapitalization(.never)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Phone Number").font(.adminCaption).foregroundStyle(.secondary)
                        TextField("Phone Number", text: $phone).textFieldStyle(.roundedBorder).keyboardType(.phonePad)
                    }
                } else {
                    detailRow(title: "Full Name", value: name)
                    detailRow(title: "Email Address", value: email)
                    detailRow(title: "Phone Number", value: phone)
                }
            } header: {
                Text("Contact Details").font(.adminSectionHeader).foregroundStyle(Color.secondary).textCase(.uppercase).padding(.leading, 8)
            }
            
            if isEditing {
                Section {
                    Button("Save Changes") {
                        originalName = name
                        originalEmail = email
                        originalPhone = phone
                        isEditing = false
                        showSaveSuccess = true
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Personal Info")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing && isDirty)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Cancel" : "Edit") {
                    if isEditing {
                        if isDirty {
                            showCancelConfirmation = true
                        } else {
                            isEditing = false
                        }
                    } else {
                        isEditing = true
                    }
                }
                .tint(AdminColor.accent)
            }
            
            if isEditing && isDirty {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showCancelConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            "Unsaved Changes",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard Changes", role: .destructive) {
                name = originalName
                email = originalEmail
                phone = originalPhone
                isEditing = false
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Do you want to leave without saving?")
        }
        .alert("Success", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Personal information updated successfully.")
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
                .fontWeight(.medium)
        }
    }
}

// 3. Change Password View
struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    @State private var errorMessage: String? = nil
    @State private var showSuccess = false
    @State private var showCancelConfirmation = false
    
    private var isDirty: Bool {
        !currentPassword.isEmpty || !newPassword.isEmpty || !confirmPassword.isEmpty
    }
    
    var body: some View {
        List {
            Section {
                SecureField("Enter current password", text: $currentPassword)
                SecureField("Enter new password (min. 8 chars)", text: $newPassword)
                SecureField("Confirm new password", text: $confirmPassword)
            } header: {
                Text("Update Password").font(.adminSectionHeader).foregroundStyle(Color.secondary).textCase(.uppercase).padding(.leading, 8)
            }
            
            Section {
                Button("Update Password") {
                    handleUpdatePassword()
                }
                .disabled(currentPassword.isEmpty || newPassword.count < 8 || confirmPassword.isEmpty)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isDirty)
        .toolbar {
            if isDirty {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showCancelConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            "Unsaved Changes",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Do you want to leave without saving?")
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your password has been changed successfully.")
        }
    }
    
    private func handleUpdatePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "New password and confirmation password do not match."
            return
        }
        showSuccess = true
    }
}

// 4. Notification Settings View
struct NotificationSettingsDetailedView: View {
    @State private var emailApproved = true
    @State private var inAppApproved = true
    @State private var smsApproved = false
    
    @State private var emailDue = true
    @State private var inAppDue = true
    @State private var smsDue = true
    
    @State private var emailOverdue = true
    @State private var inAppOverdue = true
    @State private var smsOverdue = true
    
    @State private var showSaveAlert = false
    
    var body: some View {
        List {
            Section {
                Toggle("Email Notifications", isOn: $emailApproved).tint(.blue)
                Toggle("In-App Push Alerts", isOn: $inAppApproved).tint(.blue)
                Toggle("SMS Notifications", isOn: $smsApproved).tint(.blue)
            } header: {
                Text("Loan Approval Alerts").font(.adminSectionHeader).foregroundStyle(Color.secondary).textCase(.uppercase).padding(.leading, 8)
            }
            
            Section {
                Toggle("Email Notifications", isOn: $emailDue).tint(.blue)
                Toggle("In-App Push Alerts", isOn: $inAppDue).tint(.blue)
                Toggle("SMS Notifications", isOn: $smsDue).tint(.blue)
            } header: {
                Text("Payment Due Reminders").font(.adminSectionHeader).foregroundStyle(Color.secondary).textCase(.uppercase).padding(.leading, 8)
            }
            
            Section {
                Toggle("Email Notifications", isOn: $emailOverdue).tint(.blue)
                Toggle("In-App Push Alerts", isOn: $inAppOverdue).tint(.blue)
                Toggle("SMS Notifications", isOn: $smsOverdue).tint(.blue)
            } header: {
                Text("Overdue Alerts").font(.adminSectionHeader).foregroundStyle(Color.secondary).textCase(.uppercase).padding(.leading, 8)
            }
            
            Section {
                Button("Save Preferences") {
                    showSaveAlert = true
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Preferences Saved", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your notification channel preferences have been saved successfully.")
        }
    }
}

// 5. Language Selector View
struct LanguageSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLanguage = "English"
    
    private let languages = ["English", "Hindi", "Spanish", "French", "German"]
    
    var body: some View {
        List {
            ForEach(languages, id: \.self) { language in
                Button {
                    selectedLanguage = language
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        dismiss()
                    }
                } label: {
                    HStack {
                        Text(language)
                            .foregroundStyle(.primary)
                        Spacer()
                        if language == selectedLanguage {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AdminColor.accent)
                                .fontWeight(.bold)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(AdminColor.background)
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 6. Support Detailed View
struct SupportDetailedView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var ticketCategory = "Query"
    @State private var ticketMessage = ""
    @State private var showTicketSuccess = false
    
    private let categories = ["Query", "Bug Report", "Feature Request", "Feedback"]
    
    var body: some View {
        List {
            Section {
                contactRow(title: "Toll Free Helpline", value: "1800-419-5959", systemImage: "phone.bubble.fill")
                contactRow(title: "Support Email", value: "support@lms.com", systemImage: "envelope.fill")
            } header: {
                Text("Contact Desk").font(.adminSectionHeader).foregroundStyle(Color.secondary).textCase(.uppercase).padding(.leading, 8)
            }
            
            Section {
                Picker("Category", selection: $ticketCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.adminCaption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $ticketMessage)
                        .frame(height: 120)
                }
                .padding(.vertical, 4)
                
                Button("Submit Ticket") {
                    showTicketSuccess = true
                }
                .disabled(ticketMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: {
                Text("Submit a Ticket").font(.adminSectionHeader).foregroundStyle(Color.secondary).textCase(.uppercase).padding(.leading, 8)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ticket Submitted", isPresented: $showTicketSuccess) {
            Button("OK") {
                ticketMessage = ""
                dismiss()
            }
        } message: {
            Text("Thank you! Your ticket (#\(Int.random(in: 100000...999999))) has been submitted. We will contact you shortly.")
        }
    }
    
    private func contactRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(AdminColor.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.adminCaption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.adminBody)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
    }
}

private struct SystemProfileBadge: View {

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AdminColor.accent, Color.indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 84, height: 84)

            Image(systemName: "person.crop.circle.fill")
                .font(.adminLargeTitle)
                .foregroundStyle(.white.opacity(0.95))
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
