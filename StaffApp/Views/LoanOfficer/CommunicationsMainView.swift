//
//  CommunicationsMainView.swift
//  loan officer
//
//  Created by Aadya Tiwari on 21/05/26.
//


import SwiftUI

struct CommunicationsMainView: View {

    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {

        ScrollView(.vertical, showsIndicators: false) {

            VStack(spacing: 20) {

                // MARK: Header

                VStack(alignment: .leading, spacing: 4) {

                    Text("Communications")
                        .font(
                            .system(
                                size: 28,
                                weight: .bold,
                                design: .rounded
                            )
                        )

                    Text("Borrower conversations & updates")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // MARK: Conversations

                VStack(spacing: 14) {

                    ForEach(viewModel.conversations) { conversation in

                        Button {

                            viewModel.selectedConversation = conversation

                        } label: {

                            HStack(spacing: 14) {

                                AvatarView(
                                    initials: conversation.borrowerInitials,
                                    size: 52,
                                    showOnlineIndicator: true,
                                    isOnline: conversation.isOnline
                                )

                                VStack(alignment: .leading, spacing: 4) {

                                    HStack {

                                        Text(conversation.borrowerName)
                                            .font(
                                                .system(
                                                    size: 16,
                                                    weight: .semibold
                                                )
                                            )
                                            .foregroundStyle(.primary)

                                        Spacer()

                                        Text(
                                            AppFormatters.timeAgo(
                                                conversation.lastMessageTime
                                            )
                                        )
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                    }

                                    Text(conversation.lastMessage)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)

                                    if conversation.unreadCount > 0 {

                                        HStack {

                                            Spacer()

                                            CountBadge(
                                                count: conversation.unreadCount
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        Color(
                                            .secondarySystemGroupedBackground
                                        )
                                    )
                            )
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Communications")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.selectedConversation) { conversation in

            ChatView(conversation: conversation)
                .environmentObject(viewModel)
        }
    }
}

#Preview {

    NavigationStack {

        CommunicationsMainView()
            .environmentObject(AppViewModel())
    }
}
