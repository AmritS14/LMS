import SwiftUI

// MARK: - Officer Performance List

struct OfficerPerformanceView: View {
    @Environment(ManagerStore.self) private var store
    @State private var searchText = ""

    private var filteredOfficers: [OfficerPerformanceData] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return store.officerPerformance }
        return store.officerPerformance.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            // MARK: Team Summary

            Section {
                HStack(spacing: Spacing.m) {
                    teamMetric(
                        value: "\(store.officerPerformance.count)",
                        label: "Officers",
                        icon: "person.3",
                        color: .lmsAccent
                    )
                    teamMetric(
                        value: "\(store.officerPerformance.reduce(0) { $0 + $1.applicationsProcessed })",
                        label: "Processed",
                        icon: "doc.text",
                        color: .lmsSuccess
                    )
                    teamMetric(
                        value: avgApprovalRate,
                        label: "Avg Approval",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .lmsInfo
                    )
                }
                .listRowInsets(EdgeInsets(top: Spacing.m, leading: Spacing.m, bottom: Spacing.m, trailing: Spacing.m))
                .listRowBackground(Color.clear)
            }

            // MARK: Officers

            Section("Loan Officers") {
                if filteredOfficers.isEmpty {
                    ContentUnavailableView("No officers found",
                                           systemImage: "person.slash",
                                           description: Text("Try a different search."))
                } else {
                    ForEach(filteredOfficers) { officer in
                        NavigationLink(value: ManagerRoute.officerDetail(officer.name)) {
                            officerRow(officer)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Officer Performance")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search officer")
    }

    // MARK: Team Metric

    private func teamMetric(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.small))
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Officer Row

    private func officerRow(_ officer: OfficerPerformanceData) -> some View {
        HStack(spacing: Spacing.sm) {
            AvatarView(initials: officer.initials, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(officer.name)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: Spacing.s) {
                    metricPill("\(officer.applicationsProcessed) processed")
                    metricPill(Formatting.percent(officer.approvalRate, fractionDigits: 0) + " approval")
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(officer.avgDecisionTime)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Avg time")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private func metricPill(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.lmsFill, in: Capsule())
            .foregroundStyle(.secondary)
    }

    private var avgApprovalRate: String {
        let rates = store.officerPerformance.map(\.approvalRate)
        guard !rates.isEmpty else { return "—" }
        return Formatting.percent(rates.reduce(0, +) / Double(rates.count), fractionDigits: 0)
    }
}

#Preview {
    NavigationStack {
        OfficerPerformanceView()
    }
    .environment(ManagerStore.preview)
}
