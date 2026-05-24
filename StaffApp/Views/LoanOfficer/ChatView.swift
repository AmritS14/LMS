//
//  ChatView.swift
//  loan officer
//

import SwiftUI

struct ChatView: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AppViewModel

    let conversation: BorrowerConversation

    @State private var messageText = ""

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                // MARK: Messages

                ScrollView {

                    LazyVStack(spacing: 12) {

                        ForEach(conversation.messages) { message in

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

                ToolbarItem(placement: .topBarLeading) {

                    Button("Close") {
                        dismiss()
                    }
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

    // MARK: - Send Message

    private func sendMessage() {

        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        print("Message Sent: \(messageText)")

        messageText = ""
    }
}

#Preview {

    ChatView(
        conversation: SampleData.conversations[0]
    )
    .environmentObject(AppViewModel())
}
