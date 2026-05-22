import SwiftUI

struct BorrowerMessagingView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var viewModel = MessagingViewModel()
    @FocusState private var composerFocused: Bool

    var body: some View {
        ZStack {
            Color.lmsBackground.ignoresSafeArea()

            if viewModel.isLoading && viewModel.threads.isEmpty {
                ProgressView()
            } else if viewModel.activeThread == nil {
                ContentUnavailableView(
                    "No Conversations",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("You don't have any active support threads yet.")
                )
            } else {
                VStack(spacing: 0) {
                    messageThread
                    inputBar
                }
            }
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let env, let userID = session.currentUser?.id else { return }
            await viewModel.fetchThreads(messagingService: env.messaging, userID: userID)
            if let first = viewModel.threads.first {
                await viewModel.selectThread(first, messagingService: env.messaging)
            }
        }
    }

    // MARK: - Message Thread
    private var messageThread: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.xs) {
                    ForEach(viewModel.activeThreadMessages) { msg in
                        messageBubble(msg).id(msg.id)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.activeThreadMessages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onAppear { scrollToBottom(proxy: proxy) }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let last = viewModel.activeThreadMessages.last {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    // MARK: - Single Message Bubble
    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isMe = msg.senderID == session.currentUser?.id
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            if isMe { Spacer(minLength: 60) }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                Text(msg.body)
                    .font(.body)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.s)
                    .background(isMe ? Color.accentColor : Color.lmsSurface)
                    .foregroundStyle(isMe ? .white : .primary)
                    .clipShape(bubbleShape(isMe: isMe))

                Text(Formatting.date(msg.sentAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.xs)
            }

            if !isMe { Spacer(minLength: 60) }
        }
    }

    private func bubbleShape(isMe: Bool) -> some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius:     18,
            bottomLeadingRadius:  isMe ? 18 : 4,
            bottomTrailingRadius: isMe ? 4 : 18,
            topTrailingRadius:    18,
            style: .continuous
        )
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        @Bindable var vm = viewModel
        return HStack(alignment: .bottom, spacing: Spacing.s) {
            TextField("Message", text: $vm.newMessageText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.s)
                .background(Color.lmsSurface, in: Capsule())
                .focused($composerFocused)

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(canSend ? Color.accentColor : Color.lmsGray4)
            }
            .disabled(!canSend)
            .animation(.easeInOut(duration: 0.15), value: canSend)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.s)
        .background(.bar)
    }

    private var canSend: Bool {
        !viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.isSending
    }

    private func send() {
        guard let env, let userID = session.currentUser?.id else { return }
        Task {
            await viewModel.sendMessage(messagingService: env.messaging, senderID: userID)
        }
    }
}

#Preview {
    NavigationStack {
        BorrowerMessagingView()
            .environment(SessionStore(
                currentUser: MockAuthService.seedBorrower,
                borrowerProfile: MockAuthService.seedBorrowerProfile
            ))
            .environment(\.appEnvironment, AppEnvironment(
                auth: MockAuthService(),
                loans: MockLoanService(),
                documents: MockDocumentService(),
                notifications: MockNotificationService(),
                messaging: MockMessagingService(),
                keychain: MockKeychainService()
            ))
    }
}
