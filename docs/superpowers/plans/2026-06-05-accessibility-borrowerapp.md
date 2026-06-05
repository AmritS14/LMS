# BorrowerApp Accessibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement structural VoiceOver and Dynamic Type accessibility features across the 19 BorrowerApp view files.

**Architecture:** Use native SwiftUI modifiers (`.accessibilityAddTraits(.isHeader)`, `.accessibilityElement(children: .combine)`) directly within the view declarations.

**Tech Stack:** Swift, SwiftUI

---

### Task 1: Authentication Views Accessibility

**Files:**
- Modify: `BorrowerApp/Views/LoginView.swift`
- Modify: `BorrowerApp/Views/RegisterView.swift`
- Modify: `BorrowerApp/Views/ForgotPasswordView.swift`
- Modify: `BorrowerApp/Views/UpdatePasswordView.swift`

- [ ] **Step 1: Apply Headers and Labels**

For each file listed above, locate the main screen title (e.g., `Text("Login")`) and add the header trait. Locate any custom inputs and ensure they have accessibility labels.

```swift
// Pattern to apply to screen titles:
Text("Screen Title")
    .font(.lmsLargeTitle)
    .accessibilityAddTraits(.isHeader)

// Pattern to apply to custom buttons/toggles not using standard components:
Image(systemName: "eye.slash")
    .accessibilityLabel("Toggle password visibility")
    .accessibilityAddTraits(.isButton)
```

- [ ] **Step 2: Commit**

```bash
git commit -am "feat: add accessibility headers and labels to Auth views"
```

### Task 2: Loan Application & KYC Views

**Files:**
- Modify: `BorrowerApp/Views/AadhaarKYCView.swift`
- Modify: `BorrowerApp/Views/KYCView.swift`
- Modify: `BorrowerApp/Views/NewLoanApplicationView.swift`
- Modify: `BorrowerApp/Views/UploadRequestedDocumentsView.swift`

- [ ] **Step 1: Apply Headers and Form Grouping**

For each file listed above, apply the header trait to titles. Ensure form sections and instruction text do not have hardcoded `.frame(height:)` preventing Dynamic Type wrapping. Use `fixedSize` to allow vertical expansion.

```swift
// Pattern to apply for instruction text wrapping:
Text("Please upload your documents...")
    .fixedSize(horizontal: false, vertical: true)

// Pattern to apply for visual progress steps:
HStack {
    Circle().fill(.blue)
    Text("Step 1")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Step 1 of 3: KYC")
```

- [ ] **Step 2: Commit**

```bash
git commit -am "feat: add accessibility wrapping and grouping to Application views"
```

### Task 3: Dashboards & Tracking

**Files:**
- Modify: `BorrowerApp/Views/HomeDashboardView.swift`
- Modify: `BorrowerApp/Views/BorrowerProfileView.swift`
- Modify: `BorrowerApp/Views/ApplicationTrackingView.swift`
- Modify: `BorrowerApp/Views/RepaymentDashboardView.swift`

- [ ] **Step 1: Apply Timeline and Dashboard Summarization**

For each file, add `.accessibilityAddTraits(.isHeader)` to dashboard section headers (like "Active Loans"). Group visual charts or timelines using `.combine`.

```swift
// Pattern for ApplicationTrackingView timeline entries:
VStack {
    Text("Under Review")
    Text("We are reviewing your application.")
}
.accessibilityElement(children: .combine)

// Pattern for decorative dashboard background elements:
RoundedRectangle(cornerRadius: 12)
    .fill(Color.gray)
    .accessibilityHidden(true)
```

- [ ] **Step 2: Commit**

```bash
git commit -am "feat: add accessibility summaries to Dashboards and Tracking views"
```

### Task 4: Utilities & Misc

**Files:**
- Modify: `BorrowerApp/Views/EMICalculatorView.swift`
- Modify: `BorrowerApp/Views/LoanAssistantView.swift`
- Modify: `BorrowerApp/Views/BorrowerMessagingView.swift`
- Modify: `BorrowerApp/Views/ProductComparisonView.swift`
- Modify: `BorrowerApp/Views/NotificationsView.swift`
- Modify: `BorrowerApp/Views/SanctionLetterView.swift`
- Modify: `BorrowerApp/Views/RazorpayCheckoutView.swift`

- [ ] **Step 1: Apply Headers and Interactive Traits**

Apply header traits to titles in these utility views. Ensure the EMICalculator sliders have accessibility values, and message bubbles group sender name and message text.

```swift
// Pattern for Chat Bubbles in MessagingView:
VStack {
    Text("Agent")
    Text("Hello, how can I help?")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Agent says: Hello, how can I help?")

// Pattern for EMICalculator slider values:
Slider(value: $amount, in: 0...100)
    .accessibilityValue("\(Int(amount)) rupees")
```

- [ ] **Step 2: Commit**

```bash
git commit -am "feat: add accessibility traits to Utility and Misc views"
```
