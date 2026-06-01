import SwiftUI

@MainActor
@Observable
final class AuditViewModel {
    var entries: [AuditEntry] = []
    var isLoading = false
    var error: String? = nil

    private var environment: AppEnvironment?

    func configure(environment: AppEnvironment?) {
        self.environment = environment
    }

    func loadLogs() async {
        guard let environment else { return }
        
        isLoading = true
        error = nil
        do {
            self.entries = try await environment.admin.fetchAuditLogs()
        } catch {
            self.error = error.localizedDescription
            print("Failed to fetch audit logs: \(error)")
        }
        isLoading = false
    }

    func generateCSV(from filteredEntries: [AuditEntry]) -> URL? {
        var csvString = "ID,Timestamp,Actor Role,Actor ID,Action,Entity Type,Entity ID,Metadata\n"
        
        let formatter = ISO8601DateFormatter()
        
        for entry in filteredEntries {
            let id = entry.id.uuidString
            let timestamp = formatter.string(from: entry.timestamp)
            let actorRole = entry.actorRole.displayName
            let actorID = entry.actorID.uuidString
            let action = entry.action.replacingOccurrences(of: "\"", with: "\"\"")
            let entityType = entry.entityType.replacingOccurrences(of: "\"", with: "\"\"")
            let entityID = entry.entityID.uuidString
            
            let metaString = entry.metadata.map { "\($0.key): \($0.value)" }.joined(separator: "; ")
            let escapedMeta = metaString.replacingOccurrences(of: "\"", with: "\"\"")
            
            let row = "\(id),\(timestamp),\(actorRole),\(actorID),\"\(action)\",\"\(entityType)\",\(entityID),\"\(escapedMeta)\"\n"
            csvString.append(row)
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("AuditLogs_\(Date().timeIntervalSince1970).csv")
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }
}

struct AuditListView: View {
    @State private var viewModel = AuditViewModel()
    @Environment(\.appEnvironment) private var env
    
    @State private var searchText = ""
    @State private var selectedRole: String = "All Roles"
    
    @State private var exportURL: URL?
    @State private var showExportSheet = false
    
    private let roles = ["All Roles", "Admin", "Manager", "Loan Officer", "Borrower"]
    
    private var filteredEntries: [AuditEntry] {
        viewModel.entries.filter { entry in
            var matches = true
            
            if selectedRole != "All Roles" && entry.actorRole.displayName != selectedRole {
                matches = false
            }
            
            if !searchText.isEmpty {
                let search = searchText.lowercased()
                if !entry.action.lowercased().contains(search) &&
                   !entry.entityType.lowercased().contains(search) {
                    matches = false
                }
            }
            
            return matches
        }
    }
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let error = viewModel.error {
                ContentUnavailableView("Failed to Load Logs", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if filteredEntries.isEmpty {
                ContentUnavailableView("No Logs Found", systemImage: "doc.text.magnifyingglass", description: Text("No audit logs match your search criteria."))
            } else {
                ForEach(filteredEntries, id: \.id) { entry in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(entry.action)
                                .font(.lmsHeadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.lmsCaption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("\(entry.actorRole.displayName) • \(entry.entityType)")
                            .font(.lmsSubheadline)
                            .foregroundStyle(.secondary)
                            
                        if let details = entry.metadata.first {
                            Text("\(details.key.capitalized): \(details.value)")
                                .font(.lmsCaption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
        }
        .navigationTitle("All Audit Logs")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search actions or entities")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        if let url = viewModel.generateCSV(from: filteredEntries) {
                            exportURL = url
                            showExportSheet = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Menu {
                        Picker("Role", selection: $selectedRole) {
                            ForEach(roles, id: \.self) { role in
                                Text(role).tag(role)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(selectedRole == "All Roles" ? .primary : Color.lmsInfo)
                    }
                }
            }
        }
        .task {
            viewModel.configure(environment: env)
            await viewModel.loadLogs()
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
}

#Preview {
    NavigationStack {
        AuditListView()
    }
}
