import SwiftUI

/// Officer-facing chat bound to the real borrower⇄officer thread for an
/// application. Mirrors the borrower's chat so the conversation is two-way.
struct LOConversationView: View {
    let application: LOLoanApplication

    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var thread: MessageThread?
    @State private var messages: [ChatMessage] = []
    @State private var draft: String = ""
    @State private var isLoading = true
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    Spacer(); ProgressView(); Spacer()
                } else if let errorMessage {
                    Spacer()
                    ContentUnavailableView("Couldn't Load Chat", systemImage: "exclamationmark.bubble", description: Text(errorMessage))
                    Spacer()
                } else {
                    messageList
                }
                inputBar
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(application.borrowerName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await load() }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { msg in
                        bubble(msg).id(msg.id)
                    }
                }
                .padding(12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    @ViewBuilder
    private func bubble(_ msg: ChatMessage) -> some View {
        let isMe = msg.senderID == session.currentUser?.id
        HStack {
            if isMe { Spacer(minLength: 50) }
            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                Text(msg.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isMe ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(isMe ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text(msg.sentAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if !isMe { Spacer(minLength: 50) }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message borrower", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground), in: Capsule())
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(canSend ? Color.accentColor : Color(.systemGray3))
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending && thread != nil
    }

    private func load() async {
        guard let env,
              let appID = application.sourceApplicationID,
              let borrowerID = application.borrowerID,
              let officerID = session.currentUser?.id else {
            errorMessage = "Conversation unavailable for this application."
            isLoading = false
            return
        }
        do {
            let t = try await env.messaging.ensureThread(applicationID: appID, participantIDs: [officerID, borrowerID])
            thread = t
            messages = try await env.messaging.messages(threadID: t.id)
            try? await env.messaging.markRead(threadID: t.id, upTo: Date())
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func send() {
        guard let env, let thread, let officerID = session.currentUser?.id else { return }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        draft = ""
        isSending = true
        Task {
            let message = ChatMessage(threadID: thread.id, senderID: officerID, body: text)
            if let sent = try? await env.messaging.send(message) {
                messages.append(sent)
            } else {
                draft = text
            }
            isSending = false
        }
    }
}
