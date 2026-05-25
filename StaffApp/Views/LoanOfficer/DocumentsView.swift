import SwiftUI

struct DocumentsView: View {
    @Environment(LoanOfficerStore.self) private var store
    @State private var selectedCategory: GeneratedDocument.Category?
    @State private var selectedDocument: GeneratedDocument?

    private var grouped: [(GeneratedDocument.Category, [GeneratedDocument])] {
        let categories = selectedCategory.map { [$0] } ?? GeneratedDocument.Category.allCases
        return categories.map { category in
            (category, store.generatedDocuments.filter { $0.category == category })
        }
    }

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s) {
                        chip(label: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(GeneratedDocument.Category.allCases, id: \.self) { cat in
                            chip(label: cat.rawValue,
                                 icon: cat.icon,
                                 isSelected: selectedCategory == cat) {
                                selectedCategory = (selectedCategory == cat) ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.s)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            ForEach(grouped, id: \.0) { category, items in
                if !items.isEmpty {
                    Section(category.rawValue) {
                        ForEach(items) { doc in
                            Button {
                                selectedDocument = doc
                            } label: {
                                row(doc)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Documents")
        .sheet(item: $selectedDocument) { documentSheet($0) }
    }

    private func row(_ doc: GeneratedDocument) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: doc.category.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.lmsAccent)
                .frame(width: 44, height: 44)
                .background(Color.lmsAccent.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: CornerRadius.small))
            VStack(alignment: .leading, spacing: 4) {
                Text(doc.title).font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    Text(doc.category.rawValue)
                    Text("•")
                    Text(doc.fileSize)
                }
                .font(.caption).foregroundStyle(.secondary)
                Text(OfficerFormat.date(doc.generatedDate))
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if doc.isSigned {
                    StatusBadge("Signed", tone: .success,
                                icon: "checkmark.seal.fill", size: .small)
                }
                if doc.borrowerAcknowledged {
                    StatusBadge("Ack'd", tone: .info,
                                icon: "hand.thumbsup.fill", size: .small)
                }
            }
        }
    }

    private func chip(label: String, icon: String? = nil, isSelected: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon).font(.caption2.weight(.semibold))
                }
                Text(label).font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xs)
            .background(isSelected ? Color.lmsAccent : Color.lmsFill, in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func documentSheet(_ doc: GeneratedDocument) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Image(systemName: doc.category.icon)
                        .font(.system(size: 64))
                        .foregroundStyle(Color.lmsAccent)
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .background(Color.lmsTertiarySurface,
                                    in: RoundedRectangle(cornerRadius: CornerRadius.card))

                    Text(doc.title).font(.lmsTitle3)

                    VStack(spacing: 0) {
                        DetailRow(icon: "folder.fill", title: "Category",
                                  value: doc.category.rawValue)
                        DetailRow(icon: "internaldrive.fill", title: "Size",
                                  value: doc.fileSize)
                        DetailRow(icon: "calendar", title: "Generated",
                                  value: OfficerFormat.date(doc.generatedDate))
                        DetailRow(icon: "checkmark.seal.fill", title: "Signed",
                                  value: doc.isSigned ? "Yes" : "No",
                                  valueColor: doc.isSigned ? .lmsSuccess : .secondary)
                        DetailRow(icon: "hand.thumbsup.fill", title: "Acknowledged",
                                  value: doc.borrowerAcknowledged ? "Yes" : "No",
                                  valueColor: doc.borrowerAcknowledged ? .lmsSuccess : .secondary)
                    }
                    .padding(Spacing.m)
                    .background(Color.lmsSurface,
                                in: RoundedRectangle(cornerRadius: CornerRadius.card))

                    PrimaryButton(doc.isSigned ? "Share" : "Sign Document") {
                        selectedDocument = nil
                    }
                }
                .padding(Spacing.m)
            }
            .background(Color.lmsBackground)
            .navigationTitle("Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { selectedDocument = nil }
                }
            }
        }
    }
}
