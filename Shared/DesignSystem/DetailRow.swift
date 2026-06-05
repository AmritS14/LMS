import SwiftUI

// Label / value row used inside cards and forms. The icon is rendered in
// a rounded tinted square in front of the title so rows scan vertically.
struct DetailRow: View {
    private let icon: String
    private let title: String
    private let value: String
    private let valueColor: Color
    private let iconTint: Color

    init(icon: String,
         title: String,
         value: String,
         valueColor: Color = .primary,
         iconTint: Color = .lmsAccent) {
        self.icon = icon
        self.title = title
        self.value = value
        self.valueColor = valueColor
        self.iconTint = iconTint
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(iconTint)
                .frame(width: 28, height: 28)
                .background(iconTint.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                .accessibilityHidden(true)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}
