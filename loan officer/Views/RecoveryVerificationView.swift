import SwiftUI

// MARK: - Follow-Up Outcome Enum

enum FollowUpOutcome: String, CaseIterable {
    case promiseToPay = "Promise to Pay"
    case partialPayment = "Partial Payment"
    case notReachable = "Not Reachable"
    case refused = "Refused"
    case other = "Other"
}

// MARK: - Recovery Verification View

struct RecoveryVerificationView: View {

    @EnvironmentObject var viewModel: AppViewModel

    @State private var expandedBorrowerId: UUID? = nil

    @State private var showCallLogSheet = false
    @State private var showFollowUpSheet = false

    @State private var selectedBorrower: OverdueBorrower? = nil

    // Call Log State
    @State private var callLogNotes: String = ""
    @State private var callLogOutcome: FollowUpOutcome = .promiseToPay

    // Follow-Up State
    @State private var followUpDate: Date = Date().addingTimeInterval(86400)
    @State private var followUpOutcome: FollowUpOutcome = .promiseToPay
    @State private var followUpNotes: String = ""

    var body: some View {

        ScrollView(.vertical, showsIndicators: false) {

            VStack(spacing: 20) {

                collectionEfficiencyOverview
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                overdueBorrowersList
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Recovery")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCallLogSheet) {
            callLogSheetContent
        }
        .sheet(isPresented: $showFollowUpSheet) {
            followUpSheetContent
        }
    }
}

// MARK: - Main Recovery Content

extension RecoveryVerificationView {

    // MARK: Collection Overview

    private var collectionEfficiencyOverview: some View {

        PremiumCard {

            VStack(spacing: 16) {

                HStack(spacing: 20) {

                    CircularProgress(
                        progress: overallCollectionEfficiency / 100.0,
                        color: efficiencyColor,
                        lineWidth: 8,
                        size: 80
                    )

                    VStack(alignment: .leading, spacing: 12) {

                        Text("Collection Efficiency")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold,
                                    design: .rounded
                                )
                            )

                        HStack(spacing: 16) {

                            VStack(alignment: .leading, spacing: 2) {

                                Text("Total Overdue")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)

                                Text(
                                    AppFormatters.formatCurrency(
                                        totalOverdueAmount
                                    )
                                )
                                .font(
                                    .system(
                                        size: 15,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(.red)
                            }

                            VStack(alignment: .leading, spacing: 2) {

                                Text("Borrowers")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)

                                Text("\(viewModel.overdueBorrowers.count)")
                                    .font(
                                        .system(
                                            size: 15,
                                            weight: .bold,
                                            design: .rounded
                                        )
                                    )
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    Spacer()
                }

                HStack(spacing: 0) {

                    efficiencyMiniStat(
                        label: "Urgent",
                        count: viewModel.overdueBorrowers.filter {
                            $0.priority == .urgent
                        }.count,
                        color: .red
                    )

                    Divider()
                        .frame(height: 28)

                    efficiencyMiniStat(
                        label: "High",
                        count: viewModel.overdueBorrowers.filter {
                            $0.priority == .high
                        }.count,
                        color: .orange
                    )

                    Divider()
                        .frame(height: 28)

                    efficiencyMiniStat(
                        label: "Normal",
                        count: viewModel.overdueBorrowers.filter {
                            $0.priority == .normal
                        }.count,
                        color: .blue
                    )

                    Divider()
                        .frame(height: 28)

                    efficiencyMiniStat(
                        label: "Low",
                        count: viewModel.overdueBorrowers.filter {
                            $0.priority == .low
                        }.count,
                        color: .green
                    )
                }
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.tertiarySystemGroupedBackground))
                )
            }
        }
    }

    private func efficiencyMiniStat(
        label: String,
        count: Int,
        color: Color
    ) -> some View {

        VStack(spacing: 4) {

            Text("\(count)")
                .font(
                    .system(
                        size: 18,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(color)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Computed Values

    private var overallCollectionEfficiency: Double {

        let efficiencies = viewModel.overdueBorrowers.map {
            $0.collectionEfficiency
        }

        guard !efficiencies.isEmpty else {
            return 0
        }

        return efficiencies.reduce(0, +) / Double(efficiencies.count)
    }

    private var efficiencyColor: Color {

        if overallCollectionEfficiency >= 70 {
            return .green
        }

        if overallCollectionEfficiency >= 50 {
            return .orange
        }

        return .red
    }

    private var totalOverdueAmount: Double {

        viewModel.overdueBorrowers.reduce(0) {
            $0 + $1.totalOutstanding
        }
    }

    // MARK: Borrowers List

    private var overdueBorrowersList: some View {

        VStack(spacing: 12) {

            SectionHeader(
                title: "Overdue Borrowers",
                subtitle: "\(viewModel.overdueBorrowers.count) accounts",
                icon: "person.crop.circle.badge.exclamationmark.fill"
            )

            ForEach(viewModel.overdueBorrowers) { borrower in

                overdueBorrowerCard(borrower)
            }
        }
    }

    // MARK: Borrower Card

    private func overdueBorrowerCard(
        _ borrower: OverdueBorrower
    ) -> some View {

        let isExpanded = expandedBorrowerId == borrower.id

        return PremiumCard {

            VStack(spacing: 12) {

                HStack(spacing: 12) {

                    AvatarView(
                        initials: borrower.borrowerInitials,
                        size: 44,
                        colors: avatarColors(for: borrower.priority)
                    )

                    VStack(alignment: .leading, spacing: 3) {

                        Text(borrower.borrowerName)
                            .font(.system(size: 15, weight: .semibold))

                        Text(borrower.loanId)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    dpdBadge(days: borrower.dpdDays)
                }

                HStack(spacing: 12) {

                    VStack(alignment: .leading, spacing: 2) {

                        Text("Outstanding EMI")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text(
                            AppFormatters.formatCurrency(
                                borrower.outstandingEMI
                            )
                        )
                        .font(
                            .system(
                                size: 14,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {

                        Text("Total Outstanding")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text(
                            AppFormatters.formatCurrency(
                                borrower.totalOutstanding
                            )
                        )
                        .font(
                            .system(
                                size: 14,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.red)
                    }
                }

                if isExpanded {

                    expandedBorrowerDetails(borrower)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {

            withAnimation(
                .spring(
                    response: 0.35,
                    dampingFraction: 0.85
                )
            ) {

                expandedBorrowerId =
                    isExpanded
                    ? nil
                    : borrower.id
            }
        }
    }

    // MARK: Expanded Details

    private func expandedBorrowerDetails(
        _ borrower: OverdueBorrower
    ) -> some View {

        VStack(spacing: 10) {

            Divider()

            DetailRow(
                icon: "phone.fill",
                title: "Phone",
                value: borrower.phoneNumber,
                valueColor: .blue
            )

            DetailRow(
                icon: "calendar.badge.exclamationmark",
                title: "DPD Days",
                value: "\(borrower.dpdDays) days",
                valueColor: borrower.dpdDays > 30 ? .red : .orange
            )

            HStack(spacing: 12) {

                // MARK: Message Button

                Button {

                    if let conversation = viewModel.conversations.first(where: {
                        $0.borrowerName == borrower.borrowerName
                    }) {

                        viewModel.selectedConversation = conversation

                        viewModel.navigationPath.append(
                            AppDestination.communications
                        )
                    }

                } label: {

                    HStack(spacing: 6) {

                        Image(systemName: "message.fill")

                        Text("Message")
                    }
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                Color.blue.opacity(0.1)
                            )
                    )
                }
                .buttonStyle(.plain)

                // MARK: Log Call Button

                Button {

                    viewModel.markBorrowerContacted(borrower)

                } label: {

                    Label("Log Call", systemImage: "phone.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.green)
                        )
                }
                .buttonStyle(.plain)

                // MARK: Add Note Button

                Button {

                    selectedBorrower = borrower
                    callLogNotes = ""
                    callLogOutcome = .promiseToPay

                    showCallLogSheet = true

                } label: {

                    Label(
                        "Add Note",
                        systemImage: "note.text.badge.plus"
                    )
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.blue)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: DPD Badge

    private func dpdBadge(days: Int) -> some View {

        let color: Color =
            days > 30
            ? .red
            : (days > 15 ? .orange : .yellow)

        return Text("\(days) DPD")
            .font(
                .system(
                    size: 11,
                    weight: .bold,
                    design: .rounded
                )
            )
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
    }

    // MARK: Avatar Colors

    private func avatarColors(
        for priority: RecoveryPriority
    ) -> [Color] {

        switch priority {

        case .urgent:
            return [.red, .pink]

        case .high:
            return [.orange, .yellow]

        case .normal:
            return [.blue, .cyan]

        case .low:
            return [.green, .mint]
        }
    }
}

// MARK: - Call Log Sheet

extension RecoveryVerificationView {

    private var callLogSheetContent: some View {

        NavigationStack {

            Form {

                Section("Call Outcome") {

                    Picker(
                        "Outcome",
                        selection: $callLogOutcome
                    ) {

                        ForEach(
                            FollowUpOutcome.allCases,
                            id: \.self
                        ) { outcome in

                            Text(outcome.rawValue)
                                .tag(outcome)
                        }
                    }
                }

                Section("Notes") {

                    TextEditor(text: $callLogNotes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Call Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("Cancel") {

                        showCallLogSheet = false
                    }
                }
            }
        }
    }
}

// MARK: - Follow-Up Sheet

extension RecoveryVerificationView {

    private var followUpSheetContent: some View {

        NavigationStack {

            Form {

                Section("Follow-up Date") {

                    DatePicker(
                        "Date & Time",
                        selection: $followUpDate,
                        in: Date()...,
                        displayedComponents: [
                            .date,
                            .hourAndMinute
                        ]
                    )
                }

                Section("Outcome") {

                    Picker(
                        "Outcome",
                        selection: $followUpOutcome
                    ) {

                        ForEach(
                            FollowUpOutcome.allCases,
                            id: \.self
                        ) { outcome in

                            Text(outcome.rawValue)
                                .tag(outcome)
                        }
                    }
                }

                Section("Notes") {

                    TextEditor(text: $followUpNotes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Schedule Follow-up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("Cancel") {

                        showFollowUpSheet = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        RecoveryVerificationView()
            .environmentObject(AppViewModel())
    }
}
