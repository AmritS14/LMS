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
            Form {
                // Section 1: Trigger Event Selection Dropdown
                Section {
                    Picker("Trigger Event", selection: $selectedTrigger) {
                        ForEach(TriggerEvent.allCases) { trigger in
                            Label(trigger.rawValue, systemImage: trigger.systemImage)
                                .tag(trigger)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Section 2: Template Title
                Section {
                    TextField("Template Title (e.g. Approved Notification)", text: $title)
                } header: {
                    Text("Template Title")
                        .font(.adminSectionHeader)
                        .foregroundStyle(Color.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, 8)
                }

                // Section 3: Delivery Channels
                Section {
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
                            Text(channel.rawValue)
                        }
                        .tint(AdminColor.accent)
                    }
                } header: {
                    Text("Delivery Channels")
                        .font(.adminSectionHeader)
                        .foregroundStyle(Color.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, 8)
                }

                // Section 4: Message Body Text Editor
                Section {
                    TextEditor(text: $bodyText)
                        .font(.adminFormInput.monospacedDigit())
                        .frame(minHeight: 180)

                    // Placeholder tokens reference
                    placeholderHint
                } header: {
                    Text("Message Body")
                        .font(.adminSectionHeader)
                        .foregroundStyle(Color.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, 8)
                }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        if hasEditedChanges {
                            showCancelConfirmation = true
                        } else {
                            onDismiss()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                            .padding(8)
                            .background(Color(uiColor: .systemGray5), in: Circle())
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        handleCreateTemplate()
                    }
                    .fontWeight(.bold)
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
                .font(.adminCaption)
                .foregroundStyle(.secondary)
        }
    }

    private func placeholderToken(_ token: String, description: String) -> some View {
        HStack {
            Text(token)
                .font(.adminCaption.monospacedDigit())
                .foregroundStyle(AdminColor.accent)
            Spacer()
            Text(description)
                .font(.adminCaption)
                .foregroundStyle(.tertiary)
        }
    }
}
