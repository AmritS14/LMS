import SwiftUI

// MARK: - Risk Alerts

struct RiskAlertsView: View {
    @Environment(ManagerStore.self) private var store
    @State private var filterSeverity: RiskAlertSeverity?

    private var filteredAlerts: [RiskAlert] {
        guard let severity = filterSeverity else { return store.riskAlerts }
        return store.riskAlerts.filter { $0.severity == severity }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter Picker (Native segmented control)
            Picker("Severity", selection: $filterSeverity) {
                Text("All").tag(RiskAlertSeverity?.none)
                ForEach(RiskAlertSeverity.allCases, id: \.self) { severity in
                    Text(severity.rawValue).tag(RiskAlertSeverity?.some(severity))
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
            .background(Color.lmsBackground)

            if filteredAlerts.isEmpty {
                ContentUnavailableView("No alerts",
                                       systemImage: "checkmark.shield",
                                       description: Text("No risk alerts for the selected filter."))
                    .frame(maxHeight: .infinity)
            } else {
                List {
                    // Summary
                    if store.unreadRiskAlertCount > 0 {
                        Section {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "exclamationmark.shield.fill")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Color.lmsDanger)
                                    .frame(width: 40, height: 40)
                                    .background(Color.lmsDanger.opacity(0.12),
                                                in: RoundedRectangle(cornerRadius: CornerRadius.small))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(store.unreadRiskAlertCount) unread alerts")
                                        .font(.headline)
                                    Text("Review and take action on high-risk items")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }

                    // Alerts
                    Section("Risk Alerts") {
                        ForEach(filteredAlerts) { alert in
                            alertRow(alert)
                                .swipeActions(edge: .leading) {
                                    Button {
                                        store.markRiskAlertRead(alert)
                                    } label: {
                                        Label("Read", systemImage: "envelope.open")
                                    }
                                    .tint(.lmsInfo)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        store.dismissRiskAlert(alert)
                                    } label: {
                                        Label("Dismiss", systemImage: "xmark.circle")
                                    }
                                }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Risk Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Alert Row

    private func alertRow(_ alert: RiskAlert) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: alert.severity.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(severityColor(alert.severity))
                .frame(width: 36, height: 36)
                .background(severityColor(alert.severity).opacity(0.12),
                             in: RoundedRectangle(cornerRadius: CornerRadius.small))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Spacer()
                    if !alert.isRead {
                        Circle().fill(Color.lmsDanger).frame(width: 8, height: 8)
                    }
                }

                Text(alert.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                HStack(spacing: Spacing.xs) {
                    StatusBadge(alert.severity.rawValue, tone: alert.severity.tone,
                                icon: alert.severity.icon, size: .small)
                    Text("•")
                        .foregroundStyle(.quaternary)
                    Text(alert.loanReferenceCode)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                    Text("•")
                        .foregroundStyle(.quaternary)
                    Text(alert.timeText)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture {
            store.markRiskAlertRead(alert)
        }
    }


    private func severityColor(_ severity: RiskAlertSeverity) -> Color {
        switch severity {
        case .critical: .lmsDanger
        case .high: .lmsWarning
        case .medium: .lmsInfo
        }
    }
}

#Preview {
    NavigationStack {
        RiskAlertsView()
    }
    .environment(ManagerStore.preview)
}
