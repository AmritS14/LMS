import SwiftUI

// MARK: - Officer Detail

struct OfficerDetailView: View {
    let officerName: String
    @Environment(ManagerStore.self) private var store

    private var officer: OfficerPerformanceData? {
        store.officerPerformance.first { $0.name == officerName }
    }

    var body: some View {
        Group {
            if let officer {
                content(officer)
            } else {
                ContentUnavailableView("Officer not found",
                                       systemImage: "person.slash",
                                       description: Text("This officer is no longer in the team."))
            }
        }
        .navigationTitle(officerName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ officer: OfficerPerformanceData) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.l) {
                headerSection(officer)
                metricsSection(officer)
                recentDecisionsSection(officer)
            }
            .padding(Spacing.m)
        }
        .background(Color.lmsBackground)
    }

    // MARK: Header

    private func headerSection(_ officer: OfficerPerformanceData) -> some View {
        VStack(spacing: Spacing.m) {
            AvatarView(initials: officer.initials, size: 72)

            VStack(spacing: 4) {
                Text(officer.name)
                    .font(.lmsTitle2)
                Text("Loan Officer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.l)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    // MARK: Metrics

    private func metricsSection(_ officer: OfficerPerformanceData) -> some View {
        SectionCard(title: "Performance Metrics") {
            HStack(spacing: Spacing.m) {
                metricItem(
                    value: "\(officer.applicationsProcessed)",
                    label: "Applications\nProcessed",
                    color: .lmsAccent
                )
                metricItem(
                    value: Formatting.percent(officer.approvalRate, fractionDigits: 0),
                    label: "Approval\nSuccess",
                    color: .lmsSuccess
                )
            }
            HStack(spacing: Spacing.m) {
                metricItem(
                    value: officer.avgDecisionTime,
                    label: "Avg Decision\nTime",
                    color: .lmsInfo
                )
                metricItem(
                    value: Formatting.percent(officer.recoveryRate, fractionDigits: 0),
                    label: "Recovery\nRate",
                    color: .lmsWarning
                )
            }
        }
    }

    private func metricItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: Spacing.s) {
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.m)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }

    // MARK: Recent Decisions

    private func recentDecisionsSection(_ officer: OfficerPerformanceData) -> some View {
        SectionCard(title: "Recent Decisions") {
            if officer.recentDecisions.isEmpty {
                Text("No recent decisions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.m)
            } else {
                ForEach(officer.recentDecisions) { decision in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: decision.action.rowIcon)
                            .font(.title3)
                            .foregroundStyle(decision.action.themeColor)
                            .frame(width: 32, height: 32)
                            .background(decision.action.themeColor.opacity(0.12),
                                         in: RoundedRectangle(cornerRadius: CornerRadius.small))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(decision.applicantName)
                                .font(.subheadline.weight(.medium))
                            Text("\(decision.action.verb) • \(decision.amount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(decision.timeText)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    if decision.id != officer.recentDecisions.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        OfficerDetailView(officerName: "Sarah Mehta")
    }
    .environment(ManagerStore.preview)
}
