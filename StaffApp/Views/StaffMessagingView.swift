import SwiftUI

// MARK: - Thread List

struct StaffMessagingView: View {
    @State private var threads: [MessageThread] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading conversations…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if threads.isEmpty {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Start a new message with a borrower from their application.")
                    )
                } else {
                    List(threads) { thread in
                        NavigationLink {
                            MessageThreadView(thread: thread)
                        } label: {
                            ThreadRow(thread: thread)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: Spacing.m, bottom: 4, trailing: Spacing.m))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Messages")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .task {
                if let t = try? await MockData.sharedMessagingService.threads(for: MockData.loanOfficerUser.id) {
                    threads = t
                }
                isLoading = false
            }
        }
    }
}

struct ThreadRow: View {
    let thread: MessageThread

    private var borrowerName: String {
        let ids = thread.participantIDs.filter { $0 != MockData.loanOfficerUser.id }
        return ids.compactMap { MockData.borrowerUser(for: $0)?.fullName }.first ?? "Unknown"
    }

    private var timeAgo: String {
        let diff = Date().timeIntervalSince(thread.updatedAt)
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.lmsPrimary, .lmsNavyBlue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Text(borrowerName.prefix(1))
                    .font(.lmsTitle2)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(borrowerName).font(.lmsHeadline)
                    Spacer()
                    Text(timeAgo).font(.caption2).foregroundStyle(.tertiary)
                }
                Text(thread.lastMessagePreview ?? "No messages yet.")
                    .font(.lmsCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(Spacing.m)
        .background(.background, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Chat View

struct MessageThreadView: View {
    let thread: MessageThread
    @State private var messages: [ChatMessage] = []
    @State private var draft = ""
    @State private var isSending = false
    @FocusState private var isInputFocused: Bool

    private var borrowerName: String {
        let ids = thread.participantIDs.filter { $0 != MockData.loanOfficerUser.id }
        return ids.compactMap { MockData.borrowerUser(for: $0)?.fullName }.first ?? "Chat"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Spacing.xs) {
                        ForEach(messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }
                    }
                    .padding(Spacing.m)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()

            // Input bar
            HStack(spacing: Spacing.s) {
                TextField("Type a message…", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .focused($isInputFocused)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: isSending ? "hourglass" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary : Color.lmsPrimary)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding(Spacing.m)
            .background(.regularMaterial)
        }
        .navigationTitle(borrowerName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let msgs = try? await MockData.sharedMessagingService.messages(threadID: thread.id) {
                messages = msgs
            }
        }
    }

    private func sendMessage() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isSending = true
        draft = ""
        let newMsg = ChatMessage(threadID: thread.id, senderID: MockData.loanOfficerUser.id, body: text)
        Task {
            if let sent = try? await MockData.sharedMessagingService.send(newMsg) {
                messages.append(sent)
            }
            isSending = false
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    private var isMine: Bool { message.senderID == MockData.loanOfficerUser.id }
    private var senderName: String {
        if isMine { return "You" }
        return MockData.borrowerUser(for: message.senderID)?.fullName ?? "Borrower"
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.s) {
            if isMine { Spacer(minLength: 60) }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 2) {
                if !isMine {
                    Text(senderName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.leading, Spacing.s)
                }
                Text(message.body)
                    .font(.lmsBody)
                    .foregroundStyle(isMine ? .white : .primary)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.s)
                    .background(
                        isMine
                            ? AnyShapeStyle(LinearGradient(colors: [.lmsNavyBlue, .lmsPrimary], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Color(.systemFill))
                        , in: RoundedRectangle(cornerRadius: 18)
                    )
                Text(shortTime(message.sentAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, Spacing.s)
            }

            if !isMine { Spacer(minLength: 60) }
        }
    }

    private func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

#Preview {
    StaffMessagingView()
}
