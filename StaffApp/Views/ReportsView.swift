import SwiftUI

struct ReportsView: View {
    @State private var generatingReport: String?
    @State private var showGenerateConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: Quick Actions

                Section {
                    VStack(spacing: Spacing.m) {
                        HStack(spacing: Spacing.m) {
                            reportQuickAction(
                                icon: "doc.text.fill",
                                title: "Daily",
                                format: "PDF",
                                color: .lmsAccent
                            )
                            reportQuickAction(
                                icon: "calendar",
                                title: "Weekly",
                                format: "CSV",
                                color: .lmsSuccess
                            )
                            reportQuickAction(
                                icon: "chart.bar.doc.horizontal.fill",
                                title: "Monthly",
                                format: "PDF",
                                color: .lmsWarning
                            )
                            reportQuickAction(
                                icon: "exclamationmark.triangle.fill",
                                title: "NPA",
                                format: "PDF",
                                color: .lmsDanger
                            )
                        }
                    }
                    .listRowInsets(EdgeInsets(top: Spacing.m, leading: Spacing.m, bottom: Spacing.m, trailing: Spacing.m))
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Generate Reports")
                }

                // MARK: Recent Exports

                Section {
                    if Self.recentExports.isEmpty {
                        Text("No reports yet")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, Spacing.m)
                    } else {
                        ForEach(Self.recentExports) { export in
                            exportRow(export)
                        }
                    }
                } header: {
                    HStack {
                        Text("Recent Exports")
                        Spacer()
                        if !Self.recentExports.isEmpty {
                            Text("\(Self.recentExports.count) files")
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
                        Text("12.4 MB")
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        // TODO: clear old exports
                    } label: {
                        Label("Clear Old Exports", systemImage: "trash")
                    }
                } footer: {
                    Text("Reports older than 90 days are automatically removed.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Reports")
        }
    }

    // MARK: Quick Action Tile

    private func reportQuickAction(icon: String, title: String, format: String, color: Color) -> some View {
        Button {
            generatingReport = title
            // TODO: trigger actual report generation
        } label: {
            VStack(spacing: Spacing.s) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))

                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)

                Text(format)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: Export Row

    private func exportRow(_ export: ReportExport) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: export.formatIcon)
                .font(.title2)
                .foregroundStyle(export.formatColor)
                .frame(width: 40, height: 40)
                .background(export.formatColor.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(export.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: Spacing.xs) {
                    Text(export.format)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(export.formatColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(export.formatColor.opacity(0.12), in: Capsule())

                    Text("·")
                        .foregroundStyle(.quaternary)

                    Text(export.size)
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text("·")
                        .foregroundStyle(.quaternary)

                    Text(export.date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Button {
                // TODO: share / download
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.body)
                    .foregroundStyle(Color.lmsAccent)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: Mock Data

    private struct ReportExport: Identifiable {
        let id = UUID()
        let name: String
        let format: String
        let size: String
        let date: String

        var formatIcon: String {
            switch format {
            case "CSV": return "tablecells"
            case "PDF": return "doc.richtext"
            default: return "doc"
            }
        }

        var formatColor: Color {
            switch format {
            case "CSV": return .lmsSuccess
            case "PDF": return .lmsDanger
            default: return .secondary
            }
        }
    }

    private static let recentExports: [ReportExport] = [
        ReportExport(name: "Daily Report — May 25", format: "PDF", size: "1.2 MB", date: "2h ago"),
        ReportExport(name: "Weekly Report — W21", format: "CSV", size: "340 KB", date: "Yesterday"),
        ReportExport(name: "Monthly Report — April", format: "PDF", size: "4.8 MB", date: "3 days ago"),
        ReportExport(name: "NPA Analysis — Q1 2026", format: "PDF", size: "2.1 MB", date: "1 week ago"),
        ReportExport(name: "Daily Report — May 24", format: "PDF", size: "1.1 MB", date: "1 week ago")
    ]
}

#Preview {
    ReportsView()
}
