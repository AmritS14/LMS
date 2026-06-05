# Shared DesignSystem Accessibility Improvements

## Overview
This document outlines the design for adding comprehensive standard accessibility features (VoiceOver and Dynamic Type) to the `Shared/DesignSystem` components in the LMS project. Because these components are used across both `BorrowerApp` and `StaffApp`, this sub-project provides foundational accessibility improvements to the entire ecosystem.

## Goals
- Provide a smooth and logical VoiceOver experience by combining scattered text elements into single, cohesive accessibility statements.
- Ensure layouts remain robust and text remains readable when users increase the system text size via Dynamic Type.
- Identify interactive UI elements explicitly for screen readers.

## Scope
This phase focuses exclusively on the ~12 reusable components located in the `Shared/DesignSystem/` directory:
- Typography, Spacing, Colors
- DetailRow, SectionCard, SectionHeader
- PrimaryButton, AvatarView
- StatusBadge, CountBadge
- EmptyStateView, LMSTextFieldStyle

## Implementation Approach
We will use the **Native Refactor Approach**, directly applying idiomatic SwiftUI modifiers to the existing components rather than building wrappers or enforcing rigid protocols.

### 1. VoiceOver Semantic Grouping
- **DetailRow**: Apply `.accessibilityElement(children: .combine)` so it reads as a single sentence (e.g., "Status, Approved"). Icons will be marked with `.accessibilityHidden(true)`.
- **Badges (`StatusBadge`, `CountBadge`)**: Provide contextual `.accessibilityLabel` modifiers to give raw data (like "3") actual meaning (like "3 unread messages").
- **AvatarView**: Hide purely visual elements (like user initials) from screen readers and provide a standard `.accessibilityLabel` like "Profile picture".

### 2. Layout Robustness & Interactive Traits
- **Layout Wrapping**: Ensure text inside structures like `DetailRow` or `EmptyStateView` can wrap securely to multiple lines without awkward truncation ("...") when scaled up heavily.
- **Button Traits**: Add `.accessibilityAddTraits(.isButton)` to `PrimaryButton` and other tappable areas so VoiceOver identifies them as interactive.
- **Form Inputs (`LMSTextFieldStyle`)**: Use `.accessibilityValue` to track current text and `.accessibilityLabel` to name the input field, ensuring screen reader users can navigate forms efficiently.

## Testing Strategy
- Use Xcode's Accessibility Inspector to verify VoiceOver outputs without running a physical device.
- Override Dynamic Type size in Xcode Previews to `.accessibility3` or `.accessibilityExtraExtraExtraLarge` to visually verify layout wrapping logic.
