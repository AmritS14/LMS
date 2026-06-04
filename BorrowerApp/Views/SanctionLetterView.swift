import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(url: url)
    }
}

struct SanctionLetterView: View {
    let application: LoanApplication
    var customPath: String? = nil
    @State private var viewModel = SanctionLetterViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header Info Card
            metadataHeaderCard
                .padding(.horizontal, Spacing.m)
                .padding(.top, Spacing.m)
                .padding(.bottom, Spacing.s)

            if viewModel.isLoading {
                Spacer()
                VStack(spacing: Spacing.m) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.accentColor)
                    Text("Fetching sanction letter PDF...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                VStack(spacing: Spacing.m) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.lmsDanger)
                    
                    Text("Could Not Load PDF")
                        .font(.headline)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.l)
                    
                    Button("Retry") {
                        Task {
                            await viewModel.loadPDF(applicationID: application.id, customPath: customPath)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                }
                Spacer()
            } else if let pdfURL = viewModel.pdfURL {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Document Preview")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Spacing.m)

                    PDFKitView(url: pdfURL)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .fill(Color.lmsSurface)
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, Spacing.m)
                        .padding(.bottom, Spacing.m)
                }

                Divider()

                // Actions
                HStack(spacing: Spacing.m) {
                    ShareLink(item: pdfURL) {
                        Label("Share / Export", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 28)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: CornerRadius.button))
                    .controlSize(.large)
                    .tint(.accentColor)
                }
                .padding(Spacing.m)
                .background(Color.lmsSurface)
            } else {
                Spacer()
                Text("No sanction letter PDF available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .background(Color.lmsBackground.ignoresSafeArea(edges: .bottom))
        .navigationTitle("Sanction Letter")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPDF(applicationID: application.id, customPath: customPath)
        }
    }

    private var metadataHeaderCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(application.productName ?? "\(application.loanType.rawValue.capitalized) Loan")
                        .font(.headline)
                    Text("Application ID: APP-\(application.id.uuidString.prefix(8).uppercased())")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(application.status.rawValue.capitalized, tone: .success)
            }

            Divider()

            HStack {
                statRow(title: "Approved Amount", value: Formatting.currency(application.requestedAmount))
                Spacer()
                let displayRate = application.interestRate > 1.0 ? application.interestRate / 100.0 : application.interestRate
                statRow(title: "Interest Rate", value: Formatting.percent(displayRate))
                Spacer()
                statRow(title: "Tenure", value: "\(application.tenureMonths) months")
            }
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(Color.lmsSeparator.opacity(0.2), lineWidth: 0.5)
        )
    }

    private func statRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}
