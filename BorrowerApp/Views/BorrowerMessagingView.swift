import SwiftUI

struct BorrowerMessagingView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var viewModel = MessagingViewModel()
    @State private var applications: [LoanApplication] = []

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.threads.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.lmsBackground.ignoresSafeArea())
            } else if viewModel.threads.isEmpty {
                ContentUnavailableView(
                    "No Conversations",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("You don't have any active support threads yet.")
                )
            } else {
                threadList
            }
        }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.large)
        .task { await loadData() }
    }

    private var threadList: some View {
        List {
            Section {
                ForEach(sortedThreads) { thread in
                    NavigationLink {
                        ChatDetailView(thread: thread, title: title(for: thread))
                    } label: {
                        ThreadRow(
                            title: title(for: thread),
                            subtitle: subtitle(for: thread),
                            preview: thread.lastMessagePreview ?? "—",
                            timestamp: thread.updatedAt,
                            icon: icon(for: thread),
                            iconColor: iconColor(for: thread),
                            principal: principal(for: thread),
                            tenure: tenure(for: thread)
                        )
                    }
                }
            } footer: {
                Text("Conversations are organised by application. Reach out to your loan officer or general support anytime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await loadData() }
    }

    private var sortedThreads: [MessageThread] {
        viewModel.threads.sorted { $0.updatedAt > $1.updatedAt }
    }

    // MARK: - Thread display helpers
    private func application(for thread: MessageThread) -> LoanApplication? {
        guard let appID = thread.applicationID else { return nil }
        return applications.first(where: { $0.id == appID })
    }

    private func title(for thread: MessageThread) -> String {
        if let app = application(for: thread) {
            return "\(app.loanType.rawValue.capitalized) Loan"
        }
        return "General Support"
    }

    private func subtitle(for thread: MessageThread) -> String {
        if let app = application(for: thread) {
            return "Application • \(app.status.displayLabel)"
        }
        return "Customer care"
    }

    private func icon(for thread: MessageThread) -> String {
        guard let app = application(for: thread) else { return "headphones" }
        switch app.loanType {
        case .home:      return "house.fill"
        case .personal:  return "person.fill"
        case .vehicle:   return "car.fill"
        case .business:  return "briefcase.fill"
        case .education: return "graduationcap.fill"
        }
    }

    private func principal(for thread: MessageThread) -> String? {
        application(for: thread).map { Formatting.currency($0.requestedAmount) }
    }

    private func tenure(for thread: MessageThread) -> String? {
        guard let app = application(for: thread) else { return nil }
        if app.tenureMonths % 12 == 0 {
            let years = app.tenureMonths / 12
            return "\(years) yr\(years == 1 ? "" : "s")"
        }
        return "\(app.tenureMonths) mo"
    }

    private func iconColor(for thread: MessageThread) -> Color {
        guard let app = application(for: thread) else { return .gray }
        switch app.loanType {
        case .home:      return .blue
        case .personal:  return .indigo
        case .vehicle:   return .orange
        case .business:  return .brown
        case .education: return .green
        }
    }

    private func loadData() async {
        guard let env, let userID = session.currentUser?.id else { return }
        await viewModel.fetchThreads(messagingService: env.messaging, userID: userID)
        if let apps = try? await env.loans.fetchApplications(for: userID) {
            applications = apps
        }
    }
}

// MARK: - Thread Row
private struct ThreadRow: View {
    let title: String
    let subtitle: String
    let preview: String
    let timestamp: Date
    let icon: String
    let iconColor: Color
    let principal: String?
    let tenure: String?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(relativeTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if principal != nil || tenure != nil {
                    HStack(spacing: Spacing.xs) {
                        if let principal {
                            Label(principal, systemImage: "indianrupeesign")
                                .labelStyle(.titleAndIcon)
                        }
                        if principal != nil && tenure != nil {
                            Text("•").foregroundStyle(.tertiary)
                        }
                        if let tenure {
                            Label(tenure, systemImage: "calendar")
                                .labelStyle(.titleAndIcon)
                        }
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                }

                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private var relativeTime: String {
        timestamp.formatted(.relative(presentation: .named))
    }
}

// MARK: - Chat Detail
struct ChatDetailView: View {
    let thread: MessageThread
    let title: String

    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var viewModel = MessagingViewModel()
    @FocusState private var composerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.activeThreadMessages.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                messageThread
            }
            inputBar
        }
        .background(Color.lmsBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let env else { return }
            await viewModel.selectThread(thread, messagingService: env.messaging)
        }
    }

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
