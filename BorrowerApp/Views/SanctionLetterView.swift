import SwiftUI
import PDFKit

struct SanctionLetterView: View {
    let application: LoanApplication
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SanctionLetterViewModel()
    @State private var showFullScreenPDF = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading Sanction Letter…").progressViewStyle(.circular)
                    .controlSize(.large)
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                ContentUnavailableView(
                    "Error Loading Letter",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
                Button("Try Again") {
                    Task { await loadData() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                Spacer()
            } else if let letter = viewModel.sanctionLetter {
                if viewModel.showSuccessMessage {
                    successStateView
                } else {
                    mainContent(letter)
                }
            } else {
                Spacer()
                ContentUnavailableView(
                    "No Sanction Letter",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("An official sanction letter is generated once your application is approved.")
                )
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.lmsBackground.ignoresSafeArea())
        .navigationTitle("Sanction Letter")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
        .sheet(isPresented: $showFullScreenPDF) {
            fullScreenPDFPreview
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func mainContent(_ letter: SanctionLetter) -> some View {
        ScrollView {
            VStack(spacing: Spacing.m) {
                // Header details
                summaryCard(letter)
                
                // PDF Mini Preview Card
                pdfPreviewCard
                
                // Terms Checklist
                if !letter.isAccepted {
                    acceptanceCard
                } else {
                    alreadyAcceptedCard(letter)
                }
            }
            .padding(Spacing.m)
        }
    }

    private func summaryCard(_ letter: SanctionLetter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Text("Loan Summary")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                StatusBadge(
                    letter.isAccepted ? "Accepted" : "Pending Acceptance",
                    tone: letter.isAccepted ? .success : .warning
                )
            }
            
            Divider()
            
            VStack(spacing: Spacing.xs) {
                summaryRow(label: "Borrower Name", value: application.borrowerName ?? "Borrower")
                summaryRow(label: "Loan Type", value: application.loanType.rawValue.capitalized + " Loan")
                summaryRow(label: "Sanctioned Amount", value: Formatting.currency(application.requestedAmount))
                summaryRow(label: "Interest Rate (p.a.)", value: String(format: "%.2f%% (Fixed)", application.interestRate))
                summaryRow(label: "Tenure", value: "\(application.tenureMonths) Months")
                summaryRow(label: "Sanction Date", value: Formatting.date(letter.generatedDate))
            }
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    private var pdfPreviewCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Document Preview")
                .font(.headline)
                .foregroundStyle(.primary)
            
            ZStack(alignment: .center) {
                if let pdfURL = viewModel.pdfURL, let data = try? Data(contentsOf: pdfURL) {
                    PDFKitView(pdfData: data)
                        .frame(height: 200)
                        .cornerRadius(CornerRadius.medium)
                        .disabled(true) // Disable interactions in mini preview
                } else {
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .fill(Color.lmsBackground)
                        .frame(height: 200)
                    ProgressView().progressViewStyle(.circular)
                }
                
                // Tap Overlay
                Button {
                    showFullScreenPDF = true
                } label: {
                    Color.black.opacity(0.02)
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: Spacing.s) {
                Button {
                    showFullScreenPDF = true
                } label: {
                    Label("View Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs_s)
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)
                
                if let pdfURL = viewModel.pdfURL {
                    ShareLink(
                        item: pdfURL,
                        preview: SharePreview("Sanction Letter", image: Image(systemName: "doc.text.fill"))
                    ) {
                        Label("Share PDF", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.xs_s)
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                }
            }
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    private var acceptanceCard: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Acceptance & E-Sign")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("By checking the box below and tapping Accept, you acknowledge that you have read, understood, and agreed to all terms and conditions detailed in this Loan Sanction Letter. This constitutes a legally binding e-signature.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(nil)
            
            Toggle(isOn: $viewModel.termsAccepted) {
                Text("I have read and accepted the terms and conditions.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .tint(.accentColor)
            
            Button {
                Task {
                    let success = await viewModel.acceptSanctionLetter(
                        sanctionLettersService: env!.sanctionLetters,
                        application: application
                    )
                    if success {
                        // Send system notification
                        try? await env?.notifications.sendNotification(
                            topic: .system,
                            title: "Sanction Letter Accepted",
                            body: "You have accepted the sanction terms for your \(application.loanType.rawValue) loan."
                        )
                    }
                }
            } label: {
                if viewModel.isAccepting {
                    ProgressView().progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Accept Sanction Letter")
                        .font(.headline)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.lmsSuccess)
            .disabled(!viewModel.termsAccepted || viewModel.isAccepting)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    private func alreadyAcceptedCard(_ letter: SanctionLetter) -> some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
            
            Text("Sanction Letter Accepted")
                .font(.headline)
            
            if let date = letter.acceptedAt {
                Text("Digitally signed on \(Formatting.date(date))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.m)
        .background(Color.lmsSuccess.opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(Color.lmsSuccess.opacity(0.3), lineWidth: 1)
        )
    }

    private var successStateView: some View {
        VStack(spacing: Spacing.m) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("Terms Accepted Successfully!")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            
            Text("Your accepted sanction letter has been logged. The underwriting team will now proceed with the disbursement process.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.l)
            
            Spacer()
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .padding(.bottom, Spacing.xl)
        }
        .padding(Spacing.m)
    }

    private var fullScreenPDFPreview: some View {
        NavigationStack {
            Group {
                if let pdfURL = viewModel.pdfURL, let data = try? Data(contentsOf: pdfURL) {
                    PDFKitView(pdfData: data)
                } else {
                    ProgressView().progressViewStyle(.circular)
                }
            }
            .navigationTitle("Sanction Letter PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        showFullScreenPDF = false
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        }
    }

    private func loadData() async {
        guard let env else { return }
        await viewModel.loadSanctionLetter(
            sanctionLettersService: env.sanctionLetters,
            application: application
        )
    }
}

// MARK: - PDFKitView Representable

struct PDFKitView: UIViewRepresentable {
    let pdfData: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(data: pdfData) {
            uiView.document = document
        }
    }
}
