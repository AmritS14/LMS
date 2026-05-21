import SwiftUI

struct BorrowerMessagingView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    
    @State private var viewModel = MessagingViewModel()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.threads.isEmpty {
                ProgressView()
            } else if viewModel.activeThread == nil {
                VStack(spacing: 16) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No active conversations")
                        .font(.headline)
                }
            } else {
                VStack(spacing: 0) {
                    messageThread
                    Divider()
                    inputBar
                }
            }
        }
        .navigationTitle("Support Chat")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let env = env, let userID = session.currentUser?.id else { return }
            await viewModel.fetchThreads(messagingService: env.messaging, userID: userID)
            if let first = viewModel.threads.first {
                await viewModel.selectThread(first, messagingService: env.messaging)
            }
        }
    }



    // MARK: - Message Thread
    var messageThread: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.activeThreadMessages) { msg in
                        messageView(msg).id(msg.id)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
            }
            .onChange(of: viewModel.activeThreadMessages.count) { _, _ in
                if let last = viewModel.activeThreadMessages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onAppear {
                if let last = viewModel.activeThreadMessages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Single Message View
    @ViewBuilder
    func messageView(_ msg: ChatMessage) -> some View {
        let isMe = msg.senderID == session.currentUser?.id
        HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 60) }

            if !isMe {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
                    .offset(y: -4)
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if !isMe {
                    Text("Officer")
                        .font(.caption2).bold()
                        .foregroundStyle(.blue)
                        .padding(.leading, 4)
                }

                Text(msg.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(isMe ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundStyle(isMe ? .white : .primary)
                    .clipShape(bubbleShape(isMe: isMe))
                    .font(.subheadline)

                Text(Formatting.date(msg.sentAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            if !isMe { Spacer(minLength: 60) }
        }
        .padding(.vertical, 3)
    }

    func bubbleShape(isMe: Bool) -> some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius:     isMe ? 16 : 4,
            bottomLeadingRadius:  16,
            bottomTrailingRadius: isMe ? 4 : 16,
            topTrailingRadius:    16
        )
    }

    // MARK: - Input Bar
    var inputBar: some View {
        HStack(spacing: 10) {
            @Bindable var vm = viewModel
            TextField("Message…", text: $vm.newMessageText, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button {
                Task {
                    guard let env = env, let userID = session.currentUser?.id else { return }
                    await viewModel.sendMessage(messagingService: env.messaging, senderID: userID)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.secondary : Color.blue
                    )
            }
            .disabled(viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }
}
