import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 68, height: 68)
                .background(Color.lmsTertiarySurface, in: Circle())
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.lmsTitle3)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.lmsSubheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .padding(.horizontal, Spacing.l)
        .accessibilityElement(children: .combine)
    }
}