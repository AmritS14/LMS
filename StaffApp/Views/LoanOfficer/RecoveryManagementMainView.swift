import SwiftUI

// Entry-point recovery dashboard summarising overdue accounts. Detailed
// follow-up workflows live in RecoveryVerificationView (drilled into via
// the "View Details" link below).
struct RecoveryManagementMainView: View {
    @Environment(LoanOfficerStore.self) private var store

    private var overdueAmount: Decimal {
        store.overdueBorrowers.reduce(Decimal.zero) { $0 + $1.totalOutstanding }
    }

    var body: some View {
        List {
            Section {
                summary
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("Overdue Accounts") {
                if store.overdueBorrowers.isEmpty {
                    ContentUnavailableView("Nothing overdue",
                                           systemImage: "checkmark.seal.fill",
                                           description: Text("All assigned accounts are current."))
                } else {
                    ForEach(store.overdueBorrowers) { borrower in
                        NavigationLink(value: OfficerRoute.recoveryDetail) {
                            row(borrower)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Recovery")
    }

    private var summary: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.m) {
                metric(label: "Overdue", value: OfficerFormat.currency(overdueAmount),
                       icon: "indianrupeesign.circle.fill", color: .lmsDanger)
                metric(label: "Accounts", value: "\(store.overdueBorrowers.count)",
                       icon: "person.3.fill", color: .lmsWarning)
            }
            HStack(spacing: Spacing.m) {
                metric(label: "Urgent",
                       value: "\(store.overdueBorrowers.filter { $0.priority == .urgent }.count)",
                       icon: "exclamationmark.triangle.fill", color: .lmsDanger)
                metric(label: "Contacted",
                       value: "\(store.overdueBorrowers.filter { $0.contacted }.count)",
                       icon: "phone.fill", color: .lmsSuccess)
            }
        }
        .padding(Spacing.m)
    }

    private func metric(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: CornerRadius.small))
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    private func row(_ borrower: OverdueBorrower) -> some View {
        HStack(spacing: Spacing.sm) {
            AvatarView(initials: borrower.borrowerInitials,
                       size: 44,
                       colors: borrower.priority.gradient)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(borrower.borrowerName).font(.headline)
                    Spacer()
                    StatusBadge("\(borrower.dpdDays) DPD",
                                tone: borrower.dpdDays > 30 ? .danger : .warning,
                                size: .small)
                }
                Text(borrower.loanID)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                HStack {
                    Text(OfficerFormat.currency(borrower.totalOutstanding))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Color.lmsDanger)
                    Spacer()
                    StatusBadge(borrower.priority.rawValue,
                                tone: borrower.priority.tone, size: .small)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
