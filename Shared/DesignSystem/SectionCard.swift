import SwiftUI

// A card that visually matches an inset-grouped List section. Use sparingly
// — prefer Form / List with .insetGrouped when the content is form-like.
struct SectionCard<Content: View>: View {
    private let title: String?
    private let footer: String?
    private let content: Content

    init(title: String? = nil,
         footer: String? = nil,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if let title {
                Text(title.uppercased())
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.xs)
            }

            VStack(alignment: .leading, spacing: Spacing.m) {
                content
            }
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))

            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.xs)
            }
        }
    }
}
