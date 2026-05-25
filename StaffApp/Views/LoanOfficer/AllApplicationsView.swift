import SwiftUI

struct AllApplicationsView: View {
    @Environment(LoanOfficerStore.self) private var store
    @State private var searchText: String = ""
    @State private var statusFilter: ApplicationStatus?

    private var filtered: [OfficerApplication] {
        store.applications.filter { app in
            let matchesSearch = searchText.isEmpty
                || app.borrowerName.localizedCaseInsensitiveContains(searchText)
                || app.loanTypeLabel.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = statusFilter == nil || app.status == statusFilter
            return matchesSearch && matchesStatus
        }
    }

    var body: some View {
        List {
            Section {
                filterStrip
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if filtered.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No applications",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Adjust filters or search to see more results.")
                    )
                }
            } else {
                Section {
                    ForEach(filtered) { app in
                        NavigationLink(value: OfficerRoute.review(app.id)) {
                            applicationRow(app)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Applications")
        .searchable(text: $searchText, prompt: "Borrower or loan type")
    }

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                chip(label: "All", isSelected: statusFilter == nil) {
                    statusFilter = nil
                }
                ForEach([ApplicationStatus.submitted, .underReview,
                        .escalated, .additionalInfoRequired, .recommended,
                         .approved, .rejected], id: \.self) { status in
                    chip(label: status.displayLabel,
                         isSelected: statusFilter == status,
                         icon: status.icon) {
                        statusFilter = (statusFilter == status) ? nil : status
                    }
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
        }
    }

    private func chip(label: String, isSelected: Bool, icon: String? = nil,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2.weight(.semibold))
                }
                Text(label)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? Color.lmsAccent : Color.lmsFill,
                        in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func applicationRow(_ app: OfficerApplication) -> some View {
        HStack(spacing: Spacing.sm) {
            AvatarView(initials: app.borrowerInitials,
                       size: 44,
                       colors: app.riskLevel.gradient)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(app.borrowerName)
                        .font(.headline)
                    if app.fraudFlag {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
                Text("\(app.loanTypeLabel) • \(OfficerFormat.currency(app.loanAmount))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack(spacing: Spacing.xs) {
                    StatusBadge(app.status.displayLabel, tone: app.status.tone,
                                icon: app.status.icon, size: .small)
                    StatusBadge(app.riskLevel.rawValue, tone: app.riskLevel.tone,
                                icon: app.riskLevel.icon, size: .small)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
