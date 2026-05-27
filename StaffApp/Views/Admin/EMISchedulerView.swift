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
    
    // HUD State
    @State private var hudMessage: String? = nil
    @State private var showHUD = false

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            List {
                Section {
                    ForEach(schedules) { schedule in
                        reminderCard(schedule: schedule)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                } header: {
                    Text("Configured Reminder Triggers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
            
            // HUD Banner Overlay
            if showHUD, let msg = hudMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.85), in: Capsule())
                        .shadow(radius: 8)
                        .padding(.bottom, 36)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
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
                triggerHUD("Reminder Created")
            })
        }
        .sheet(item: $selectedScheduleForEdit) { schedule in
            AddReminderScheduleSheet(editingSchedule: schedule, onSave: { updated in
                if let idx = schedules.firstIndex(where: { $0.id == updated.id }) {
                    schedules[idx] = updated
                    triggerHUD("Reminder Updated")
                }
            })
        }
    }
    
    // MARK: - Subviews
    
    private func reminderCard(schedule: ReminderSchedule) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text(schedule.timing)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Toggle switch
                Toggle("", isOn: Binding(
                    get: { schedule.isActive },
                    set: { val in
                        if let idx = schedules.firstIndex(where: { $0.id == schedule.id }) {
                            schedules[idx].isActive = val
                            triggerHUD(val ? "Schedule Activated" : "Schedule Deactivated")
                        }
                    }
                ))
                .labelsHidden()
                .tint(.blue)
            }
            
            Divider()
            
            HStack {
                // Channels active indicator
                HStack(spacing: 8) {
                    channelIcon(isOn: schedule.channels.contains(.email), image: "envelope.fill", label: "Email")
                    channelIcon(isOn: schedule.channels.contains(.sms), image: "message.fill", label: "SMS")
                    channelIcon(isOn: schedule.channels.contains(.inApp), image: "bell.fill", label: "In-App")
                }
                
                Spacer()
                
                // Card actions menu
                Menu {
                    Button(action: { selectedScheduleForEdit = schedule }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(action: { duplicateSchedule(schedule) }) {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                    
                    Button(role: .destructive, action: { deleteSchedule(schedule) }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func channelIcon(isOn: Bool, image: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: image)
                .font(.system(size: 10))
            Text(label)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(isOn ? Color.blue : Color.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isOn ? Color.blue.opacity(0.12) : Color.primary.opacity(0.04), in: Capsule())
    }
    
    // MARK: - Actions
    
    private func duplicateSchedule(_ schedule: ReminderSchedule) {
        var copy = schedule
        copy.id = UUID()
        copy.name += " Copy"
        schedules.append(copy)
        triggerHUD("Reminder Duplicated")
    }
    
    private func deleteSchedule(_ schedule: ReminderSchedule) {
        withAnimation {
            schedules.removeAll { $0.id == schedule.id }
        }
        triggerHUD("Reminder Deleted")
    }
    
    private func triggerHUD(_ message: String) {
        hudMessage = message
        withAnimation(.easeOut(duration: 0.25)) {
            showHUD = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeIn(duration: 0.25)) {
                showHUD = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        EMISchedulerView()
    }
}
