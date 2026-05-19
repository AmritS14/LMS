import SwiftUI

public struct StatusBadge: View {
    public enum Tone { case neutral, info, success, warning, danger }

    private let text: String
    private let tone: Tone

    public init(_ text: String, tone: Tone = .neutral) {
        self.text = text
        self.tone = tone
    }

    public var body: some View {
        Text(text)
            .font(.lmsCaption.weight(.semibold))
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xs)
            .background(background, in: Capsule())
            .foregroundStyle(foreground)
    }

    private var background: Color {
        switch tone {
        case .neutral: .gray.opacity(0.15)
        case .info: .lmsAccent.opacity(0.15)
        case .success: .lmsSuccess.opacity(0.15)
        case .warning: .lmsWarning.opacity(0.15)
        case .danger: .lmsDanger.opacity(0.15)
        }
    }

    private var foreground: Color {
        switch tone {
        case .neutral: .primary
        case .info: .lmsAccent
        case .success: .lmsSuccess
        case .warning: .lmsWarning
        case .danger: .lmsDanger
        }
    }
}
