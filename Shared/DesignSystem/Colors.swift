import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// Semantic color tokens that map to iOS system colors so the app
// automatically adapts to Light/Dark Mode and accessibility settings.
extension Color {
    // Brand / tint — defer to the asset-catalog AccentColor so the
    // user's chosen tint flows through every standard control.
    static let lmsPrimary = Color.accentColor
    static let lmsAccent  = Color.accentColor

    // Semantic status colors map to system equivalents (auto dark-mode).
    #if canImport(UIKit)
    static let lmsDanger  = Color(uiColor: .systemRed)
    static let lmsSuccess = Color(uiColor: .systemGreen)
    static let lmsWarning = Color(uiColor: .systemOrange)
    static let lmsInfo    = Color(uiColor: .systemBlue)

    static let lmsSurface       = Color(uiColor: .secondarySystemGroupedBackground)
    static let lmsBackground    = Color(uiColor: .systemGroupedBackground)
    static let lmsTertiarySurface = Color(uiColor: .tertiarySystemGroupedBackground)
    static let lmsFill          = Color(uiColor: .systemFill)
    static let lmsSecondaryFill = Color(uiColor: .secondarySystemFill)
    static let lmsTertiaryFill  = Color(uiColor: .tertiarySystemFill)
    static let lmsSeparator     = Color(uiColor: .separator)
    static let lmsGray4         = Color(uiColor: .systemGray4)
    static let lmsGray5         = Color(uiColor: .systemGray5)
    #else
    static let lmsDanger  = Color.red
    static let lmsSuccess = Color.green
    static let lmsWarning = Color.orange
    static let lmsInfo    = Color.blue

    static let lmsSurface         = Color.white
    static let lmsBackground      = Color.gray.opacity(0.1)
    static let lmsTertiarySurface = Color.gray.opacity(0.08)
    static let lmsFill            = Color.gray.opacity(0.2)
    static let lmsSecondaryFill   = Color.gray.opacity(0.16)
    static let lmsTertiaryFill    = Color.gray.opacity(0.12)
    static let lmsSeparator       = Color.gray.opacity(0.3)
    static let lmsGray4           = Color.gray.opacity(0.3)
    static let lmsGray5           = Color.gray.opacity(0.2)
    #endif
}

extension LinearGradient {
    // Subtle vertical wash used behind hero headers. Stays within
    // semantic colors so it adapts to Dark Mode.
    static let lmsBackgroundGradient = LinearGradient(
        colors: [Color.lmsBackground, Color.lmsBackground],
        startPoint: .top,
        endPoint: .bottom
    )
}
