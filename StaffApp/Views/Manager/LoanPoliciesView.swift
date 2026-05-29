import SwiftUI

// MARK: - Loan Policies

struct LoanPoliciesView: View {
    @Environment(ManagerStore.self) private var store
    @State private var editingPolicy: LoanPolicyConfig?

    var body: some View {
        List {
            Section {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.lmsInfo)
                    Text("Configure interest rates, tenure limits, and eligibility criteria for each loan product.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.lmsInfo.opacity(0.06))
            }

            Section("Active Products") {
                ForEach(store.loanPolicies.filter(\.isActive)) { policy in
                    policyRow(policy)
                }
            }

            let inactive = store.loanPolicies.filter { !$0.isActive }
            if !inactive.isEmpty {
                Section("Inactive Products") {
                    ForEach(inactive) { policy in
                        policyRow(policy)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Loan Policies")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingPolicy) { policy in
            LoanPolicyEditSheet(policy: policy) { updated in
                store.updatePolicy(updated)
                editingPolicy = nil
            }
        }
    }

    // MARK: Policy Row

    private func policyRow(_ policy: LoanPolicyConfig) -> some View {
        Button {
            editingPolicy = policy
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: policyIcon(policy.loanType))
                    .font(.body.weight(.medium))
                    .foregroundStyle(policyColor(policy.loanType))
                    .frame(width: 36, height: 36)
                    .background(policyColor(policy.loanType).opacity(0.12),
                                 in: RoundedRectangle(cornerRadius: CornerRadius.small))

                VStack(alignment: .leading, spacing: 4) {
                    Text(policy.loanType.rawValue.capitalized + " Loan")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    HStack(spacing: Spacing.xs) {
                        Text(policy.interestRangeText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("•")
                            .foregroundStyle(.quaternary)
                        Text("Max " + policy.maxAmountText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("•")
                            .foregroundStyle(.quaternary)
                        Text(policy.maxTenureText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

    private func policyIcon(_ type: LoanType) -> String {
        switch type {
        case .home: "house"
        case .personal: "person"
        case .business: "building.2"
        case .vehicle: "car"
        case .education: "graduationcap"
        }
    }

    private func policyColor(_ type: LoanType) -> Color {
        switch type {
        case .home: .lmsAccent
        case .personal: .lmsInfo
        case .business: .lmsWarning
        case .vehicle: .lmsSuccess
        case .education: .lmsDanger
        }
    }
}

#Preview {
    NavigationStack {
        LoanPoliciesView()
    }
    .environment(ManagerStore.preview)
}
