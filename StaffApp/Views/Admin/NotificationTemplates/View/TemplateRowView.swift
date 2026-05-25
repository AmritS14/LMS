//
//  TemplateRowView.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI

// MARK: - Reusable Template Row Component

/// A reusable row displaying a notification template's title,
/// trigger event, and a body preview snippet.
struct TemplateRowView: View {
    let template: NotificationTemplate
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Trigger event icon
            triggerIcon

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                Text(template.triggerEvent.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(template.bodyText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    // MARK: - Subviews

    /// Icon representing the trigger event with associated color.
    private var triggerIcon: some View {
        let color = triggerColor
        return Image(systemName: template.triggerEvent.systemImage)
            .font(.title3)
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    /// Resolves the tint color string from the model to a SwiftUI Color.
    private var triggerColor: Color {
        switch template.triggerEvent.tintColor {
        case "green": .green
        case "red": .red
        case "orange": .orange
        default: .accentColor
        }
    }
}

#Preview {
    List {
        TemplateRowView(
            template: NotificationTemplate.sampleTemplates[0],
            isSelected: false
        )
        TemplateRowView(
            template: NotificationTemplate.sampleTemplates[4],
            isSelected: true
        )
    }
    .listStyle(.insetGrouped)
}
