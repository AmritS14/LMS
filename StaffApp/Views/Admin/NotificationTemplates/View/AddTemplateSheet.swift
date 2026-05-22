//
//  AddTemplateSheet.swift
//  LMS
//
//  Created by Antigravity on 22/05/26.
//

import SwiftUI

struct AddTemplateSheet: View {
    @Bindable var viewModel: TemplateViewModel
    let onDismiss: () -> Void

    @State private var title: String = ""
    @State private var selectedTrigger: TriggerEvent = .loanApproved
    @State private var bodyText: String = "Dear {{borrower_name}},\n\nCongratulations! Your application has been processed.\n\nBest regards,\nLMS Team"
    @State private var channels: Set<NotificationChannel> = [.email, .inApp]
    
    @State private var showCancelConfirmation = false
    @State private var errorMessage: String? = nil

    private var hasEditedChanges: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedTrigger != .loanApproved ||
        bodyText != "Dear {{borrower_name}},\n\nCongratulations! Your application has been processed.\n\nBest regards,\nLMS Team" ||
        channels != Set<NotificationChannel>([.email, .inApp])
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AdminSpacing.sectionGap) {
                    
                    // Section 1: Trigger Event Selection Dropdown
                    VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                        SectionHeaderView(title: "Trigger Event", systemImage: "bolt.fill")
                        
                        Menu {
                            ForEach(TriggerEvent.allCases) { trigger in
                                Button {
                                    selectedTrigger = trigger
                                } label: {
                                    HStack {
                                        Text(trigger.rawValue)
                                        Spacer()
                                        Image(systemName: trigger.systemImage)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedTrigger.systemImage)
                                    .foregroundColor(AdminColor.accent)
                                Text(selectedTrigger.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                AdminColor.cardBackground,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }

                    // Section 2: Template Title
                    VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                        SectionHeaderView(title: "Template Title", systemImage: "tag")
                        
                        TextField("e.g. Approved Notification", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .padding(AdminSpacing.cardPadding)
                            .background(
                                AdminColor.cardBackground,
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                    }

                    // Section 3: Delivery Channels
                    VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                        SectionHeaderView(title: "Delivery Channels", systemImage: "paperplane.fill")

                        VStack(spacing: Spacing.s) {
                            ForEach(NotificationChannel.allCases.indices, id: \.self) { index in
                                let channel = NotificationChannel.allCases[index]
                                Toggle(isOn: Binding(
                                    get: { channels.contains(channel) },
                                    set: { isEnabled in
                                        if isEnabled {
                                            channels.insert(channel)
                                        } else {
                                            channels.remove(channel)
                                        }
                                    }
                                )) {
                                    Label(channel.rawValue, systemImage: channel.systemImage)
                                }

                                if index < NotificationChannel.allCases.count - 1 {
                                    Divider()
                                }
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
                    }

                    // Section 4: Message Body Text Editor
                    VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
                        SectionHeaderView(title: "Message Body", systemImage: "text.alignleft")

                        VStack(spacing: Spacing.s) {
                            TextEditor(text: $bodyText)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 180)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)

                            Divider()

                            // Placeholder tokens reference
                            placeholderHint
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
                    }
                }
                .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
                .padding(.vertical, 24)
            }
            .background(AdminColor.background)
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasEditedChanges {
                            showCancelConfirmation = true
                        } else {
                            onDismiss()
                        }
                    }
                    .tint(AdminColor.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        handleCreateTemplate()
                    }
                    .tint(AdminColor.accent)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || channels.isEmpty)
                }
            }
            .confirmationDialog(
                "Unsaved Changes",
                isPresented: $showCancelConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard Changes", role: .destructive) {
                    onDismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved template details. Do you want to leave without saving?")
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
        }
    }

    private func handleCreateTemplate() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let isDuplicate = viewModel.templates.contains { $0.title.lowercased() == trimmedTitle.lowercased() }
        
        if isDuplicate {
            errorMessage = "A notification template with this title already exists."
            return
        }

        viewModel.createTemplate(
            for: selectedTrigger,
            title: trimmedTitle,
            bodyText: bodyText,
            channels: channels
        )
        onDismiss()
    }

    private var placeholderHint: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 4) {
                placeholderToken("{{borrower_name}}", description: "Borrower's full name")
                placeholderToken("{{loan_id}}", description: "Loan application ID")
                placeholderToken("{{loan_amount}}", description: "Sanctioned loan amount")
                placeholderToken("{{emi_amount}}", description: "Monthly EMI amount")
                placeholderToken("{{due_date}}", description: "Payment due date")
                placeholderToken("{{payment_amount}}", description: "Amount received")
                placeholderToken("{{remaining_balance}}", description: "Outstanding balance")
                placeholderToken("{{days_overdue}}", description: "Days past due date")
                placeholderToken("{{late_fee}}", description: "Late payment fee")
                placeholderToken("{{document_list}}", description: "Required documents")
            }
        } label: {
            Label("Available Placeholders", systemImage: "curlybraces")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func placeholderToken(_ token: String, description: String) -> some View {
        HStack {
            Text(token)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(AdminColor.accent)
            Spacer()
            Text(description)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
