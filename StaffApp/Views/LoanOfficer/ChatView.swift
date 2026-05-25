import SwiftUI

struct ChatView: View {
    @Environment(LoanOfficerStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let conversationID: UUID
    @State private var draft: String = ""
    @FocusState private var inputFocused: Bool

    private var conversation: OfficerConversation? {
        store.conversations.first { $0.id == conversationID }
    }

    var body: some View {
        Group {
            if let conversation {
                content(for: conversation)
            } else {
                ContentUnavailableView(
                    "Conversation unavailable",
                    systemImage: "bubble.left.and.exclamationmark.bubble.right"
                )
            }
        }
        .navigationTitle(conversation?.borrowerName ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(for conversation: OfficerConversation) -> some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Spacing.s) {
                        ForEach(conversation.messages) { message in
                            bubble(message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.top, Spacing.m)
                }
                .onChange(of: conversation.messages.count) { _, _ in
                    if let last = conversation.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()

            HStack(spacing: Spacing.s) {
                TextField("Message…", text: $draft, axis: .vertical)
                    .focused($inputFocused)
                    .lineLimit(1...4)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.s)
                    .background(Color.lmsTertiarySurface,
                                in: RoundedRectangle(cornerRadius: CornerRadius.medium))

                Button {
                    send(in: conversation.id)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(draft.trimmingCharacters(in: .whitespaces).isEmpty
                                         ? Color.lmsGray4 : Color.lmsAccent)
                }
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(Spacing.sm)
            .background(.bar)
        }
    }

    private func bubble(_ message: ConversationMessage) -> some View {
        HStack {
            if message.sender == .officer { Spacer(minLength: 40) }
            VStack(alignment: message.sender == .officer ? .trailing : .leading,
                   spacing: 2) {
                Text(message.text)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.s)
                    .background(message.sender == .officer
                                ? Color.lmsAccent : Color.lmsFill,
                                in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                    .foregroundStyle(message.sender == .officer ? .white : .primary)
                Text(OfficerFormat.timeAgo(message.sentAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if message.sender == .borrower { Spacer(minLength: 40) }
        }
    }

    private func send(in id: UUID) {
        let trimmed = draft.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        draft = ""
        Task { await store.sendMessage(trimmed, in: id) }
    }
}
