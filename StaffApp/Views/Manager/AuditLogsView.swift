import SwiftUI

// MARK: - Audit Logs

struct AuditLogsView: View {
    @Environment(ManagerStore.self) private var store
    @State private var searchText = ""
    @State private var filterAction: String? = nil

    private var actions: [String] {
        Array(Set(store.auditLogs.map(\.action))).sorted()
    }

    private var filteredLogs: [ManagerAuditLogEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.auditLogs.filter { log in
            // Action filter
            if let filter = filterAction, log.action != filter { return false }
            // Search
            guard !query.isEmpty else { return true }
            return log.loanReferenceCode.localizedCaseInsensitiveContains(query)
                || log.managerName.localizedCaseInsensitiveContains(query)
                || log.action.localizedCaseInsensitiveContains(query)
        }
    }

    private var groupedLogs: [(String, [ManagerAuditLogEntry])] {
        let grouped = Dictionary(grouping: filteredLogs) { log in
            Formatting.date(log.timestamp)
        }
        return grouped.sorted { $0.value.first!.timestamp > $1.value.first!.timestamp }
    }

    var body: some View {
        List {
            // Filter chips
            if !actions.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.s) {
                            filterChip("All", isSelected: filterAction == nil) {
                                filterAction = nil
                            }
                            ForEach(actions, id: \.self) { action in
                                filterChip(action, isSelected: filterAction == action) {
                                    filterAction = action
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: Spacing.s, leading: Spacing.m, bottom: Spacing.s, trailing: Spacing.m))
                    .listRowBackground(Color.clear)
                }
            }

            // Logs grouped by date
            if filteredLogs.isEmpty {
                Section {
                    ContentUnavailableView("No audit logs found",
                                           systemImage: "list.clipboard",
                                           description: Text("Try a different search or filter."))
                }
            } else {
                ForEach(groupedLogs, id: \.0) { date, logs in
                    Section(date) {
                        ForEach(logs) { log in
                            logRow(log)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Audit Logs")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search loan ID or manager")
        .refreshable { await store.refreshAll() }
    }

    // MARK: Log Row

    private func logRow(_ log: ManagerAuditLogEntry) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: actionIcon(log.action))
                .font(.body.weight(.medium))
                .foregroundStyle(actionColor(log.action))
                .frame(width: 32, height: 32)
                .background(actionColor(log.action).opacity(0.12),
                             in: RoundedRectangle(cornerRadius: CornerRadius.small))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(log.loanReferenceCode)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                    Spacer()
                    StatusBadge(log.status.rawValue, tone: log.status.tone, size: .small)
                }
                HStack(spacing: Spacing.xs) {
                    Text(log.action)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("•")
                        .foregroundStyle(.quaternary)
                    Text(log.managerName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("•")
                        .foregroundStyle(.quaternary)
                    Text(log.timeText)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: Filter Chip

    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(isSelected ? Color.lmsAccent : Color.lmsFill, in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

    private func actionIcon(_ action: String) -> String {
        switch action.lowercased() {
        case "approved": return "checkmark.circle.fill"
        case "rejected": return "xmark.circle.fill"
        case "sent back": return "arrow.uturn.backward.circle.fill"
        case "escalated": return "arrow.up.right.circle.fill"
        case "policy updated": return "gearshape.circle.fill"
        default: return "circle.fill"
        }
    }

    private func actionColor(_ action: String) -> Color {
        switch action.lowercased() {
        case "approved": return .lmsSuccess
        case "rejected": return .lmsDanger
        case "sent back": return .lmsWarning
        case "escalated": return .lmsInfo
        case "policy updated": return .lmsAccent
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        AuditLogsView()
    }
    .environment(ManagerStore.preview)
}
