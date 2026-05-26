import SwiftUI

// Small numeric badge used for unread counts, etc. Hidden when count is zero.
struct CountBadge: View {
    private let count: Int
    private let tint: Color

    init(count: Int, tint: Color = .lmsDanger) {
        self.count = count
        self.tint = tint
    }

    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .frame(minWidth: 18, minHeight: 18)
                .background(tint, in: Capsule())
        }
    }
}

// Circular progress ring used in dashboard metrics.
struct CircularProgress: View {
    private let progress: Double
    private let color: Color
    private let lineWidth: CGFloat
    private let size: CGFloat

    init(progress: Double,
         color: Color = .lmsAccent,
         lineWidth: CGFloat = 8,
         size: CGFloat = 72) {
        self.progress = max(0, min(1, progress))
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}
