import SwiftUI

// MARK: - Add/Edit Reminder Schedule Sheet
struct AddReminderScheduleSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // Callback on save
    var editingSchedule: ReminderSchedule? = nil
    var onSave: (ReminderSchedule) -> Void

    // Form Fields
    @State private var name: String = ""
    @State private var timingDays: Int = 3
    @State private var timingType: TimingType = .before
    @State private var selectedChannels: Set<NotificationChannel> = [.sms]
    @State private var templateBody: String = ""
    
    // Alert & Validation States
    @State private var showDiscardAlert = false
    @State private var hasEdits = false
    
    // Validation flags
    private var isTitleEmpty: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isNoChannelSelected: Bool {
        selectedChannels.isEmpty
    }
    
    private var canSave: Bool {
        !isTitleEmpty && !isNoChannelSelected && !templateBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Conflict Detection (UI Simulation)
    private var hasPotentialConflict: Bool {
        // Simulates a conflict warning if timing is set to exactly "On due date" or "5 days after" for demonstration
        timingType == .on || (timingType == .after && timingDays == 5)
    }
    
    enum TimingType: String, CaseIterable, Identifiable {
        case before = "Before Due Date"
        case on = "On Due Date"
        case after = "After Missed Payment"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Live Preview computed body
    private var previewResolvedText: String {
        let sampleValues = [
            "{{borrower_name}}": "Naman Gupta",
            "{{emi_amount}}": "₹8,452",
            "{{due_date}}": "25 May 2026"
        ]
        
        var result = templateBody
        if result.isEmpty {
            result = "Hello {{borrower_name}}, your loan installment of {{emi_amount}} is due on {{due_date}}."
        }
        
        for (key, val) in sampleValues {
            result = result.replacingOccurrences(of: key, with: val)
        }
        return result
    }
    
    init(editingSchedule: ReminderSchedule? = nil, onSave: @escaping (ReminderSchedule) -> Void) {
        self.editingSchedule = editingSchedule
        self.onSave = onSave
        
        // Initial setup for editing
        if let schedule = editingSchedule {
            _name = State(initialValue: schedule.name)
            _templateBody = State(initialValue: schedule.templateBody)
            _selectedChannels = State(initialValue: schedule.channels)
            
            // Parse timing string (e.g., "3 days before due date")
            let parts = schedule.timing.split(separator: " ")
            if schedule.timing == "On due date" {
                _timingType = State(initialValue: .on)
                _timingDays = State(initialValue: 0)
            } else if schedule.timing.contains("before") {
                _timingType = State(initialValue: .before)
                if let days = parts.first.map(String.init).flatMap(Int.init) {
                    _timingDays = State(initialValue: days)
                }
            } else if schedule.timing.contains("after") {
                _timingType = State(initialValue: .after)
                if let days = parts.first.map(String.init).flatMap(Int.init) {
                    _timingDays = State(initialValue: days)
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Reminder Metadata
                Section {
                    TextField("Reminder Name", text: $name)
                        .onChange(of: name) { _, _ in hasEdits = true }
                    
                    if isTitleEmpty {
                        Text("Title is required")
                            .font(.adminCaption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Reminder Info")
                        .font(.adminSectionHeader)
                        .foregroundStyle(Color.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, 8)
                }
                
                // Section 2: Trigger Timing Builder
                Section {
                    Picker("Trigger On", selection: $timingType) {
                        ForEach(TimingType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .onChange(of: timingType) { _, _ in hasEdits = true }
                    
                    if timingType != .on {
                        Stepper(value: $timingDays, in: 1...30) {
                            Text("\(timingDays) Days \(timingType == .before ? "Before" : "After")")
                        }
                        .onChange(of: timingDays) { _, _ in hasEdits = true }
                    }
                    
                    // Conflict warning banner
                    if hasPotentialConflict {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Potential Reminder Conflict: Another reminder schedule is already set for this trigger timing.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .transition(.opacity)
                    }
                } header: {
                    Text("Trigger Schedule")
                        .font(.adminSectionHeader)
                        .foregroundStyle(Color.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, 8)
                }
                
                // Section 3: Delivery Channels
                Section {
                    channelToggle(channel: .email, title: "Email", icon: "envelope")
                    channelToggle(channel: .sms, title: "SMS", icon: "message")
                    channelToggle(channel: .inApp, title: "In-App", icon: "bell")
                    
                    if isNoChannelSelected {
                        Text("At least one delivery channel must be selected")
                            .font(.adminCaption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Delivery Channels")
                        .font(.adminSectionHeader)
                        .foregroundStyle(Color.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, 8)
                }
                
                // Section 4: Template Editor
                Section {
                    TextEditor(text: $templateBody)
                        .frame(minHeight: 120)
                        .font(.adminFormInput.monospacedDigit())
                        .onChange(of: templateBody) { _, _ in hasEdits = true }
                    
                    // Placeholders Help Panel
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 4) {
                            placeholderRow(token: "{{borrower_name}}", label: "Borrower's Full Name")
                            placeholderRow(token: "{{emi_amount}}", label: "EMI Repayment Amount")
                            placeholderRow(token: "{{due_date}}", label: "EMI Repayment Due Date")
                        }
                        .padding(.top, 4)
                    } label: {
                        Label("Available Tokens", systemImage: "curlybraces")
                            .font(.adminCaption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Message Template")
                        .font(.adminSectionHeader)
                        .foregroundStyle(Color.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, 8)
                }
                
                // Section 5: Live Placeholders Preview
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Reminder Preview", systemImage: "eye.fill")
                                .font(.adminCaption)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                            Spacer()
                            Text("Simulated Borrower View")
                                .font(.adminCaption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider()
                        
                        Text(previewResolvedText)
                            .font(.adminSecondary)
                            .foregroundStyle(.primary)
                            .padding(.vertical, 4)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Live Preview")
                        .font(.adminSectionHeader)
                        .foregroundStyle(Color.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, 8)
                }
            }
            .navigationTitle(editingSchedule == nil ? "New Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { handleCancel() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveAction()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Stay", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
        }
    }
    
    // MARK: - Actions
    
    private func channelToggle(channel: NotificationChannel, title: String, icon: String) -> some View {
        Toggle(isOn: Binding(
            get: { selectedChannels.contains(channel) },
            set: { val in
                hasEdits = true
                if val {
                    selectedChannels.insert(channel)
                } else {
                    selectedChannels.remove(channel)
                }
            }
        )) {
            Label(title, systemImage: icon)
        }
        .tint(.blue)
    }
    
    private func placeholderRow(token: String, label: String) -> some View {
        HStack {
            Text(token)
                .font(.adminCaption.monospacedDigit())
                .foregroundStyle(.blue)
            Spacer()
            Text(label)
                .font(.adminCaption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func handleCancel() {
        if hasEdits {
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }
    
    private func saveAction() {
        var timingStr = ""
        switch timingType {
        case .before:
            timingStr = "\(timingDays) days before due date"
        case .on:
            timingStr = "On due date"
        case .after:
            timingStr = "\(timingDays) days after missed payment"
        }
        
        let schedule = ReminderSchedule(
            id: editingSchedule?.id ?? UUID(),
            name: name,
            timing: timingStr,
            channels: selectedChannels,
            templateBody: templateBody,
            isActive: editingSchedule?.isActive ?? true
        )
        
        onSave(schedule)
        dismiss()
    }
}

#Preview {
    AddReminderScheduleSheet(onSave: { _ in })
}
