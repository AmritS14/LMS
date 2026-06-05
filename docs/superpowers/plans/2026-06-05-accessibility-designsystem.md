# Shared DesignSystem Accessibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement comprehensive VoiceOver and Dynamic Type improvements to the ~12 core UI components in `Shared/DesignSystem`.

**Architecture:** We will use native SwiftUI modifiers (`.accessibilityElement(children: .combine)`, `.accessibilityHidden()`, `.accessibilityLabel()`) directly on the component views to provide standard accessibility behaviors without adding complex wrappers or protocols.

**Tech Stack:** Swift, SwiftUI

---

### Task 1: DetailRow Accessibility

**Files:**
- Modify: `Shared/DesignSystem/DetailRow.swift`

- [ ] **Step 1: Write the failing test**

*(We skip unit tests here because SwiftUI accessibility is inherently visual/OS-level and UI tests are out of scope for this pass, but we verify via Xcode previews / inspector).*

- [ ] **Step 2: Write minimal implementation**

Modify `DetailRow` body to combine children and hide decorative icons. Also ensure text can wrap vertically.

```swift
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(iconTint)
                .frame(width: 28, height: 28)
                .background(iconTint.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                .accessibilityHidden(true)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
```

- [ ] **Step 3: Commit**

```bash
git commit -am "feat: improve VoiceOver and dynamic type wrapping in DetailRow"
```

### Task 2: Badges Accessibility

**Files:**
- Modify: `Shared/DesignSystem/StatusBadge.swift`
- Modify: `Shared/DesignSystem/CountBadge.swift`

- [ ] **Step 1: Write minimal implementation for StatusBadge**

Modify `StatusBadge.swift` to combine the icon and text into a single VoiceOver read.

```swift
    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(iconFont)
            }
            Text(text)
                .font(textFont)
        }
        .padding(.horizontal, size == .small ? Spacing.s : Spacing.sm)
        .padding(.vertical, size == .small ? Spacing.xxs : Spacing.xs)
        .background(background, in: Capsule())
        .foregroundStyle(foreground)
        .accessibilityElement(children: .combine)
    }
```

- [ ] **Step 2: Write minimal implementation for CountBadge & CircularProgress**

Modify `CountBadge.swift` to provide context for the numeric badges.

```swift
// CountBadge
    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .frame(minWidth: 18, minHeight: 18)
                .background(tint, in: Capsule())
                .accessibilityLabel("\(count) items")
        }
    }
```

```swift
// CircularProgress (inside CountBadge.swift)
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress \(Int(progress * 100)) percent")
```

- [ ] **Step 3: Commit**

```bash
git commit -am "feat: add accessibility traits to StatusBadge and CountBadge"
```

### Task 3: AvatarView Accessibility

**Files:**
- Modify: `Shared/DesignSystem/AvatarView.swift`

- [ ] **Step 1: Write minimal implementation**

Hide the initials text from VoiceOver and set a top-level accessibility label that includes the online status.

```swift
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(
                    LinearGradient(colors: colors,
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .frame(width: size, height: size)
                .overlay(
                    Text(initials)
                        .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                )

            if showOnlineIndicator {
                Circle()
                    .fill(isOnline ? Color.lmsSuccess : Color.lmsGray4)
                    .frame(width: size * 0.28, height: size * 0.28)
                    .overlay(
                        Circle().stroke(Color.lmsSurface, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isOnline ? "Profile picture, online" : "Profile picture")
    }
```

- [ ] **Step 2: Commit**

```bash
git commit -am "feat: add accessibility labels to AvatarView"
```

### Task 4: Button States & Empty States

**Files:**
- Modify: `Shared/DesignSystem/PrimaryButton.swift`
- Modify: `Shared/DesignSystem/EmptyStateView.swift`

- [ ] **Step 1: Write minimal implementation for Buttons**

Update `PrimaryButton` so VoiceOver announces the loading state correctly, since the `Text` is invisible when loading.

```swift
    var body: some View {
        Button(role: role, action: action) {
            ZStack {
                Text(title)
                    .font(.headline)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(.white)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 28)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: CornerRadius.button))
        .controlSize(.large)
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "Loading" : title)
    }
```

- [ ] **Step 2: Write minimal implementation for EmptyStateView**

Group the image, title, and subtitle into a single VoiceOver read in `EmptyStateView`.

```swift
    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 68, height: 68)
                .background(Color.lmsTertiarySurface, in: Circle())
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.lmsTitle3)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.lmsSubheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .padding(.horizontal, Spacing.l)
        .accessibilityElement(children: .combine)
    }
```

- [ ] **Step 3: Commit**

```bash
git commit -am "feat: enhance VoiceOver for buttons and empty states"
```
