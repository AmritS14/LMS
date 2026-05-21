import SwiftUI

// MARK: - Admin Local Color Theme (Supporting Light & Dark Mode)
struct AdminColor {
    static let background = Color(uiColor: UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return UIColor(hex: "#121214") // Dark purple-tinted slate
        } else {
            return UIColor(hex: "#E0DFE4") // Soft light lilac
        }
    })

    static let cardBackground = Color(uiColor: UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return UIColor(hex: "#1C1C1E") // Elevated gray card
        } else {
            return UIColor(hex: "#ECEBF0") // Premium light card
        }
    })

    static let accent = Color(hex: "#E24901")

    static let text = Color(uiColor: UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return UIColor(hex: "#F5F5F7")
        } else {
            return UIColor(hex: "#0F0E0D")
        }
    })

    static let secondaryText = Color(uiColor: UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return UIColor(hex: "#A19EB0")
        } else {
            return UIColor(hex: "#6E6986")
        }
    })

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, Color(hex: "#FFA238")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Admin Spacing & Layout Tokens (Pixel-Perfect iOS Native Spacing)
struct AdminSpacing {
    /// Spacing between elements within a card (8pt)
    static let cardContent: CGFloat = Spacing.s
    
    /// Padding around card views (16pt)
    static let cardPadding: CGFloat = Spacing.m
    
    /// Spacing between card rows in list/scroll layouts (8pt)
    static let cardGap: CGFloat = Spacing.s
    
    /// Gap between a header and the first card below it (8pt)
    static let headerToCardGap: CGFloat = Spacing.s
    
    /// Gap between separate sections (16pt)
    static let sectionGap: CGFloat = Spacing.m
    
    /// The top inset for list/form section headers (12pt)
    static let headerTopInset: CGFloat = 12
    
    /// The bottom inset for list/form section headers (4pt)
    static let headerBottomInset: CGFloat = Spacing.xs
    
    /// The top/bottom row insets for card lists (4pt)
    static let cardRowVerticalInset: CGFloat = Spacing.xs
    
    /// The leading/trailing row insets for card lists (16pt)
    static let cardRowHorizontalInset: CGFloat = Spacing.m
}

// MARK: - Admin Local Primary Button
struct AdminPrimaryButton: View {
    @Environment(\.isEnabled) private var isEnabled

    private let title: String
    private let isLoading: Bool
    private let action: () -> Void

    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }
                Text(title)
                    .font(.lmsHeadline)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(isEnabled ? AdminColor.accent : Color.gray.opacity(0.4))
            .clipShape(Capsule())
            .shadow(color: isEnabled ? AdminColor.accent.opacity(0.2) : Color.clear, radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Local Hex Color Helper
fileprivate extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

fileprivate extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
