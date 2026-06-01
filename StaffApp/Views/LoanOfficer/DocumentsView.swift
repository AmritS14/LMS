import SwiftUI

struct DocumentsView: View {
    @Environment(AppViewModel.self) var viewModel

    @State private var selectedDocument: DigitalDocument?
    @State private var selectedCategory = "All"

    private let categories = ["All", "Sanction Letters", "Reports", "Policies"]

    private var filteredDocuments: [DigitalDocument] {
        if selectedCategory == "All" {
            return viewModel.digitalDocuments
        }

        return viewModel.digitalDocuments.filter { document in
            switch selectedCategory {
            case "Sanction Letters":
                return document.title.localizedCaseInsensitiveContains("sanction")
            case "Reports":
                return document.title.localizedCaseInsensitiveContains("report")
            case "Policies":
                return document.title.localizedCaseInsensitiveContains("policy")
            default:
                return true
            }
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header

                categoryChips

                if filteredDocuments.isEmpty {
                    ContentUnavailableView(
                        "No Documents",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Try a different category.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredDocuments) { document in
                            Button {
                                selectedDocument = document
                            } label: {
                                documentCard(document)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedDocument) { document in
            DocumentDetailSheet(document: document)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Document Vault")
                .font(.system(.title2, design: .rounded).weight(.semibold))
            Text("Review borrower uploads and sanctioned files")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selectedCategory == category ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule().fill(selectedCategory == category ? Color.blue : Color(.tertiarySystemGroupedBackground))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func documentCard(_ document: DigitalDocument) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.blue.opacity(0.12))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: document.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.blue)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(document.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(document.type)
                    Text("•")
                    Text(document.fileSize)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

                Text(AppFormatters.formatDate(document.generatedDate))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                if document.isSigned {
                    Label("Signed", systemImage: "checkmark.seal.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                }

                if document.borrowerAcknowledged {
                    Label("Ack", systemImage: "hand.thumbsup.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator).opacity(0.15), lineWidth: 0.5)
        )
    }
}

private struct DocumentDetailSheet: View {
    let document: DigitalDocument

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            detailRow(title: "Type", value: document.type)
                            detailRow(title: "File Size", value: document.fileSize)
                            detailRow(title: "Generated", value: AppFormatters.formatDate(document.generatedDate))
                            detailRow(title: "Signed", value: document.isSigned ? "Yes" : "No")
                            detailRow(title: "Borrower Acknowledged", value: document.borrowerAcknowledged ? "Yes" : "No")
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Document Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.blue.opacity(0.12))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: document.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Loan officer document record")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.primary)
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        DocumentsView()
            .environment(AppViewModel())
    }
}

