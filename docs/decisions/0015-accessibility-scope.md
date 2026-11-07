# 0015. Accessibility scope by release

- **Date:** 2026-11-07
- **Status:** Accepted

## Maintainer input

> **Maintainer:** Accessibility is great, research best practices around our release cycle and around accessibility options. Provide a decision matrix for me to make calls on and feed back to understand the cost benefit of implementation.

> **Maintainer:** I approve A1-10 at the proposed version numbers.

## Context

The App Store Accessibility Nutrition Labels cover nine features: VoiceOver, Voice Control, Larger Text, Dark Interface, Differentiate Without Color Alone, Sufficient Contrast, Reduced Motion, Captions and Audio Descriptions. Apple recommends evaluating VoiceOver first, since that work carries over to other assistive technologies. `XCUIApplication.performAccessibilityAudit(for:_:)` audits a screen in a UI test and runs from `xcodebuild test`.

## Decision

| ID | Item | Target |
|---|---|---|
| A1 | VoiceOver labels, values, traits, grouping and announcements | v0 |
| A2 | Larger Text: text styles throughout, stacked layouts at accessibility sizes | v0 |
| A3 | Color tokens with high-contrast variants; contrast-ratio test in `WishfullyCore` (4.5:1 text, 3:1 controls) | v0 |
| A4 | Dark appearance for every token | v0 |
| A5 | State shown by icon and text in addition to color | v0 |
| A6 | Reduce Motion replaces celebrations and transitions with fades | v0 |
| A7 | Voice Control input labels for icon buttons | v1 |
| A8 | Accessibility audit UI tests per screen on macOS CI, light and dark | v0 |
| A9 | Snapshot images at the largest text size and in dark mode | v0 |
| A10 | App Store Accessibility Nutrition Labels and an accessibility page | v1 |

Captions and Audio Descriptions apply to video and audio; the app contains text and images.

## Consequences

- The design system slice builds A1 to A6 into its tokens and components.
- Every slice that adds a screen adds its audit test and snapshots.
- Every TestFlight build gets one maintainer pass of the common tasks with VoiceOver on and one at the largest text size.
- A10 declares a label only after every common task passes with that feature on.
