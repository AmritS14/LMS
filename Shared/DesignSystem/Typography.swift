import SwiftUI

// All tokens use system text styles so Dynamic Type continues to work
// across the app, per HIG ("Use built-in text styles whenever possible").
extension Font {
    static let lmsLargeTitle: Font  = .largeTitle.weight(.bold)
    static let lmsTitle: Font       = .title.weight(.semibold)
    static let lmsTitle2: Font      = .title2.weight(.semibold)
    static let lmsTitle3: Font      = .title3.weight(.semibold)
    static let lmsHeadline: Font    = .headline
    static let lmsBody: Font        = .body
    static let lmsCallout: Font     = .callout
    static let lmsSubheadline: Font = .subheadline
    static let lmsFootnote: Font    = .footnote
    static let lmsCaption: Font     = .caption
    static let lmsCaption2: Font    = .caption2
    static let lmsMono: Font        = .subheadline.monospacedDigit()
    static let lmsMonoTimer: Font   = .title3.monospacedDigit().weight(.semibold)
    static let lmsHeroAmount: Font  = .system(.largeTitle, design: .rounded).weight(.bold)
    static let lmsHeroIcon: Font    = .system(size: 48)

    // MARK: - Admin-specific Design Tokens
    static let adminLargeTitle: Font  = .largeTitle.weight(.bold)
    static let adminScreenTitle: Font = .title2.weight(.bold)
    static let adminSectionHeader: Font = .footnote.weight(.semibold)
    static let adminCardTitle: Font   = .subheadline.weight(.semibold)
    static let adminBody: Font        = .body
    static let adminSecondary: Font   = .subheadline
    static let adminCaption: Font     = .caption
    static let adminStatus: Font      = .footnote.weight(.semibold)
    static let adminButton: Font      = .headline.weight(.bold)
    static let adminFormLabel: Font   = .subheadline.weight(.semibold)
    static let adminFormInput: Font   = .body
}
