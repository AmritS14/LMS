import SwiftUI

struct AuditTrailView: View {
    private let entries = AdminSeedData.auditEntries

    var body: some View {
        List {
            if entries.isEmpty {
                EmptyStateView(
                    title: "No Audit Entries",
                    subtitle: "Actions will appear here once admins start reviewing accounts.",
                    systemImage: "list.clipboard"
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(entry.action)
                                .font(.lmsHeadline)
                            Spacer()
                            StatusBadge(entry.actorRole.displayName, tone: .info, size: .small)
                        }

                        Text(entry.entityType)
                            .font(.lmsSubheadline)
                            .foregroundStyle(.secondary)

                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.lmsCaption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Audit Trail")
        .navigationBarTitleDisplayMode(.inline)
        .background(AdminColor.background)
    }
}