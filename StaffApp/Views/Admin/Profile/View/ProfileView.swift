import SwiftUI
import PhotosUI

// MARK: - Profile View

/// A native iOS Profile view matching the requested layout.
struct ProfileView: View {
    @State private var isTwoFactorEnabled = true
    @State private var isBiometricEnabled = true
    @State private var showSignOutConfirmation = false
    @State private var showSignOutSuccess = false
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var avatarImage: Image? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                // Header: Avatar, Name, Role
                headerView
                
                // Account Section
                accountSection
                
                // Security Section
                securitySection
                
                // Preferences Section
                preferencesSection
                
                // Support & Sign Out Section
                footerSection
            }
            .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
            .padding(.top, AdminSpacing.cardRowVerticalInset)
            .padding(.bottom, Spacing.xl)
        }
        .background(AdminColor.background)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Are you sure you want to sign out?", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                showSignOutSuccess = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Signed Out", isPresented: $showSignOutSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You have been successfully signed out of the LMS system.")
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    avatarImage = Image(uiImage: uiImage)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerView: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let avatarImage {
                        avatarImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Text("SA")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 80)
                            .background(Color.indigo)
                            .clipShape(Circle())
                    }
                    
                    // Camera Badge Overlay
                    Image(systemName: "camera.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.indigo)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                        .shadow(radius: 2)
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 4) {
                Text("Sarah Jenkins")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("SYSTEM ADMIN")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.indigo.opacity(0.15), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            SectionHeaderView(title: "Account", systemImage: "person.circle")
            
            VStack(spacing: Spacing.s) {
                profileNavigationRow(
                    icon: "person.fill",
                    iconColor: .blue,
                    title: "Personal Information",
                    destination: PersonalInfoView()
                )
                
                Divider()
                
                profileNavigationRow(
                    icon: "checkmark.shield.fill",
                    iconColor: .green,
                    title: "KYC Status",
                    value: "Verified",
                    destination: KYCDetailedView()
                )
            }
            .padding(AdminSpacing.cardPadding)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        }
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            SectionHeaderView(title: "Security", systemImage: "lock.shield")
            
            VStack(spacing: Spacing.s) {
                profileNavigationRow(
                    icon: "lock.fill",
                    iconColor: .gray,
                    title: "Change Password",
                    destination: ChangePasswordView()
                )
                
                Divider()
                
                HStack(spacing: 12) {
                    iconView(icon: "key.fill", color: .orange)
                    Toggle("Two-Factor Authentication", isOn: $isTwoFactorEnabled)
                        .tint(.green)
                }
                
                Divider()
                
                HStack(spacing: 12) {
                    iconView(icon: "faceid", color: .indigo)
                    Toggle("Biometric Login", isOn: $isBiometricEnabled)
                        .tint(.green)
                }
            }
            .padding(AdminSpacing.cardPadding)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            SectionHeaderView(title: "Preferences", systemImage: "slider.horizontal.3")
            
            VStack(spacing: Spacing.s) {
                profileNavigationRow(
                    icon: "bell.fill",
                    iconColor: .red,
                    title: "Notification Settings",
                    destination: NotificationSettingsDetailedView()
                )
                
                Divider()
                
                profileNavigationRow(
                    icon: "globe",
                    iconColor: .teal,
                    title: "Language",
                    value: "English",
                    destination: LanguageSelectorView()
                )
            }
            .padding(AdminSpacing.cardPadding)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        }
    }

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            VStack(spacing: Spacing.s) {
                profileNavigationRow(
                    icon: "questionmark.circle.fill",
                    iconColor: .gray,
                    title: "Support",
                    destination: SupportDetailedView()
                )
                
                Divider()
                
                Button {
                    showSignOutConfirmation = true
                } label: {
                    HStack(spacing: 12) {
                        iconView(icon: "rectangle.portrait.and.arrow.right.fill", color: .red.opacity(0.2), foregroundColor: .red)
                        Text("Sign Out")
                            .foregroundStyle(.red)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(AdminSpacing.cardPadding)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Subviews
    
    private func profileNavigationRow<Destination: View>(icon: String, iconColor: Color, title: String, value: String? = nil, destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                iconView(icon: icon, color: iconColor)
                
                Text(title)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .foregroundStyle(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func iconView(icon: String, color: Color, foregroundColor: Color = .white) -> some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(foregroundColor)
            .frame(width: 32, height: 32)
            .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                // Info Cards
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Staff Details", systemImage: "info.circle")
                    
                    VStack(spacing: Spacing.s) {
                        detailRow(title: "Employee ID", value: "EMP-00123")
                        Divider()
                        detailRow(title: "Department", value: "Administration")
                        Divider()
                        detailRow(title: "Office Location", value: "Mumbai Corporate HQ")
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Contact Details", systemImage: "envelope.fill")
                    
                    VStack(spacing: 16) {
                        if isEditing {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Full Name")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("Full Name", text: $name)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email Address")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("Email Address", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Phone Number")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("Phone Number", text: $phone)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.phonePad)
                            }
                        } else {
                            detailRow(title: "Full Name", value: name)
                            Divider()
                            detailRow(title: "Email Address", value: email)
                            Divider()
                            detailRow(title: "Phone Number", value: phone)
                        }
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                
                if isEditing {
                    AdminPrimaryButton("Save Changes") {
                        originalName = name
                        originalEmail = email
                        originalPhone = phone
                        isEditing = false
                        showSaveSuccess = true
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
            .padding(.vertical, 24)
        }
        .background(AdminColor.background)
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

// 2. KYC Status View
struct KYCDetailedView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                // KYC Summary Card
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "KYC Overview", systemImage: "checkmark.seal.fill")
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("Verification Status")
                            Spacer()
                            Text("Verified")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.15), in: Capsule())
                                .foregroundStyle(.green)
                        }
                        
                        Divider()
                        
                        detailRow(title: "Verification Date", value: "15 May 2026")
                        Divider()
                        detailRow(title: "Authorized Officer", value: "System Auto-KYC")
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                
                // Documents Card
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Verified Documents", systemImage: "doc.plaintext.fill")
                    
                    VStack(spacing: 12) {
                        documentRow(title: "Aadhaar Card", number: "xxxx xxxx 5678", systemImage: "person.text.rectangle")
                        Divider()
                        documentRow(title: "PAN Card", number: "ABCDE1234F", systemImage: "creditcard.fill")
                        Divider()
                        documentRow(title: "Employee ID Verification", number: "EMP-00123", systemImage: "person.badge.shield.checkered")
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
            .padding(.vertical, 24)
        }
        .background(AdminColor.background)
        .navigationTitle("KYC Status")
        .navigationBarTitleDisplayMode(.inline)
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
    
    private func documentRow(title: String, number: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(AdminColor.accent)
                .frame(width: 32, height: 32)
                .background(AdminColor.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(number)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
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
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Update Password", systemImage: "key.fill")
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Current Password")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            SecureField("Enter current password", text: $currentPassword)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("New Password")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            SecureField("Enter new password (min. 8 chars)", text: $newPassword)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirm New Password")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            SecureField("Confirm new password", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                
                AdminPrimaryButton("Update Password") {
                    handleUpdatePassword()
                }
                .disabled(currentPassword.isEmpty || newPassword.count < 8 || confirmPassword.isEmpty)
            }
            .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
            .padding(.vertical, 24)
        }
        .background(AdminColor.background)
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
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                // Section 1: Loan Approved Notices
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Loan Approval Alerts", systemImage: "checkmark.circle.fill")
                    
                    VStack(spacing: Spacing.s) {
                        Toggle("Email Notifications", isOn: $emailApproved)
                            .tint(.green)
                        Divider()
                        Toggle("In-App Push Alerts", isOn: $inAppApproved)
                            .tint(.green)
                        Divider()
                        Toggle("SMS Notifications", isOn: $smsApproved)
                            .tint(.green)
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                
                // Section 2: EMI Due Alerts
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Payment Due Reminders", systemImage: "calendar.fill")
                    
                    VStack(spacing: Spacing.s) {
                        Toggle("Email Notifications", isOn: $emailDue)
                            .tint(.green)
                        Divider()
                        Toggle("In-App Push Alerts", isOn: $inAppDue)
                            .tint(.green)
                        Divider()
                        Toggle("SMS Notifications", isOn: $smsDue)
                            .tint(.green)
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                
                // Section 3: Payment Overdue Alerts
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Overdue Alerts", systemImage: "exclamationmark.triangle.fill")
                    
                    VStack(spacing: Spacing.s) {
                        Toggle("Email Notifications", isOn: $emailOverdue)
                            .tint(.green)
                        Divider()
                        Toggle("In-App Push Alerts", isOn: $inAppOverdue)
                            .tint(.green)
                        Divider()
                        Toggle("SMS Notifications", isOn: $smsOverdue)
                            .tint(.green)
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                
                AdminPrimaryButton("Save Preferences") {
                    showSaveAlert = true
                }
            }
            .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
            .padding(.vertical, 24)
        }
        .background(AdminColor.background)
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
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                // Support Card Info
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Contact Desk", systemImage: "phone.fill")
                    
                    VStack(spacing: 12) {
                        contactRow(title: "Toll Free Helpline", value: "1800-419-5959", systemImage: "phone.bubble.fill")
                        Divider()
                        contactRow(title: "Support Email", value: "support@lms.com", systemImage: "envelope.fill")
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                
                // Submit Ticket Card
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Submit a Ticket", systemImage: "square.and.pencil")
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Menu {
                                ForEach(categories, id: \.self) { category in
                                    Button {
                                        ticketCategory = category
                                    } label: {
                                        Text(category)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(ticketCategory)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(10)
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                )
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $ticketMessage)
                                .frame(height: 120)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                )
                        }
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                
                AdminPrimaryButton("Submit Ticket") {
                    showTicketSuccess = true
                }
                .disabled(ticketMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
            .padding(.vertical, 24)
        }
        .background(AdminColor.background)
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
