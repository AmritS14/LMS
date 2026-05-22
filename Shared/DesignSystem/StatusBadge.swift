import SwiftUI

// Pill-shaped status indicator, sized for inline use next to titles.
struct StatusBadge: View {
    enum Tone { case neutral, info, success, warning, danger }

    private let text: String
    private let tone: Tone

    init(_ text: String, tone: Tone = .neutral) {
        self.text = text
        self.tone = tone
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xs)
            .background(background, in: Capsule())
            .foregroundStyle(foreground)
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
