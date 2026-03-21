# ADR-0001: SwiftUI only — no UIKit

**Status:** Accepted
**Date:** 2026-03-14

## Context

The app targets iOS, macOS, and visionOS from a single codebase. Choosing between
SwiftUI and UIKit (or a hybrid) affects how much platform-specific code is needed
and how maintainable the codebase is over time.

## Decision

Use SwiftUI exclusively. No UIKit imports anywhere in the app target. Platform
differences are handled with `#if os(iOS)` / `#if os(macOS)` conditional compilation
inside SwiftUI views.

## Options Considered

- **SwiftUI only (chosen):** Single declarative UI layer, works across all three
  target platforms, no bridging overhead.
- **UIKit + SwiftUI hybrid:** More escape hatches for complex custom controls, but
  requires `UIViewRepresentable` bridging, complicates the visionOS story, and
  splits the mental model.
- **UIKit only:** Maximum control, but visionOS support is painful and the tooling
  investment is not justified for this app's UI complexity.

## Consequences

- Views are `internal`; all UI stays in the SwiftUI layer.
- Platform-specific adaptations (navigation style, sheet sizing) use
  `#if os(iOS)` / `#if os(macOS)` guards inside SwiftUI view bodies.
- Any future requirement for a UIKit-only control must be wrapped in a
  `UIViewRepresentable` and justified as an exception, not a pattern.
