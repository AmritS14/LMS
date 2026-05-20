//
//  TemplateViewModel.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI
import Observation

// MARK: - Template ViewModel

/// Manages the state and business logic for Notification Templates (US-43).
/// Handles template listing, editing, and persistence with async/await.
@Observable
@MainActor
final class TemplateViewModel {

    // MARK: - State

    /// The complete list of notification templates.
    var templates: [NotificationTemplate]

    /// The template currently being edited (selected in detail view).
    var selectedTemplate: NotificationTemplate?

    /// The working copy of the body text in the editor.
    var editingBodyText: String = ""

    /// The working copy of the title in the editor.
    var editingTitle: String = ""
    
    /// The working copy of selected channels in the editor.
    var editingChannels: Set<NotificationChannel> = []

    /// Whether a save operation is in progress.
    var isSaving: Bool = false
    
    /// Error message for validation failures.
    var validationError: String? = nil

    /// Controls display of save success alert.
    var showSaveAlert: Bool = false

    /// Whether the editor has unsaved changes.
    var hasUnsavedChanges: Bool = false

    /// Search text for filtering templates.
    var searchText: String = ""

    // MARK: - Computed Properties

    /// Templates filtered by search text.
    var filteredTemplates: [NotificationTemplate] {
        guard !searchText.isEmpty else { return templates }
        let query = searchText.lowercased()
        return templates.filter { template in
            template.title.lowercased().contains(query) ||
            template.triggerEvent.rawValue.lowercased().contains(query)
        }
    }

    /// A preview of how the template body looks to the borrower,
    /// with placeholder tokens replaced by sample values.
    var previewBodyText: String {
        editingBodyText
            .replacingOccurrences(of: "{{borrower_name}}", with: "Aarav Mehta")
            .replacingOccurrences(of: "{{loan_id}}", with: "LN-2026-001234")
            .replacingOccurrences(of: "{{loan_amount}}", with: "5,00,000")
            .replacingOccurrences(of: "{{emi_amount}}", with: "12,450")
            .replacingOccurrences(of: "{{due_date}}", with: "25 May 2026")
            .replacingOccurrences(of: "{{payment_amount}}", with: "12,450")
            .replacingOccurrences(of: "{{remaining_balance}}", with: "4,87,550")
            .replacingOccurrences(of: "{{days_overdue}}", with: "5")
            .replacingOccurrences(of: "{{late_fee}}", with: "500")
            .replacingOccurrences(of: "{{document_list}}", with: "• Aadhaar Card\n• PAN Card\n• Salary Slip (last 3 months)")
    }

    // MARK: - Initialization

    init(templates: [NotificationTemplate] = NotificationTemplate.sampleTemplates) {
        self.templates = templates
    }

    // MARK: - Actions

    /// Selects a template for editing and loads its content.
    /// - Parameter template: The template to begin editing.
    func selectTemplate(_ template: NotificationTemplate) {
        selectedTemplate = template
        editingTitle = template.title
        editingBodyText = template.bodyText
        editingChannels = template.channels
        hasUnsavedChanges = false
        validationError = nil
    }

    /// Saves the current edits back to the template list.
    func updateTemplate() async {
        guard let selected = selectedTemplate else { return }
        
        // Validation
        if editingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "Template title cannot be empty."
            return
        }
        if editingBodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "Template body cannot be empty."
            return
        }
        if editingChannels.isEmpty {
            validationError = "At least one notification channel must be selected."
            return
        }
        
        validationError = nil
        isSaving = true
        defer { isSaving = false }

        // Simulate network persistence
        try? await Task.sleep(for: .milliseconds(800))

        guard let index = templates.firstIndex(where: { $0.id == selected.id }) else { return }
        templates[index].title = editingTitle
        templates[index].bodyText = editingBodyText
        templates[index].channels = editingChannels
        selectedTemplate = templates[index]
        
        AuditLogger.log(action: "Template Updated", details: "ID: \(selected.id), Title: \(editingTitle)")
        
        hasUnsavedChanges = false
        showSaveAlert = true
    }
    
    /// Creates a new empty template for a given trigger event.
    func createTemplate(for trigger: TriggerEvent, title: String) {
        let newTemplate = NotificationTemplate(title: title, triggerEvent: trigger, bodyText: "New Template Body")
        templates.append(newTemplate)
        AuditLogger.log(action: "Template Created", details: "Title: \(title), Trigger: \(trigger.rawValue)")
    }
    
    /// Deletes templates at the specified offsets.
    func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            let template = filteredTemplates[index]
            if let realIndex = templates.firstIndex(where: { $0.id == template.id }) {
                templates.remove(at: realIndex)
                AuditLogger.log(action: "Template Deleted", details: "Title: \(template.title)")
            }
        }
    }

    /// Marks the editor as having unsaved changes.
    func markDirty() {
        if !hasUnsavedChanges {
            hasUnsavedChanges = true
        }
    }
}
