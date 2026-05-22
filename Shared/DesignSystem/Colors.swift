import SwiftUI

extension Color {
    // Primary (#0A2A66)
    static let lmsPrimary = Color(red: 10/255, green: 42/255, blue: 102/255)
    static let lmsAccent = lmsPrimary
    static let lmsNavyBlue = lmsPrimary

    // Semantic
    static let lmsSuccess = Color(red: 52/255, green: 199/255, blue: 89/255)    // #34C759
    static let lmsWarning = Color(red: 255/255, green: 181/255, blue: 71/255)   // #FFB547
    static let lmsDanger = Color(red: 255/255, green: 107/255, blue: 107/255)   // #FF6B6B

    // Backgrounds
    static let lmsSurface = Color(red: 250/255, green: 250/255, blue: 247/255)  // #FAFAF7
    static let lmsCardBackground = Color.white

    // Text
    static let lmsText = Color(red: 17/255, green: 17/255, blue: 17/255)        // #111111
    static let lmsSecondaryText = Color(red: 122/255, green: 122/255, blue: 122/255) // #7A7A7A
}
