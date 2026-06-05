import SwiftUI

// Pill-shaped status indicator. Tone drives the colour; an optional icon
// is rendered before the text when supplied.
struct StatusBadge: View {
    enum Tone { case neutral, info, success, warning, danger }
    enum Size { case small, medium }

    private let text: String
    private let tone: Tone
    private let icon: String?
    private let size: Size

    init(_ text: String,
         tone: Tone = .neutral,
         icon: String? = nil,
         size: Size = .medium) {
        self.text = text
        self.tone = tone
        self.icon = icon
        self.size = size
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(iconFont)
            }
            Text(text)
                .font(textFont)
        }
        .padding(.horizontal, size == .small ? Spacing.s : Spacing.sm)
        .padding(.vertical, size == .small ? Spacing.xxs : Spacing.xs)
        .background(background, in: Capsule())
        .foregroundStyle(foreground)
        .accessibilityElement(children: .combine)
    }

    private var textFont: Font {
        switch size {
        case .small: .caption.weight(.semibold)
        case .medium: .footnote.weight(.semibold)
        }
    }

    private var iconFont: Font {
        switch size {
        case .small: .caption2.weight(.semibold)
        case .medium: .caption.weight(.semibold)
        }
    }

    private var background: Color {
        switch tone {
        case .neutral: Color.lmsFill
        case .info:    Color.lmsInfo.opacity(0.15)
        case .success: Color.lmsSuccess.opacity(0.15)
        case .warning: Color.lmsWarning.opacity(0.15)
        case .danger:  Color.lmsDanger.opacity(0.15)
        }
    }

    private var foreground: Color {
        switch tone {
        case .neutral: .primary
        case .info:    .lmsInfo
        case .success: .lmsSuccess
        case .warning: .lmsWarning
        case .danger:  .lmsDanger
        }
    }
}
