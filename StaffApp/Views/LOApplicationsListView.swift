import SwiftUI

struct LOApplicationsListView: View {
    @State private var searchText = ""
    @State private var selectedFilter = 0
    let filters = ["Active", "Incomplete", "Processed"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Status", selection: $selectedFilter) {
                    ForEach(0..<filters.count, id: \.self) { index in
                        Text(filters[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(Spacing.m)
                
                if selectedFilter == 2 {
                    LOEmptyStateView(
                        icon: "checkmark.seal",
                        title: "All Caught Up!",
                        message: "You have no processed applications at the moment."
                    )
                } else {
                    List {
                        ForEach(0..<5, id: \.self) { _ in
                            NavigationLink {
                                LOApplicationDetailView()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Application #APP-882")
                                            .font(.lmsHeadline)
                                        Text("John Smith • Personal Loan")
                                            .font(.lmsCaption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    StatusBadge(filters[selectedFilter], tone: selectedFilter == 0 ? .success : .info)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Applications")
            .searchable(text: $searchText, prompt: "Search borrower or ID")
        }
    }
}

struct LOEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            Text(title)
                .font(.lmsTitle2)
            Text(message)
                .font(.lmsBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.l)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
