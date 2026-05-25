import re

with open('/Users/shailesh99394gmail.com/Downloads/LMS/StaffApp/Views/Admin/Profile/View/ProfileView.swift', 'r') as f:
    content = f.read()

# Refactor PersonalInfoView body
personal_info_body_old = """    var body: some View {
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
        .background(AdminColor.background)"""

personal_info_body_new = """    var body: some View {
        List {
            Section {
                detailRow(title: "Employee ID", value: "EMP-00123")
                detailRow(title: "Department", value: "Administration")
                detailRow(title: "Office Location", value: "Mumbai Corporate HQ")
            } header: {
                Text("Staff Details").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
            }
            
            Section {
                if isEditing {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Full Name").font(.caption).foregroundStyle(.secondary)
                        TextField("Full Name", text: $name).textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email Address").font(.caption).foregroundStyle(.secondary)
                        TextField("Email Address", text: $email).textFieldStyle(.roundedBorder).keyboardType(.emailAddress).autocorrectionDisabled().textInputAutocapitalization(.never)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Phone Number").font(.caption).foregroundStyle(.secondary)
                        TextField("Phone Number", text: $phone).textFieldStyle(.roundedBorder).keyboardType(.phonePad)
                    }
                } else {
                    detailRow(title: "Full Name", value: name)
                    detailRow(title: "Email Address", value: email)
                    detailRow(title: "Phone Number", value: phone)
                }
            } header: {
                Text("Contact Details").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
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
        .listStyle(.insetGrouped)"""
content = content.replace(personal_info_body_old, personal_info_body_new)

# KYCDetailedView body
kyc_body_old = """    var body: some View {
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
                }
            }
            .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
            .padding(.vertical, 24)
        }
        .background(AdminColor.background)"""
kyc_body_new = """    var body: some View {
        List {
            Section {
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
                detailRow(title: "Verification Date", value: "15 May 2026")
                detailRow(title: "Authorized Officer", value: "System Auto-KYC")
            } header: {
                Text("KYC Overview").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
            }
            
            Section {
                documentRow(title: "Aadhaar Card", number: "xxxx xxxx 5678", systemImage: "person.text.rectangle")
                documentRow(title: "PAN Card", number: "ABCDE1234F", systemImage: "creditcard.fill")
                documentRow(title: "Employee ID Verification", number: "EMP-00123", systemImage: "person.badge.shield.checkered")
            } header: {
                Text("Verified Documents").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
            }
        }
        .listStyle(.insetGrouped)"""
content = content.replace(kyc_body_old, kyc_body_new)

# ChangePasswordView body
password_body_old = """    var body: some View {
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Update Password", systemImage: "lock.rotation")
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Current Password")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            SecureField("Current Password", text: $currentPassword)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("New Password")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            SecureField("New Password", text: $newPassword)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirm New Password")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            SecureField("Confirm New Password", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                AdminPrimaryButton("Update Password") {
                    updatePassword()
                }
                .disabled(!isDirty)
            }
            .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
            .padding(.vertical, 24)
        }
        .background(AdminColor.background)"""
password_body_new = """    var body: some View {
        List {
            Section {
                SecureField("Current Password", text: $currentPassword)
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)
            } header: {
                Text("Update Password").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
            } footer: {
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            
            Section {
                Button("Update Password") {
                    updatePassword()
                }
                .disabled(!isDirty)
            }
        }
        .listStyle(.insetGrouped)"""
content = content.replace(password_body_old, password_body_new)

# NotificationSettingsDetailedView body
notif_body_old = """    var body: some View {
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                // Email Notifications
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Email Notifications", systemImage: "envelope.fill")
                    
                    VStack(spacing: Spacing.s) {
                        Toggle("System Alerts", isOn: $emailAlerts)
                            .tint(AdminColor.accent)
                        Divider()
                        Toggle("Marketing Updates", isOn: $emailMarketing)
                            .tint(AdminColor.accent)
                        Divider()
                        Toggle("Daily Summaries", isOn: $emailSummaries)
                            .tint(AdminColor.accent)
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                // Push Notifications
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Push Notifications", systemImage: "app.badge.fill")
                    
                    VStack(spacing: Spacing.s) {
                        Toggle("New Applications", isOn: $pushNewApps)
                            .tint(AdminColor.accent)
                        Divider()
                        Toggle("Status Changes", isOn: $pushStatusChanges)
                            .tint(AdminColor.accent)
                        Divider()
                        Toggle("Chat Messages", isOn: $pushMessages)
                            .tint(AdminColor.accent)
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                if isDirty {
                    AdminPrimaryButton("Save Preferences") {
                        savePreferences()
                    }
                }
            }
            .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
            .padding(.vertical, 24)
        }
        .background(AdminColor.background)"""
notif_body_new = """    var body: some View {
        List {
            Section {
                Toggle("System Alerts", isOn: $emailAlerts).tint(.blue)
                Toggle("Marketing Updates", isOn: $emailMarketing).tint(.blue)
                Toggle("Daily Summaries", isOn: $emailSummaries).tint(.blue)
            } header: {
                Text("Email Notifications").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
            }
            
            Section {
                Toggle("New Applications", isOn: $pushNewApps).tint(.blue)
                Toggle("Status Changes", isOn: $pushStatusChanges).tint(.blue)
                Toggle("Chat Messages", isOn: $pushMessages).tint(.blue)
            } header: {
                Text("Push Notifications").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
            }
            
            if isDirty {
                Section {
                    Button("Save Preferences") {
                        savePreferences()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)"""
content = content.replace(notif_body_old, notif_body_new)

# LanguageSelectorView body
lang_body_old = """    var body: some View {
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Display Language", systemImage: "globe")
                    
                    VStack(spacing: 0) {
                        ForEach(languages, id: \.self) { language in
                            Button {
                                selectedLanguage = language
                            } label: {
                                HStack {
                                    Text(language)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedLanguage == language {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(AdminColor.accent)
                                            .fontWeight(.bold)
                                    }
                                }
                                .padding(.vertical, 12)
                            }
                            
                            if language != languages.last {
                                Divider()
                            }
                        }
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
            .padding(.vertical, 24)
        }
        .background(AdminColor.background)"""
lang_body_new = """    var body: some View {
        List {
            Section {
                ForEach(languages, id: \.self) { language in
                    Button {
                        selectedLanguage = language
                    } label: {
                        HStack {
                            Text(language)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AdminColor.accent)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            } header: {
                Text("Display Language").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
            }
        }
        .listStyle(.insetGrouped)"""
content = content.replace(lang_body_old, lang_body_new)

# SupportDetailedView body
support_body_old = """    var body: some View {
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                // Contact Options
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Contact Options", systemImage: "phone.fill")
                    
                    VStack(spacing: 12) {
                        contactRow(title: "Help Desk", value: "1-800-LMS-HELP", systemImage: "phone.circle.fill")
                        Divider()
                        contactRow(title: "Email Support", value: "support@lms.com", systemImage: "envelope.circle.fill")
                        Divider()
                        contactRow(title: "Live Chat", value: "Available 9 AM - 5 PM", systemImage: "message.circle.fill")
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                // Submit Ticket
                VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                    SectionHeaderView(title: "Submit a Ticket", systemImage: "ticket.fill")
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Issue Description")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $ticketMessage)
                                .frame(height: 120)
                                .padding(8)
                                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        }
                        
                        AdminPrimaryButton("Submit Ticket") {
                            showTicketSuccess = true
                        }
                        .disabled(ticketMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(AdminSpacing.cardPadding)
                    .background(AdminColor.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
            .padding(.vertical, 24)
        }
        .background(AdminColor.background)"""
support_body_new = """    var body: some View {
        List {
            Section {
                contactRow(title: "Help Desk", value: "1-800-LMS-HELP", systemImage: "phone.circle.fill")
                contactRow(title: "Email Support", value: "support@lms.com", systemImage: "envelope.circle.fill")
                contactRow(title: "Live Chat", value: "Available 9 AM - 5 PM", systemImage: "message.circle.fill")
            } header: {
                Text("Contact Options").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Issue Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $ticketMessage)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                }
                .padding(.vertical, 4)
                
                Button("Submit Ticket") {
                    showTicketSuccess = true
                }
                .disabled(ticketMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: {
                Text("Submit a Ticket").font(.title3).fontWeight(.bold).foregroundStyle(.primary).textCase(nil)
            }
        }
        .listStyle(.insetGrouped)"""
content = content.replace(support_body_old, support_body_new)

with open('/Users/shailesh99394gmail.com/Downloads/LMS/StaffApp/Views/Admin/Profile/View/ProfileView.swift', 'w') as f:
    f.write(content)
