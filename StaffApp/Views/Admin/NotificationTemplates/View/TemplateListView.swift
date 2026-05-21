//
//  TemplateListView.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI

// MARK: - Template List View

/// The main list view for Notification Templates (US-43).
/// Displays all available trigger-based templates.
/// Tapping a row navigates to the TemplateEditorView.
struct TemplateListView: View {
    @Bindable var viewModel: TemplateViewModel
    
    @State private var showAddAlert = false
    @State private var newTemplateTitle = ""
    @State private var selectedTrigger: TriggerEvent = .loanApproved

    var body: some View {
        List {
            // Template list grouped by trigger category
            templatesSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AdminColor.background)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search templates or triggers"
        )
        .navigationTitle("Template")
        .overlay {
            if viewModel.filteredTemplates.isEmpty && !viewModel.searchText.isEmpty {
                EmptyStateView(
                    title: "No Templates Found",
                    subtitle: "No templates match \"\(viewModel.searchText)\".",
                    systemImage: "bell.slash"
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newTemplateTitle = ""
                    showAddAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New Notification Template", isPresented: $showAddAlert) {
            TextField("Template Title", text: $newTemplateTitle)
            Picker("Trigger Event", selection: $selectedTrigger) {
                ForEach(TriggerEvent.allCases) { trigger in
                    Text(trigger.rawValue).tag(trigger)
                }
            }
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                viewModel.createTemplate(for: selectedTrigger, title: newTemplateTitle)
            }
            .disabled(newTemplateTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter a title and select a trigger event for the new template.")
        }
    }

    // MARK: - Sections

    /// The scrollable list of template rows with navigation links.
    private var templatesSection: some View {
        Section {
            ForEach(viewModel.filteredTemplates) { template in
                ZStack {
                    NavigationLink(value: template) {
                        EmptyView()
                    }
                    .opacity(0)

                    TemplateRowView(
                        template: template,
                        isSelected: viewModel.selectedTemplate?.id == template.id
                    )
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: AdminSpacing.cardRowVerticalInset,
                    leading: AdminSpacing.cardRowHorizontalInset,
                    bottom: AdminSpacing.cardRowVerticalInset,
                    trailing: AdminSpacing.cardRowHorizontalInset
                ))
            }
            .onDelete { offsets in
                viewModel.deleteTemplates(at: offsets)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TemplateListView(viewModel: TemplateViewModel())
    }
}
