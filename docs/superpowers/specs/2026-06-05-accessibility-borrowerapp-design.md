# BorrowerApp Accessibility Improvements

## Overview
This document outlines the design for adding comprehensive standard accessibility features (VoiceOver and Dynamic Type) to the `BorrowerApp` views in the LMS project. Since the `Shared/DesignSystem` components are already accessible, this phase focuses on screen-level layout, navigation semantic structures, and complex visual elements specific to the borrower experience.

## Goals
- Establish a semantic hierarchy by properly marking screen titles and section headers for VoiceOver navigation.
- Ensure forms and inputs seamlessly read their labels alongside their values.
- Translate complex visual layouts (like timelines or charts) into coherent text summaries for screen readers.
- Ensure dynamic type scaling does not break screen layouts due to rigid heights or constraints.

## Scope
This phase focuses exclusively on the 19 UI View files in the `BorrowerApp/Views/` directory, which covers core workflows such as:
- **Authentication**: `LoginView`, `RegisterView`, `ForgotPasswordView`, `UpdatePasswordView`
- **Application Flow**: `AadhaarKYCView`, `KYCView`, `NewLoanApplicationView`, `UploadRequestedDocumentsView`
- **Dashboards & Tracking**: `HomeDashboardView`, `BorrowerProfileView`, `ApplicationTrackingView`, `RepaymentDashboardView`
- **Utilities & Misc**: `EMICalculatorView`, `LoanAssistantView`, `BorrowerMessagingView`, `ProductComparisonView`, `NotificationsView`, `SanctionLetterView`, `RazorpayCheckoutView`

## Implementation Approach
We will perform a comprehensive screen-by-screen pass to add native SwiftUI modifiers directly to the view hierarchy.

### 1. Semantic Structure & Navigation
- **Headers**: Apply `.accessibilityAddTraits(.isHeader)` to text views representing main screen titles and major section dividers.
- **Buttons**: Explicitly add `.accessibilityAddTraits(.isButton)` to custom tappable rows or areas that do not use standard `Button` components.
- **Decorative Media**: Apply `.accessibilityHidden(true)` to background images, spacing shapes, or decorative icons that offer no semantic value.

### 2. Forms, Custom Layouts, & Data Visualization
- **Forms**: Use `.accessibilityLabel` to link instructions directly to input elements, ensuring `TextField`s announce their purpose clearly.
- **Data Summarization**: For complex components like timelines in `ApplicationTrackingView`, use `.accessibilityElement(children: .combine)` combined with `.accessibilityLabel("Application Status: [State]")` to replace fragmented visual reading with a direct summary.
- **Dynamic Type Protection**: Remove or refactor hardcoded `.frame(height: X)` modifiers on containers wrapping text elements. Use `.fixedSize(horizontal: false, vertical: true)` where necessary to permit text to expand vertically in standard ScrollViews.

## Testing Strategy
- Use Xcode's Accessibility Inspector to verify VoiceOver output structure across the major screen types without running a physical device.
- Utilize SwiftUI Previews with `DynamicTypeSize` overrides to visually confirm layout robustness under extreme text scaling scenarios.
