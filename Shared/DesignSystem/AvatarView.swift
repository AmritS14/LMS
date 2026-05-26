import SwiftUI

// Round avatar showing initials over a gradient. Used in list rows and
// detail headers across the staff and borrower apps.
struct AvatarView: View {
    private let initials: String
    private let size: CGFloat
    private let colors: [Color]
    private let showOnlineIndicator: Bool
    private let isOnline: Bool

    init(initials: String,
         size: CGFloat = 44,
         colors: [Color] = [.lmsInfo, .lmsAccent],
         showOnlineIndicator: Bool = false,
         isOnline: Bool = false) {
        self.initials = initials
        self.size = size
        self.colors = colors
        self.showOnlineIndicator = showOnlineIndicator
        self.isOnline = isOnline
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(
                    LinearGradient(colors: colors,
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .frame(width: size, height: size)
                .overlay(
                    Text(initials)
                        .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                )

            if showOnlineIndicator {
                Circle()
                    .fill(isOnline ? Color.lmsSuccess : Color.lmsGray4)
                    .frame(width: size * 0.28, height: size * 0.28)
                    .overlay(
                        Circle().stroke(Color.lmsSurface, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }
        }
    }
}
