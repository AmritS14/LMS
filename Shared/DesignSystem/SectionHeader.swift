import SwiftUI

// Title + optional subtitle, with an optional trailing action button.
// Use above lists or cards when a List section header isn't appropriate.
struct SectionHeader: View {
    private let title: String
    private let subtitle: String?
    private let icon: String?
    private let actionTitle: String?
    private let action: (() -> Void)?

    init(title: String,
         subtitle: String? = nil,
         icon: String? = nil,
         actionTitle: String? = nil,
         action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            if let icon {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.lmsAccent)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.lmsHeadline)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.lmsFootnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.lmsAccent)
            }
        }
    }
}
