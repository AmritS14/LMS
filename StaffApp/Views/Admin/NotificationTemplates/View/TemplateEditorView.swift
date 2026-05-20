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

            // Body text editor
            editorSection

            // Channels selection
            channelsSection

            // Borrower-facing preview
            previewSection

            // Save button
            saveSection
        }
        .formStyle(.grouped)
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
            HStack {
                Label("Title", systemImage: "textformat")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("Template Title", text: $viewModel.editingTitle)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: viewModel.editingTitle) { _, _ in
                        viewModel.markDirty()
                    }
            }

            if let template = viewModel.selectedTemplate {
                HStack {
                    Label("Trigger", systemImage: template.triggerEvent.systemImage)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(template.triggerEvent.rawValue)
                        .foregroundStyle(.primary)
                }
            }
        } header: {
            SectionHeaderView(title: "Template Info", systemImage: "info.circle")
        }
    }

    /// TextEditor for modifying the notification body text.
    private var editorSection: some View {
        Section {
            TextEditor(text: $viewModel.editingBodyText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 200)
                .scrollContentBackground(.hidden)
                .onChange(of: viewModel.editingBodyText) { _, _ in
                    viewModel.markDirty()
                }

            // Placeholder tokens reference
            placeholderHint
        } header: {
            SectionHeaderView(title: "Message Body", systemImage: "text.alignleft")
        }
    }
    
    /// Channels Selection Section
    private var channelsSection: some View {
        Section {
            ForEach(NotificationChannel.allCases) { channel in
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
                    Label(channel.rawValue, systemImage: channel.systemImage)
                }
            }
        } header: {
            SectionHeaderView(title: "Delivery Channels", systemImage: "paperplane.fill")
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
                        .foregroundStyle(Color.accentColor)

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
            .padding(.vertical, 4)
        } header: {
            SectionHeaderView(title: "Borrower Preview", systemImage: "eye")
        }
    }

    /// Prominent save button.
    private var saveSection: some View {
        Section {
            PrimaryButton("Save Template", isLoading: viewModel.isSaving) {
                Task {
                    await viewModel.updateTemplate()
                }
            }
            .disabled(!viewModel.hasUnsavedChanges)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
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
                .foregroundStyle(Color.accentColor)
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
