with open('StaffApp/Views/LoanOfficer/LOAppViewModel.swift', 'r') as f:
    content = f.read()

content = content.replace(
    'let type: ActivityType = event.status == .approved ? .approved : (event.status == .escalated ? .escalation : .assignedApplication)',
    'let type: ActivityType = event.status == .approved ? .approved : (event.status == .escalated ? .escalation : .newApplication)'
)

content = content.replace(
    '''                            unreadCount: unread,
                            applicationId: app?.sourceApplicationID?.uuidString ?? "",
                            messages: loMsgs.sorted { $0.timestamp < $1.timestamp },''',
    '''                            unreadCount: unread,
                            messages: loMsgs.sorted { $0.timestamp < $1.timestamp },'''
)

with open('StaffApp/Views/LoanOfficer/LOAppViewModel.swift', 'w') as f:
    f.write(content)
