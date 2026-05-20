import SwiftUI

// MARK: - Collections List View

struct LOCollectionsView: View {
    @State private var overdueLoans: [Loan] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if overdueLoans.isEmpty {
                    ContentUnavailableView(
                        "No Overdue Loans",
                        systemImage: "checkmark.shield.fill",
                        description: Text("All borrowers are on track with their EMIs.")
                    )
                } else {
                    List(overdueLoans) { loan in
                        NavigationLink {
                            LOCollectionDetailView(loan: loan)
                        } label: {
                            OverdueLoanRow(loan: loan)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: Spacing.m, bottom: 4, trailing: Spacing.m))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Collections")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .task {
                if let loans = try? await MockData.sharedLoanService.fetchAllOverdueLoans() {
                    overdueLoans = loans
                }
                isLoading = false
            }
            .refreshable {
                if let loans = try? await MockData.sharedLoanService.fetchAllOverdueLoans() {
                    overdueLoans = loans
                }
            }
        }
    }
}

struct OverdueLoanRow: View {
    let loan: Loan

    private var borrower: User? { MockData.borrowerUser(for: loan.borrowerID) }
    private var overdueCount: Int {
        loan.emiSchedule.filter { $0.status == .overdue }.count
    }
    private var overdueAmount: Decimal {
        loan.emiSchedule.filter { $0.status == .overdue }.reduce(0) { $0 + $1.totalAmount }
    }

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                Circle()
                    .fill(Color.lmsDanger.opacity(0.12))
                    .frame(width: 46, height: 46)
                Text(borrower?.fullName.prefix(1) ?? "?")
                    .font(.lmsTitle2)
                    .foregroundStyle(Color.lmsDanger)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(borrower?.fullName ?? "—").font(.lmsHeadline)
                Text("Outstanding: \(Formatting.currency(loan.outstandingBalance))")
                    .font(.lmsCaption).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge("\(overdueCount) Overdue", tone: .danger)
                Text(Formatting.currency(overdueAmount))
                    .font(.lmsCaption.weight(.semibold))
                    .foregroundStyle(Color.lmsDanger)
            }
        }
        .padding(Spacing.m)
        .background(.background, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Collection Detail View

struct LOCollectionDetailView: View {
    let loan: Loan
    @State private var callLogs: [CallLog] = []
    @State private var showAddLog = false

    private var borrower: User? { MockData.borrowerUser(for: loan.borrowerID) }
    private var overdueEMIs: [EMI] { loan.emiSchedule.filter { $0.status == .overdue } }
    private var upcomingEMIs: [EMI] { loan.emiSchedule.filter { $0.status == .upcoming }.prefix(3).map { $0 } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {

                // Borrower header card
                SectionCard {
                    HStack(spacing: Spacing.m) {
                        ZStack {
                            Circle()
                                .fill(Color.lmsDanger.opacity(0.12))
                                .frame(width: 52, height: 52)
                            Text(borrower?.fullName.prefix(1) ?? "?")
                                .font(.lmsTitle2)
                                .foregroundStyle(Color.lmsDanger)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(borrower?.fullName ?? "—").font(.lmsTitle2)
                            Text(borrower?.phone ?? "—").font(.lmsCaption).foregroundStyle(.secondary)
                            Text(borrower?.email ?? "—").font(.lmsCaption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Outstanding").font(.lmsCaption).foregroundStyle(.secondary)
                            Text(Formatting.currency(loan.outstandingBalance))
                                .font(.lmsHeadline)
                                .foregroundStyle(Color.lmsDanger)
                        }
                    }
                }
                .padding(.horizontal, Spacing.m)

                // Overdue EMIs
                if !overdueEMIs.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        HStack {
                            Text("Overdue Instalments")
                                .font(.lmsTitle2)
                            Spacer()
                            StatusBadge("\(overdueEMIs.count) EMIs", tone: .danger)
                        }
                        .padding(.horizontal, Spacing.m)

                        ForEach(overdueEMIs) { emi in
                            EMIRow(emi: emi)
                        }
                    }
                }

                // Upcoming EMIs (preview)
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("Upcoming Instalments")
                        .font(.lmsTitle2)
                        .padding(.horizontal, Spacing.m)
                    ForEach(upcomingEMIs) { emi in
                        EMIRow(emi: emi)
                    }
                }

                // Call/Recovery Log
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack {
                        Text("Recovery Activity Log")
                            .font(.lmsTitle2)
                        Spacer()
                        Button {
                            showAddLog = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.lmsPrimary)
                        }
                    }
                    .padding(.horizontal, Spacing.m)

                    if callLogs.isEmpty {
                        Text("No contact logged yet.")
                            .font(.lmsBody)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, Spacing.m)
                    } else {
                        ForEach(callLogs) { log in
                            CallLogRow(log: log)
                        }
                    }
                }

                Spacer(minLength: Spacing.xxl)
            }
            .padding(.vertical, Spacing.m)
        }
        .navigationTitle("Collection Detail")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .task {
            callLogs = CallLog.mockLogs(for: loan.borrowerID)
        }
        .sheet(isPresented: $showAddLog) {
            AddCallLogView { newLog in
                callLogs.insert(newLog, at: 0)
            }
            .presentationDetents([.medium])
        }
    }
}

// MARK: - EMI Row

struct EMIRow: View {
    let emi: EMI

    var body: some View {
        HStack(spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("EMI #\(emi.installmentNumber)")
                    .font(.lmsHeadline)
                Text("Due: \(Formatting.date(emi.dueDate))")
                    .font(.lmsCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatting.currency(emi.totalAmount))
                    .font(.lmsHeadline)
                    .foregroundStyle(emi.status == .overdue ? Color.lmsDanger : Color.primary)
                StatusBadge(emi.status.displayName, tone: emi.status == .overdue ? .danger : emi.status == .paid ? .success : .info)
            }
        }
        .padding(Spacing.m)
        .background(.background, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
        .padding(.horizontal, Spacing.m)
    }
}

extension EMIStatus {
    var displayName: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .paid: return "Paid"
        case .overdue: return "Overdue"
        }
    }
}

// MARK: - Call Log

struct CallLog: Identifiable {
    var id: UUID = UUID()
    var borrowerID: UUID
    var date: Date
    var outcome: String
    var notes: String
    var contactedBy: String

    static func mockLogs(for borrowerID: UUID) -> [CallLog] {
        guard borrowerID == MockData.borrowerDaniel.id else { return [] }
        return [
            CallLog(borrowerID: borrowerID,
                    date: Date(timeIntervalSinceNow: -3 * 86400),
                    outcome: "Promised to Pay",
                    notes: "Customer confirmed payment by 25th of this month.",
                    contactedBy: MockData.loanOfficerUser.fullName),
            CallLog(borrowerID: borrowerID,
                    date: Date(timeIntervalSinceNow: -7 * 86400),
                    outcome: "No Response",
                    notes: "Called twice, no answer. Left voicemail.",
                    contactedBy: MockData.loanOfficerUser.fullName)
        ]
    }
}

struct CallLogRow: View {
    let log: CallLog

    private var outcomeTone: StatusBadge.Tone {
        switch log.outcome {
        case "Promised to Pay": return .success
        case "No Response": return .warning
        default: return .neutral
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundStyle(Color.lmsPrimary)
                Text(log.outcome).font(.lmsHeadline)
                Spacer()
                StatusBadge(log.outcome, tone: outcomeTone)
            }
            Text(log.notes).font(.lmsCaption).foregroundStyle(.secondary)
            HStack {
                Image(systemName: "person.fill")
                    .font(.caption2)
                Text(log.contactedBy).font(.caption2)
                Spacer()
                Text(Formatting.date(log.date)).font(.caption2)
            }
            .foregroundStyle(.tertiary)
        }
        .padding(Spacing.m)
        .background(.background, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
        .padding(.horizontal, Spacing.m)
    }
}

// MARK: - Add Call Log Sheet

struct AddCallLogView: View {
    var onSave: (CallLog) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var outcome = "Promised to Pay"
    @State private var notes = ""
    let outcomes = ["Promised to Pay", "No Response", "Refused to Pay", "Paid Partially", "Field Visit Required"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Outcome") {
                    Picker("Outcome", selection: $outcome) {
                        ForEach(outcomes, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
                Section("Notes") {
                    TextField("Describe the interaction…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let log = CallLog(
                            borrowerID: MockData.borrowerDaniel.id,
                            date: .now,
                            outcome: outcome,
                            notes: notes,
                            contactedBy: MockData.loanOfficerUser.fullName
                        )
                        onSave(log)
                        dismiss()
                    }
                    .disabled(notes.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    LOCollectionsView()
}
