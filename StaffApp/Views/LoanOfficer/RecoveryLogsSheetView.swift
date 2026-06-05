import SwiftUI

struct RecoveryLogsSheetView: View {
    let borrowerID: UUID
    let borrowerName: String
    @Environment(AppViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss

    @State private var logs: [RecoveryLog] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading Logs...")
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Failed to Load",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if logs.isEmpty {
                    ContentUnavailableView(
                        "No Logs Found",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("No recovery logs exist for \(borrowerName).")
                    )
                } else {
                    List(logs) { log in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(log.actionType.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.headline)
                                Spacer()
                                Text(log.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack {
                                Text("Outcome:")
                                    .font(.subheadline)
                                    .bold()
                                Text(log.outcome)
                                    .font(.subheadline)
                            }

                            if let notes = log.notes, !notes.isEmpty {
                                Text("Remarks:")
                                    .font(.subheadline)
                                    .bold()
                                    .padding(.top, 2)
                                Text(notes)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }

                            if let scheduled = log.scheduledDate {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                    Text("Follow-up: \(scheduled.formatted(date: .abbreviated, time: .shortened))")
                                }
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Logs: \(borrowerName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadLogs()
            }
        }
    }

    private func loadLogs() async {
        do {
            isLoading = true
            errorMessage = nil
            logs = try await viewModel.fetchRecoveryLogs(for: borrowerID)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
