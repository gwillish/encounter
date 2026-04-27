# UI Development Issues — XCUITest / iOS 26 Debugging Log

This document records the specific failures and dead ends encountered across two sessions
(PR #94 — PlayerStrip tap / `testPlayerConditionToggleShowsAndHidesInStripRow`) so
future work doesn't repeat the same cycles.

---

## Problem Statement

`testPlayerConditionToggleShowsAndHidesInStripRow` needed a player row button in the
always-visible `PlayerStrip` (bottom of `EncounterRunnerView`) to be tappable by
XCUITest, triggering `editingPlayer = player` and presenting `PlayerEditPopover`.

After two full context sessions (~40+ iterations, ~60 s per run), the button action
*never fired*. The sheet never appeared. The underlying root cause was not definitively
established.

---

## Confirmed Observations

| Fact | Source |
|---|---|
| `playerRow.isHittable == true` | XCUITest property — AX tree sees no occlusion |
| `playerRow.tap()` does not fire button action | `runner.editing-player-debug` AX label stays `"none"` |
| Coordinate tap at button's center `(201, 771)` also fails | Diagnostic write to `/tmp/tap_diagnostic.txt` |
| Adversary row buttons **inside** the List work correctly | Multiple passing tests |
| AX tree shows `CollectionView` (List) frame as `{{0,0},{402,751}}` | `app.debugDescription` dumps |
| AX tree shows a full-screen `Other {{0,0},{402,874}}` sibling at **higher z-order** than the VStack container | All AX dumps |
| The full-screen sibling is **not interactive** in the AX tree (no buttons/sliders inside) | AX dumps — explains `isHittable=true` |
| The full-screen sibling persists regardless of which SwiftUI modifiers are present | Survived `.sheet` + `.confirmationDialog` relocation |

---

## Things Tried — What Did Not Work

### Layout Changes

| Change | Hypothesis | Outcome |
|---|---|---|
| `.safeAreaInset(edge: .bottom)` on List | PlayerStrip placed below list | UICollectionView's full-screen UIKit frame intercepts all touches; documented in code comment |
| `.overlay(alignment: .bottom)` on List | Higher z-order than list | Same UICollectionView interception |
| VStack sibling (List above, PlayerStrip below) | UICollectionView limited to 751 pt | Still fails — full-screen sibling in AX tree above VStack container |

### SwiftUI Modifier Changes

| Change | Hypothesis | Outcome |
|---|---|---|
| Added `.contentShape(Rectangle())` to PlayerStripRow | Spacer gaps not hittable | No effect on tap delivery |
| Changed `.background(.regularMaterial)` → `.background { Rectangle().fill(.regularMaterial).allowsHitTesting(false) }` | UIVisualEffectView intercepting touches | No effect |
| Moved `.sheet(item:)` + `.confirmationDialog` from outer VStack to 0×0 `Color.clear` anchor view | UIKit presenter stubs creating full-screen overlay | Full-screen sibling still present; taps still fail |

### Diagnostics Added (still in source — must be removed)

- `Color.clear.frame(width: 0, height: 0)` debug element `runner.editing-player-debug` in `EncounterRunnerView` — exposes `editingPlayer?.name` as AX label
- `Thread.sleep`, coordinate-tap fallback, multi-point tap loop in `RunnerUITests.swift`
- AX tree dump to `/tmp/ax_after_tap.txt` and `/tmp/tap_diagnostic.txt`

These must be reverted before PR #94 is merged.

---

## Root-Cause Hypothesis (Unresolved)

The AX tree consistently shows this structure inside `EncounterRunnerView`:

```
Other {{0,0},{402,874}}          ← SwiftUI nav content area
  Other {{0,0},{402,874}}
    Other {{0,0},{402,874}}
      Other {{0,0},{402,874}}    ← VStack container (holds CollectionView + player-row)
        CollectionView {{0,0},{402,751}}  runner.adversary-list
        Button {{16,757},{370,28}}        runner.player-row   ← target
      Other {{0,0},{402,874}}    ← PHANTOM: higher z-order, full-screen, NOT interactive in AX
        Other {{0,0},{402,874}}
```

The **phantom full-screen sibling** (`isUserInteractionEnabled = true` in UIKit,
`isAccessibilityElement = false`) intercepts all HID touch events at y ≈ 771 before
the button's gesture recognizer is reached. XCUITest's `isHittable` does not detect it
because `isHittable` queries the AX tree (where the element is invisible), not UIKit's
hit-test chain.

**Leading candidates for the phantom view:**

1. **SwiftUI's NavigationStack navigation-gesture capture view** — iOS 26 adds a
   full-screen UIView to handle back-swipe and navigation transitions; this view
   persists after the push animation completes.
2. **EncounterBuilderView's `.sheet(isPresented: $showCompendium)` presenter stub** —
   attached at the NavigationController level, persisting into pushed destinations.
3. **UICollectionView UIKit frame mismatch** — AX reports 751 pt (SwiftUI layout),
   but the actual UIKit view `bounds` might be 874 pt; `pointInside` on UIScrollView
   would then return true for y = 771.

None of these were verified or falsified within the available context budget.

---

## Cost of the XCUITest Loop

Each diagnostic iteration required:
- Editing source code
- Building the app (~20–30 s incremental, ~60 s clean)
- Booting the iOS simulator (~30 s if cold)
- Running `navigateToRunner()` setup (~30 s of UI interactions)
- Waiting for the test to time out or fail (~5–15 s)

**Total per iteration: ~60–90 seconds.** With 40+ iterations across two sessions, this
consumed ~60–90 minutes of wall-clock time just in test execution, plus the entire
context budget of two AI sessions.

### Why XCUITest is a Poor Fit for This Class of Bug

- XCUITest operates at the AX layer; it cannot inspect UIKit `isUserInteractionEnabled`,
  `bounds`, or `frame` of arbitrary UIKit views.
- Every hypothesis requires a full build+simulator+navigation cycle to test.
- Touch delivery in SwiftUI+UIKit hybrid views on iOS 26 involves multiple undocumented
  layers (NavigationStack infrastructure, UICollectionView, SwiftUI gesture proxies).
- XCUITest gives no signal distinguishing "touch intercepted by phantom UIKit view"
  from "touch reached button but action failed" — both look identical from the outside.

---

## What Would Have Helped

1. **A UIKit introspection tool** (e.g., FLEX, Chisel, or a custom UIViewRepresentable
   that walks the UIKit tree) to inspect `isUserInteractionEnabled`, `bounds`, and `frame`
   of all views at coordinate (201, 771) at runtime.
2. **ViewInspector unit tests** that verify `editingPlayer` binding state changes in
   response to button taps — runnable in milliseconds without a simulator, catching
   state-layer bugs independently of UIKit hit testing.
3. **A simpler reproduction case** — a minimal SwiftUI playground or preview isolating
   PlayerStrip + tap behavior, without the full navigation stack.

---

## Files Modified During This Debug Session (needs cleanup)

| File | Change | Status |
|---|---|---|
| `Encounter/Views/EncounterRunnerView.swift` | Moved `.sheet`/`.confirmationDialog` to anchor view; added debug `Color.clear` element; changed layout from safeAreaInset → overlay → VStack | Needs final decision + comment cleanup |
| `Encounter/Views/PlayerStrip.swift` | `.background(.regularMaterial)` → `.background { Rectangle().fill(.regularMaterial).allowsHitTesting(false) }` | May or may not be the right call |
| `Encounter/Views/PlayerStripRow.swift` | Added `.contentShape(Rectangle())` | Correct, keep |
| `EncounterUITests/RunnerUITests.swift` | Diagnostic `Thread.sleep`, coordinate taps, AX dump, `isHittable` check | Must be reverted / simplified |

---

## Recommended Path Forward (Issue #95)

Use **ViewInspector** for SwiftUI unit tests to validate:
- `PlayerStripRow` button sets `editingPlayer` binding when tapped
- Condition icons appear/disappear in the row label based on `PlayerState.conditions`
- `AdversaryRunnerRow` label reflects condition badges

Use **XCUITest** only for end-to-end flows that require real navigation (runner
setup, session reset, fear tracking), not for individual view state transitions.

See the companion plan document for the ViewInspector integration approach.
