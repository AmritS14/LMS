//
//  ChatView.swift
//  loan officer
//

import SwiftUI

struct ChatView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(AppViewModel.self) var viewModel
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    let conversation: BorrowerConversation
    var isPushed: Bool = false

    @State private var messageText = ""
    @State private var messages: [LOChatMessage] = []
    @State private var isLoading = true

    var body: some View {
        if isPushed {
            chatContent
                .task { await loadMessages() }
        } else {
            NavigationStack {
                chatContent
                    .task { await loadMessages() }
            }
        }
    }

    private var chatContent: some View {
        VStack(spacing: 0) {

            // MARK: Messages
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            HStack {
                                if message.sender == .officer {
                                    Spacer()
                                    messageBubble(
                                        text: message.text,
                                        color: .blue,
                                        textColor: .white,
                                        alignment: .trailing
                                    )
                                } else {
                                    messageBubble(
                                        text: message.text,
                                        color: Color(.secondarySystemBackground),
                                        textColor: .primary,
                                        alignment: .leading
                                    )
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 16)
                }
            }

            Divider()

            // MARK: Bottom Input

            HStack(spacing: 12) {

                TextField(
                    "Type a message...",
                    text: $messageText
                )
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemBackground))
                )

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(conversation.borrowerName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isPushed {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) { Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.primary).padding(8).background(Color(uiColor: .systemGray5), in: Circle()) }
                }
            }
        }
    }

    // MARK: - Message Bubble

    private func messageBubble(
        text: String,
        color: Color,
        textColor: Color,
        alignment: HorizontalAlignment
    ) -> some View {

        VStack(alignment: alignment, spacing: 4) {

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(textColor)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color)
                )
        }
        .frame(maxWidth: 260, alignment: alignment == .leading ? .leading : .trailing)
    }

    // MARK: - Load Messages

    private func loadMessages() async {
        guard let env else {
            self.messages = conversation.messages
            self.isLoading = false
            return
        }
        do {
            let dbMsgs = try await env.messaging.messages(threadID: conversation.id)
            let currentUserID = session.currentUser?.id ?? MockOfficerData.officerUserID
            self.messages = dbMsgs.map { m in
                LOChatMessage(
                    text: m.body,
                    sender: m.senderID == currentUserID ? .officer : .borrower,
                    timestamp: m.sentAt,
                    isRead: m.readAt != nil
                )
            }
            try? await env.messaging.markRead(threadID: conversation.id, upTo: Date())
        } catch {
            print("Failed to load messages from DB: \(error)")
            self.messages = conversation.messages
        }
        self.isLoading = false
    }

    // MARK: - Send Message

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        let text = messageText.trimmingCharacters(in: .whitespaces)
        messageText = ""

        let localMsg = LOChatMessage(
            text: text,
            sender: .officer,
            timestamp: Date(),
            isRead: true
        )
        self.messages.append(localMsg)

        guard let env else { return }
        let currentUserID = session.currentUser?.id ?? MockOfficerData.officerUserID
        Task {
            do {
                let msg = ChatMessage(
                    threadID: conversation.id,
                    senderID: currentUserID,
                    body: text
                )
                _ = try await env.messaging.send(msg)
                
                // Refresh AppViewModel data in background so the list gets the latest preview message.
                await viewModel.refreshFromService()
            } catch {
                print("Failed to send message: \(error)")
            }
        }
    }
}

#Preview {
    ChatView(
        conversation: BorrowerConversation(
            id: UUID(),
            applicationID: nil,
            borrowerName: "Preview User",
            borrowerInitials: "PU",
            lastMessage: "",
            lastMessageTime: Date(),
            unreadCount: 0,
            messages: [],
            isOnline: false
        )
    )
    .environment(AppViewModel())
    .environment(SessionStore(
        currentUser: User(
            id: UUID(),
            fullName: "Sarah Mehta",
            email: "sarah.mehta@example.com",
            phone: "+91 99887 76543",
            role: .loanOfficer
        )
    ))
}
