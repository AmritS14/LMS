import SwiftUI

// MARK: - Reminder Schedule Model
struct ReminderSchedule: Identifiable, Hashable {
    var id: UUID
    var name: String
    var timing: String // "3 days before due date", "On due date", "5 days after missed payment"
    var channels: Set<NotificationChannel>
    var templateBody: String
    var isActive: Bool
    
    static let sampleSchedules: [ReminderSchedule] = [
        ReminderSchedule(
            id: UUID(),
            name: "Pre-Due Reminder",
            timing: "3 days before due date",
            channels: [.email, .sms],
            templateBody: "Hello {{borrower_name}}, your loan installment of {{emi_amount}} is due on {{due_date}}.",
            isActive: true
        ),
        ReminderSchedule(
            id: UUID(),
            name: "Due Date Alert",
            timing: "On due date",
            channels: [.email, .sms, .inApp],
            templateBody: "Dear {{borrower_name}}, your installment of {{emi_amount}} is due today. Please make payment immediately to avoid late fees.",
            isActive: true
        ),
        ReminderSchedule(
            id: UUID(),
            name: "Overdue Notice",
            timing: "5 days after missed payment",
            channels: [.sms, .inApp],
            templateBody: "Warning {{borrower_name}}: Your EMI payment of {{emi_amount}} is 5 days overdue. Late fees have been applied.",
            isActive: true
        )
    ]
}

// MARK: - EMI Scheduler View
struct EMISchedulerView: View {
    @State private var schedules = ReminderSchedule.sampleSchedules
    @State private var selectedScheduleForEdit: ReminderSchedule? = nil
    @State private var showCreateSheet = false

    var body: some View {
        List {
            Section {
                ForEach($schedules) { $schedule in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(schedule.name)
                                .font(.adminCardTitle)
                                .foregroundStyle(.primary)
                            Spacer()
                            Toggle("", isOn: $schedule.isActive)
                                .labelsHidden()
                        }
                        
                        Text(schedule.timing)
                            .font(.adminSecondary)
                            .foregroundStyle(.secondary)
                            
                        HStack(spacing: 12) {
                            if schedule.channels.contains(.email) {
                                Label("Email", systemImage: "envelope.fill")
                            }
                            if schedule.channels.contains(.sms) {
                                Label("SMS", systemImage: "message.fill")
                            }
                            if schedule.channels.contains(.inApp) {
                                Label("In-App", systemImage: "bell.fill")
                            }
                        }
                        .font(.adminCaption)
                        .foregroundStyle(schedule.isActive ? Color.lmsInfo : .secondary)
                        .padding(.top, 4)
                    }
                    .padding(.vertical, Spacing.xxs)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteSchedule(schedule)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            duplicateSchedule(schedule)
                        } label: {
                            Label("Duplicate", systemImage: "plus.square.on.square")
                        }
                        .tint(.blue)
                        
                        Button {
                            selectedScheduleForEdit = schedule
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                }
            } header: {
                Text("Configured Reminder Triggers")
                    .font(.adminSectionHeader)
                    .foregroundStyle(Color.secondary)
                    .textCase(.uppercase)
                    .padding(.leading, 8)
            }
        }
        .navigationTitle("EMI Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            AddReminderScheduleSheet(onSave: { newSchedule in
                schedules.append(newSchedule)
            })
        }
        .sheet(item: $selectedScheduleForEdit) { schedule in
            AddReminderScheduleSheet(editingSchedule: schedule, onSave: { updated in
                if let idx = schedules.firstIndex(where: { $0.id == updated.id }) {
                    schedules[idx] = updated
                }
            })
        }
    }
    
    // MARK: - Actions
    
    private func duplicateSchedule(_ schedule: ReminderSchedule) {
        var copy = schedule
        copy.id = UUID()
        copy.name += " Copy"
        withAnimation {
            schedules.append(copy)
        }
    }
    
    private func deleteSchedule(_ schedule: ReminderSchedule) {
        withAnimation {
            schedules.removeAll { $0.id == schedule.id }
        }
    }
}

#Preview {
    NavigationStack {
        EMISchedulerView()
    }
}
