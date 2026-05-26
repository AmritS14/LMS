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

    var body: some View {
        List {
            ForEach(viewModel.filteredTemplates) { template in
                NavigationLink(value: template) {
                    TemplateRowView(
                        template: template,
                        isSelected: viewModel.selectedTemplate?.id == template.id
                    )
                }
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
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    NavigationStack {
        TemplateListView(viewModel: TemplateViewModel())
    }
}
