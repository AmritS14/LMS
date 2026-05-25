import SwiftUI

enum FollowUpOutcome: String, CaseIterable, Identifiable {
    case promiseToPay = "Promise to Pay"
    case partialPayment = "Partial Payment"
    case notReachable = "Not Reachable"
    case refused = "Refused"
    case other = "Other"

    var id: String { rawValue }
}

struct RecoveryVerificationView: View {
    @Environment(LoanOfficerStore.self) private var store

    @State private var expandedID: UUID?
    @State private var activeLogBorrower: OverdueBorrower?
    @State private var callOutcome: FollowUpOutcome = .promiseToPay
    @State private var callNotes: String = ""

    private var totalOverdue: Decimal {
        store.overdueBorrowers.reduce(Decimal.zero) { $0 + $1.totalOutstanding }
    }

    private var collectionEfficiency: Double {
        let efficiencies = store.overdueBorrowers.map(\.collectionEfficiency)
        guard !efficiencies.isEmpty else { return 0 }
        return efficiencies.reduce(0, +) / Double(efficiencies.count)
    }

    var body: some View {
        List {
            Section {
                overview
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("Overdue Borrowers") {
                ForEach(store.overdueBorrowers) { borrower in
                    row(borrower)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Verification")
        .sheet(item: $activeLogBorrower) { borrower in
            callLogSheet(for: borrower)
        }
    }

    // MARK: Overview

    private var overview: some View {
        VStack(spacing: Spacing.m) {
            HStack(spacing: Spacing.m) {
                CircularProgress(progress: collectionEfficiency / 100.0,
                                 color: efficiencyColor,
                                 lineWidth: 10, size: 88)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Collection Efficiency")
                        .font(.subheadline.weight(.semibold))
                    Text("Total Overdue")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(OfficerFormat.currency(totalOverdue))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.lmsDanger)
                }
                Spacer()
            }

            HStack(spacing: 0) {
                ForEach(RecoveryPriority.allCases, id: \.self) { priority in
                    mini(label: priority.rawValue,
                         count: store.overdueBorrowers.filter { $0.priority == priority }.count,
                         color: toneColor(priority.tone))
                    if priority != RecoveryPriority.allCases.last {
                        Divider().frame(height: 28)
                    }
                }
            }
            .padding(.vertical, Spacing.s)
            .background(Color.lmsTertiarySurface,
                        in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
        .padding(Spacing.m)
    }

    private func mini(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)").font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var efficiencyColor: Color {
        if collectionEfficiency >= 70 { return .lmsSuccess }
        if collectionEfficiency >= 50 { return .lmsWarning }
        return .lmsDanger
    }

    // MARK: Row

    private func row(_ borrower: OverdueBorrower) -> some View {
        let isExpanded = expandedID == borrower.id
        return VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.sm) {
                AvatarView(initials: borrower.borrowerInitials,
                           size: 44,
                           colors: borrower.priority.gradient)
                VStack(alignment: .leading, spacing: 2) {
                    Text(borrower.borrowerName).font(.headline)
                    Text(borrower.loanID).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge("\(borrower.dpdDays) DPD",
                            tone: borrower.dpdDays > 30 ? .danger : .warning,
                            size: .small)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Outstanding EMI").font(.caption2).foregroundStyle(.secondary)
                    Text(OfficerFormat.currency(borrower.outstandingEMI))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total Outstanding").font(.caption2).foregroundStyle(.secondary)
                    Text(OfficerFormat.currency(borrower.totalOutstanding))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Color.lmsDanger)
                }
            }

            if isExpanded {
                Divider()
                DetailRow(icon: "phone.fill", title: "Phone",
                          value: borrower.phoneNumber, valueColor: .lmsAccent)
                DetailRow(icon: "calendar.badge.exclamationmark", title: "DPD",
                          value: "\(borrower.dpdDays) days",
                          valueColor: borrower.dpdDays > 30 ? .lmsDanger : .lmsWarning)
                DetailRow(icon: "checkmark.circle", title: "Contacted",
                          value: borrower.contacted ? "Yes" : "No",
                          valueColor: borrower.contacted ? .lmsSuccess : .lmsWarning)
                HStack(spacing: Spacing.s) {
                    Button {
                        store.markBorrowerContacted(borrower)
                    } label: {
                        Label("Log Call", systemImage: "phone.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.lmsSuccess)

                    Button {
                        activeLogBorrower = borrower
                        callOutcome = .promiseToPay
                        callNotes = ""
                    } label: {
                        Label("Add Note", systemImage: "note.text.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                expandedID = isExpanded ? nil : borrower.id
            }
        }
    }

    // MARK: Call Log Sheet

    private func callLogSheet(for borrower: OverdueBorrower) -> some View {
        NavigationStack {
            Form {
                Section { Text(borrower.borrowerName).font(.headline) }
                Section("Outcome") {
                    Picker("Outcome", selection: $callOutcome) {
                        ForEach(FollowUpOutcome.allCases) { outcome in
                            Text(outcome.rawValue).tag(outcome)
                        }
                    }
                }
                Section("Notes") {
                    TextEditor(text: $callNotes).frame(minHeight: 100)
                }
            }
            .navigationTitle("Call Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { activeLogBorrower = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.markBorrowerContacted(borrower)
                        activeLogBorrower = nil
                    }
                }
            }
        }
    }

    private func toneColor(_ tone: StatusBadge.Tone) -> Color {
        switch tone {
        case .neutral: .primary
        case .info: .lmsInfo
        case .success: .lmsSuccess
        case .warning: .lmsWarning
        case .danger: .lmsDanger
        }
    }
}
