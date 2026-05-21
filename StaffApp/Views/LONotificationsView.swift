import SwiftUI

struct LONotificationsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            NotificationRow(
                icon: "doc.text.fill",
                iconColor: .blue,
                title: "Document Re-uploaded",
                message: "Jane Doe re-uploaded her Income Statement.",
                time: "10m ago",
                isUnread: true
            )
            
            NotificationRow(
                icon: "person.crop.circle.badge.plus",
                iconColor: .lmsPrimary,
                title: "New Assignment",
                message: "You have been assigned Application #APP-991.",
                time: "2h ago",
                isUnread: true
            )
            
            NotificationRow(
                icon: "exclamationmark.triangle.fill",
                iconColor: .lmsWarning,
                title: "Compliance Alert",
                message: "High DTI ratio flagged for Robert King.",
                time: "1d ago",
                isUnread: false
            )
        }
        .listStyle(.plain)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

struct NotificationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let time: String
    let isUnread: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.lmsHeadline)
                    Spacer()
                    Text(time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(message)
                    .font(.lmsSubheadline)
                    .foregroundColor(.secondary)
            }
            
            if isUnread {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
