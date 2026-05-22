import SwiftUI

struct SectionCard<Content: View>: View {
    private let title: String?
    private let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            if let title {
                Text(title)
                    .font(.lmsTitle3)
                    .foregroundColor(.lmsText)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .background(Color.lmsCardBackground)
        .cornerRadius(CornerRadius.xlarge)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xlarge)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
    }
}
