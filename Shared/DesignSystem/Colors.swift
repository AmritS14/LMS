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
    static let lmsNavyBlue = Color("NavyBlue")

    #if canImport(UIKit)
    static let lmsSurface = Color(uiColor: .systemBackground)
    #else
    static let lmsSurface = Color.white
    #endif
}
