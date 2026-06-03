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
                if msg.body.hasPrefix("[Sanction Letter]:") {
                    sanctionLetterCard(isMe: isMe)
                } else {
                    Text(msg.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isMe ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(isMe ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                Text(msg.sentAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if !isMe { Spacer(minLength: 50) }
        }
    }

    @ViewBuilder
    private func sanctionLetterCard(isMe: Bool) -> some View {
        if let pdfURL = getPDFURL() {
            ShareLink(
                item: pdfURL,
                preview: SharePreview("Sanction Letter", image: Image(systemName: "doc.text.fill"))
            ) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(.red)
                            .font(.title3)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Loan Sanction Letter")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isMe ? .white : .primary)
                            .multilineTextAlignment(.leading)
                        Text("Tap to view or share PDF")
                            .font(.caption)
                            .foregroundStyle(isMe ? .white.opacity(0.8) : .secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer(minLength: 8)
                    
                    Image(systemName: "square.and.arrow.up")
                        .font(.footnote)
                        .foregroundStyle(isMe ? .white.opacity(0.8) : .secondary)
                }
                .padding(12)
                .background(isMe ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 280)
        } else {
            Text("Sanction Letter PDF")
                .padding(12)
                .background(isMe ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                .foregroundStyle(isMe ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func getPDFURL() -> URL? {
        guard let appID = application.sourceApplicationID else { return nil }
        let amount = Decimal(application.loanAmount)
        let rate = application.interestRate
        let tenure = application.tenure
        let fee = max(Decimal(2500), amount * Decimal(0.015))
        let referenceCode = "SL-" + appID.uuidString.replacingOccurrences(of: "-", with: "").prefix(6).uppercased()
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("Sanction_Letter_\(appID.uuidString).pdf")
        let lType = LoanType(rawValue: application.loanType.lowercased().replacingOccurrences(of: " loan", with: "")) ?? .personal
        let emi = amount / Decimal(max(tenure, 1))
        
        let pdfData = SupabaseSanctionLetterService.drawPDF(
            applicationID: appID,
            amount: amount,
            interestRate: rate,
            tenureMonths: tenure,
            loanType: lType,
            borrowerName: application.borrowerName,
            referenceCode: referenceCode,
            emi: emi,
            fee: fee
        )
        try? pdfData.write(to: fileURL)
        return fileURL
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
