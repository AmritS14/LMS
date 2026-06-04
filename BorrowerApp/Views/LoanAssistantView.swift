import SwiftUI

struct LoanAssistantView: View {
    @StateObject private var viewModel: LoanAssistantViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var composerFocused: Bool

    init(borrowerId: String) {
        _viewModel = StateObject(wrappedValue: LoanAssistantViewModel(borrowerId: borrowerId))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.chatHistory.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    messageThread
                }
                inputBar
            }
            .background(Color.lmsBackground.ignoresSafeArea())
            .navigationTitle("AI Loan Officer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.chatHistory.isEmpty {
                        Button(role: .destructive) {
                            viewModel.clearHistory()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .accessibilityLabel("Clear conversation")
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("AI Loan Officer")
                .font(.title2.weight(.semibold))
            Text("Ask me anything about your loan options, eligibility, EMIs, or your account status.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Message Thread

    private var messageThread: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.xs) {
                    ForEach(viewModel.chatHistory) { msg in
                        messageBubble(msg).id(msg.id)
                    }
                    if viewModel.isLoading {
                        typingIndicator.id("typing")
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.chatHistory.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isLoading) { _, isLoading in
                if isLoading { scrollToBottom(proxy: proxy, anchor: "typing") }
            }
            .onAppear { scrollToBottom(proxy: proxy) }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, anchor: String? = nil) {
        let id = anchor ?? viewModel.chatHistory.last.map { $0.id.uuidString } ?? ""
        guard !id.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(id, anchor: .bottom)
        }
    }

    // MARK: - Bubble

    @ViewBuilder
    private func messageBubble(_ msg: AIChatMessage) -> some View {
        let isUser = msg.role == "user"
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 2) {
                Text(msg.text)
                    .font(.body)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.s)
                    .background(isUser ? Color.accentColor : Color.lmsSurface)
                    .foregroundStyle(isUser ? .white : .primary)
                    .clipShape(bubbleShape(isUser: isUser))

                Text(msg.sentAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.xs)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }

    private func bubbleShape(isUser: Bool) -> some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: 18,
            bottomLeadingRadius: isUser ? 18 : 4,
            bottomTrailingRadius: isUser ? 4 : 18,
            topTrailingRadius: 18,
            style: .continuous
        )
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 7, height: 7)
                        .opacity(0.4)
                        .animation(
                            .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                            value: viewModel.isLoading
                        )
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.s)
            .background(Color.lmsSurface)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 18, bottomLeadingRadius: 4,
                    bottomTrailingRadius: 18, topTrailingRadius: 18,
                    style: .continuous
                )
            )
            Spacer(minLength: 60)
        }
        .accessibilityLabel("AI is typing")
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: Spacing.s) {
            TextField("Ask about loans...", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.s)
                .background(Color.lmsSurface, in: Capsule())
                .focused($composerFocused)

            Button {
                Task { await viewModel.sendMessage() }
            } label: {
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
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading
    }
}
