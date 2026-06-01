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
    
    @State private var showAddTemplateSheet = false
    @State private var selectedTemplateForEdit: NotificationTemplate? = nil

    var body: some View {
        List {
            ForEach(viewModel.filteredTemplates) { template in
                Button {
                    selectedTemplateForEdit = template
                } label: {
                    HStack {
                        TemplateRowView(
                            template: template,
                            isSelected: viewModel.selectedTemplate?.id == template.id
                        )
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tertiary)
                    }
                }
                .tint(.primary)
            }
            .onDelete { offsets in
                viewModel.deleteTemplates(at: offsets)
            }
        }
        .listStyle(.insetGrouped)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search templates or triggers"
        )
        .navigationTitle("Template")
        .navigationBarTitleDisplayMode(.inline)
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
                    showAddTemplateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTemplateSheet) {
            AddTemplateSheet(viewModel: viewModel) {
                showAddTemplateSheet = false
            }
        }
        .navigationDestination(item: $selectedTemplateForEdit) { template in
            TemplateEditorView(viewModel: viewModel)
                .onAppear {
                    viewModel.selectTemplate(template)
                }
                .onDisappear {
                    selectedTemplateForEdit = nil
                }
        }
    }
}

#Preview {
    NavigationStack {
        TemplateListView(viewModel: TemplateViewModel())
    }
}
