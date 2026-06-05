import SwiftUI

// MARK: - Tab 3: Reports

struct ManagerReportsView: View {
    @Environment(ManagerStore.self) private var store
    @State private var showFormatPicker = false
    @State private var pendingReportType: ReportKind?
    @State private var previewReport: ReportItem?
    @State private var showClearConfirmation = false


    var body: some View {
        List {
            // MARK: Generate Reports

            Section("Generate Reports") {
                reportActionRow(icon: "doc.text.fill", title: "Daily Report",
                                subtitle: "End of day summary", type: .daily, color: .lmsAccent)
                reportActionRow(icon: "calendar", title: "Weekly Report",
                                subtitle: "7-day rolling performance", type: .weekly, color: .lmsSuccess)
                reportActionRow(icon: "chart.bar.doc.horizontal.fill", title: "Monthly Report",
                                subtitle: "Comprehensive analytics", type: .monthly, color: .lmsWarning)
                reportActionRow(icon: "exclamationmark.triangle.fill", title: "NPA Analysis",
                                subtitle: "Non-performing asset details", type: .npa, color: .lmsDanger)
            }

            // MARK: Report History

            Section {
                if store.reportHistory.isEmpty {
                    ContentUnavailableView("No reports yet",
                                           systemImage: "doc.text.magnifyingglass",
                                           description: Text("Generate your first report above."))
                        .padding(.vertical, Spacing.m)
                } else {
                    ForEach(store.reportHistory) { report in
                        reportRow(report)
                    }
                    .onDelete { offsets in
                        offsets.forEach { idx in
                            store.deleteReport(store.reportHistory[idx])
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Report History")
                    Spacer()
                    if !store.reportHistory.isEmpty {
                        Text("\(store.reportHistory.count) files")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            // MARK: Storage

            Section {
                HStack {
                    Label("Reports Storage", systemImage: "internaldrive")
                    Spacer()
                    Text(store.reportsStorageSizeString)
                        .foregroundStyle(.secondary)
                }

                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Label("Clear Old Exports", systemImage: "trash")
                }
            } footer: {
                Text("Reports older than 90 days are automatically removed.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Reports")
        .toolbarTitleDisplayMode(.large)
        .confirmationDialog("Select Format", isPresented: $showFormatPicker,
                            titleVisibility: .visible) {
            Button("PDF") {
                if let type = pendingReportType {
                    store.generateReport(type: type, format: .pdf)
                }
            }
            Button("CSV") {
                if let type = pendingReportType {
                    store.generateReport(type: type, format: .csv)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Are you sure you want to clear old exports?", isPresented: $showClearConfirmation,
                            titleVisibility: .visible) {
            Button("Clear Old Exports", role: .destructive) {
                store.clearOldReports()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $previewReport) { report in
            reportPreviewSheet(report)
        }
        .refreshable { await store.refreshAll() }
    }

    // MARK: Quick Action Row

    private func reportActionRow(icon: String, title: String, subtitle: String,
                                  type: ReportKind, color: Color) -> some View {
        Button {
            pendingReportType = type
            showFormatPicker = true
        } label: {
            HStack(spacing: Spacing.m) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Report Row

    private func reportRow(_ report: ReportItem) -> some View {
        Button {
            if report.status == .completed {
                previewReport = report
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: report.formatIcon)
                    .font(.title2)
                    .foregroundStyle(report.formatColor)
                    .frame(width: 40, height: 40)
                    .background(report.formatColor.opacity(0.15),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(report.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if report.status == .generating {
                            ProgressView().progressViewStyle(.circular)
                                .controlSize(.mini)
                            Text("Generating...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: report.status.icon)
                                .font(.caption2)
                                .foregroundStyle(statusColor(report.status))
                            Text(report.status.rawValue)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(statusColor(report.status))
                        }

                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Text("\(report.format.rawValue.uppercased()) • \(report.size)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(report.dateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if report.status == .completed {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if report.status == .completed {
                Button {
                    previewReport = report
                } label: {
                    Label("Preview", systemImage: "eye")
                }

                shareButton(report)

                Button(role: .destructive) {
                    store.deleteReport(report)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    // MARK: Report Preview Sheet

    private func reportPreviewSheet(_ report: ReportItem) -> some View {
        NavigationStack {
            Group {
                switch report.snapshot {
                case .daily(let data):
                    DailyReportPreviewView(report: report, data: data)
                case .weekly(let data):
                    WeeklyReportPreviewView(report: report, data: data)
                case .monthly(let data):
                    MonthlyReportPreviewView(report: report, data: data)
                case .npa(let data):
                    NPAReportPreviewView(report: report, data: data)
                case nil:
                    ContentUnavailableView("No Preview", systemImage: "doc.questionmark",
                                           description: Text("Report data was not captured."))
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { previewReport = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    shareButton(report)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    previewReport = nil
                } label: {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(Spacing.m)
                .background(.bar)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Share

    @ViewBuilder
    private func shareButton(_ report: ReportItem) -> some View {
        if let url = report.fileURL, FileManager.default.fileExists(atPath: url.path) {
            ShareLink(item: url, subject: Text(report.name)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        } else {
            Label("Share", systemImage: "square.and.arrow.up")
                .foregroundStyle(.tertiary)
        }
    }

    private func reportPeriod(_ type: ReportKind) -> String {
        switch type {
        case .daily: return Date.now.formatted(.dateTime.month().day().year())
        case .weekly: return "Week \(Calendar.current.component(.weekOfYear, from: .now)), \(Calendar.current.component(.year, from: .now))"
        case .monthly: return Date.now.formatted(.dateTime.month(.wide).year())
        case .npa, .collectionEfficiency: return "Q1 2026"
        }
    }

    private func statusColor(_ status: ReportStatus) -> Color {
        switch status.tone {
        case .success: return .lmsSuccess
        case .warning: return .lmsWarning
        case .danger: return .lmsDanger
        default: return .secondary
        }
    }
}

#Preview {
    ManagerNavigationStack {
        ManagerReportsView()
    }
    .environment(ManagerStore.preview)
    .environment(SessionStore())
}
