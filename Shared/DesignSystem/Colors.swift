import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    static let lmsPrimary = Color.accentColor
    static let lmsAccent = Color.blue
    static let lmsDanger = Color.red
    static let lmsSuccess = Color.green
    static let lmsWarning = Color.orange

    #if canImport(UIKit)
    static let lmsSurface = Color(uiColor: .secondarySystemGroupedBackground)
    static let lmsBackground = Color(uiColor: .systemGroupedBackground)
    static let lmsFill = Color(uiColor: .systemFill)
    static let lmsGray4 = Color(uiColor: .systemGray4)
    static let lmsGray5 = Color(uiColor: .systemGray5)
    #else
    static let lmsSurface = Color.white
    static let lmsBackground = Color.gray.opacity(0.1)
    static let lmsFill = Color.gray.opacity(0.2)
    static let lmsGray4 = Color.gray.opacity(0.3)
    static let lmsGray5 = Color.gray.opacity(0.2)
    #endif
}

extension LinearGradient {
    static let lmsBackgroundGradient = LinearGradient(
        colors: [Color.lmsBackground, Color.lmsBackground],
        startPoint: .top,
        endPoint: .bottom
    )
}
