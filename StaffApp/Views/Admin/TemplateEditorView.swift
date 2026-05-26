//
//  TemplateEditorView.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI

// MARK: - Template Editor View

/// Detail view for editing a notification template's body text.
/// Includes a TextEditor for modification and a "Preview" section
/// showing how the notification looks to the borrower with
/// placeholder tokens resolved to sample values.
struct TemplateEditorView: View {
    @Bindable var viewModel: TemplateViewModel

    var body: some View {
        Form {
            // Template metadata
            metadataSection

            // Channels selection
            channelsSection

            // Body text editor
            editorSection

            // Borrower-facing preview
            previewSection

            // Save button
            saveSection
        }
        .navigationTitle("Edit Template")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Template Saved", isPresented: $viewModel.showSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The notification template has been updated successfully.")
        }
        .alert("Validation Error", isPresented: Binding(
            get: { viewModel.validationError != nil },
            set: { if !$0 { viewModel.validationError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.validationError {
                Text(error)
            }
        }
    }

    // MARK: - Sections

    /// Shows the template title and trigger event.
    private var metadataSection: some View {
        Section {
            TextField("Template Title", text: $viewModel.editingTitle)
                .onChange(of: viewModel.editingTitle) { _, _ in
                    viewModel.markDirty()
                }

            if let template = viewModel.selectedTemplate {
                HStack {
                    Text("Trigger")
                    Spacer()
                    Text(template.triggerEvent.rawValue)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Template Info")
        }
    }

    /// Channels Selection Section
    private var channelsSection: some View {
        Section {
            ForEach(NotificationChannel.allCases.indices, id: \.self) { index in
                let channel = NotificationChannel.allCases[index]
                Toggle(isOn: Binding(
                    get: { viewModel.editingChannels.contains(channel) },
                    set: { isEnabled in
                        if isEnabled {
                            viewModel.editingChannels.insert(channel)
                        } else {
                            viewModel.editingChannels.remove(channel)
                        }
                        viewModel.markDirty()
                    }
                )) {
                    Text(channel.rawValue)
                }
                .tint(AdminColor.accent)
            }
        } header: {
            Text("Delivery Channels")
        }
    }

    /// TextEditor for modifying the notification body text.
    private var editorSection: some View {
        Section {
            TextEditor(text: $viewModel.editingBodyText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 200)
                .onChange(of: viewModel.editingBodyText) { _, _ in
                    viewModel.markDirty()
                }

            // Placeholder tokens reference
            placeholderHint
        } header: {
            Text("Message Body")
        }
    }

    /// Shows the borrower-facing preview with placeholders resolved.
    private var previewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Simulated notification header
                HStack(spacing: 10) {
                    Image(systemName: "bell.fill")
                        .font(.title3)
                        .foregroundStyle(AdminColor.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.editingTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("Just now")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Divider()

                // Resolved body text
                Text(viewModel.previewBodyText)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
        } header: {
            Text("Borrower Preview")
        }
    }

    /// Prominent save button.
    private var saveSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.updateTemplate()
                }
            } label: {
                Text("Save Template")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .disabled(!viewModel.hasUnsavedChanges)
        }
    }

    // MARK: - Subviews

    /// A hint showing available placeholder tokens.
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

    /// A single placeholder token row.
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

#Preview {
    let vm = TemplateViewModel()
    let _ = vm.selectTemplate(NotificationTemplate.sampleTemplates[0])

    NavigationStack {
        TemplateEditorView(viewModel: vm)
    }
}
