# ADR-0042: Players as an in-list accordion section in the encounter runner

**Status:** Accepted
**Date:** 2026-05-02

## Context

This supersedes [ADR-0022](0022-encounter-runner-ux.md).

ADR-0022 specified a PlayerStrip pinned to the bottom of the runner screen via
`.safeAreaInset(edge: .bottom)`. Tapping a player row was to open a PlayerEditPopover
via `.sheet`. Two problems emerged during implementation:

1. **iOS 26 sheet suppression.** `.sheet` presented from within a `fullScreenCover`'s
   `NavigationStack` is silently ignored on iOS 26. A ZStack overlay workaround was
   applied to `EncounterRunnerContainer` to work around this, but it required threading
   an `editingPlayer: @Binding` through the view hierarchy and rendering the card as a
   ZStack sibling above the NavigationStack — the wrong direction for SwiftUI data flow.

2. **UX inconsistency with adversaries (issue #89).** Players were represented in a
   separate region below the list while adversaries used an accordion section inside the
   list. GMs found the separation disorienting.

## Decision

Drop the PlayerStrip. Players appear as a `ForEach` section directly inside the runner
`List`, using the same accordion expand/collapse pattern as adversaries:

- Collapsed state: compact two-row display (name, condition icons, stress pips / HP
  pips, armor pips) — mirrors `AdversaryRunnerRow` layout.
- Expanded state: inline card with ±HP, ±Stress, ±Armor steppers and condition toggles
  — mirrors `AdversaryRunnerCard` layout.

A single `expandedItemID: UUID?` in `EncounterRunnerView` is shared across both the
adversary and player sections. Because adversary and player slot IDs are both `UUID`
values from independent ID spaces that do not collide, binding both sections to the same
state variable enforces the "at most one card open at a time" invariant without any
coordination logic.

`EncounterRunnerContainer` simplifies back to a plain `NavigationStack` wrapper. No
ZStack, no overlay, no `editingPlayer` state.

## Options Considered

- **Keep PlayerStrip with ZStack overlay (rejected).** The overlay approach works around
  the iOS 26 presentation issue but the data-flow direction is wrong and the container
  is more complex than the feature warrants.
- **Use `.popover` instead of `.sheet` (rejected).** `.popover` uses a different UIKit
  presentation path and avoids the fullScreenCover suppression on iPad, but behaves as a
  full-screen sheet on iPhone — the same problem on the primary device target.
- **Keep PlayerStrip, fix sheet with UIViewControllerRepresentable shim (rejected).**
  Violates ADR-0001 (SwiftUI only).

## Consequences

- `PlayerStrip.swift`, `PlayerStripRow.swift`, and `PlayerEditPopover.swift` are deleted.
- New components: `PlayerRunnerSection`, `PlayerRunnerRow`, `PlayerRunnerCard`,
  `PlayerStatRow`.
- `PlayerConditionsSection` is reused unchanged inside `PlayerRunnerCard`.
- The "always visible regardless of scroll position" property of the old strip is lost.
  Players are accessible by scrolling to the player section. Given Daggerheart has no
  individual player turns (ADR-0021), this is acceptable — the GM does not need to
  update player state continuously, only when a player is targeted.
- A future visual affordance to distinguish the adversary and player sections within the
  same list (e.g. background tint, section label) is deferred; the two `ForEach` groups
  are currently visually undifferentiated.
