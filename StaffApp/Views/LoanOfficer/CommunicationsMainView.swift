import SwiftUI

struct CommunicationsMainView: View {
    @Environment(LoanOfficerStore.self) private var store
    @State private var searchText: String = ""

    private var filtered: [OfficerConversation] {
        guard !searchText.isEmpty else { return store.conversations }
        return store.conversations.filter {
            $0.borrowerName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if store.conversations.isEmpty {
                ContentUnavailableView(
                    "No conversations",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Borrower threads will appear here once messaging is set up.")
                )
            } else {
                List {
                    ForEach(filtered) { conversation in
                        NavigationLink(value: OfficerRoute.conversation(conversation.id)) {
                            row(conversation)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search borrowers")
            }
        }
        .navigationTitle("Communications")
        .task { await store.refreshAll() }
    }

    private func row(_ conversation: OfficerConversation) -> some View {
        HStack(spacing: Spacing.sm) {
            AvatarView(initials: conversation.borrowerInitials,
                       size: 48,
                       showOnlineIndicator: true,
                       isOnline: conversation.isOnline)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.borrowerName)
                        .font(.headline)
                    Spacer()
                    Text(OfficerFormat.timeAgo(conversation.lastMessageTime))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(conversation.lastMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if conversation.unreadCount > 0 {
                CountBadge(count: conversation.unreadCount, tint: .lmsAccent)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
