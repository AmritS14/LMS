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
                List {
                    // MARK: Header
                    Section {
                        VStack(spacing: Spacing.m) {
                            AvatarView(initials: officer.initials, size: 80)
                                .padding(.top, Spacing.s)

                            VStack(spacing: 4) {
                                Text(officer.name)
                                    .font(.title2.weight(.bold))
                                Text("Loan Officer")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }

                    // MARK: Metrics
                    Section("Performance Metrics") {
                        LabeledContent("Applications Processed", value: "\(officer.applicationsProcessed)")
                        LabeledContent("Approval Success", value: Formatting.percent(officer.approvalRate, fractionDigits: 0))
                        
                        let displayTime = (officer.avgDecisionTime == "—" || officer.avgDecisionTime == "-") ? "N/A" : officer.avgDecisionTime
                        LabeledContent("Avg Decision Time", value: displayTime)
                        
                        LabeledContent("Recovery Rate", value: Formatting.percent(officer.recoveryRate, fractionDigits: 0))
                    }

                    // MARK: Recent Decisions
                    Section("Recent Decisions") {
                        if officer.recentDecisions.isEmpty {
                            Text("No recent decisions")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(officer.recentDecisions) { decision in
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: decision.action.rowIcon)
                                        .font(.title2)
                                        .foregroundStyle(decision.action.themeColor)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(decision.applicantName)
                                            .font(.body)
                                        Text("\(decision.action.verb) • \(decision.amount)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text(decision.timeText)
                                        .font(.subheadline)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                ContentUnavailableView("Officer not found",
                                       systemImage: "person.slash",
                                       description: Text("This officer is no longer in the team."))
            }
        }
        .navigationTitle(officerName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        OfficerDetailView(officerName: "Sarah Mehta")
    }
    .environment(ManagerStore.preview)
}
