# UI Development Reference

This document covers testing strategy, ViewInspector patterns, XCUITest patterns, AX tree
debugging, and iOS 26 quirks for the Encounter app. Consult it when developing or debugging
SwiftUI views.

**Related:** [ADR-0041](decisions/0041-explicit-dependency-injection.md) (dependency injection),
[ui-vocabulary.md](ui-vocabulary.md) (screen names, component glossary).

---

## Testing Pyramid

The five-tier pyramid is defined in `CLAUDE.md`. Short form:

| Tier | Tool | Speed | Use for |
|---|---|---|---|
| 1 — Model | Swift Testing direct | ~0.1 ms | Model mutations, JSON decoding, persistence |
| 2 — View structure | ViewInspector (`EncounterTests`) | ~1 ms | Element presence, bindings, AX labels, conditional render |
| 3 — Snapshot | swift-snapshot-testing (`EncounterTests`, iOS Simulator) | ~50–100 ms | Visual regression — layout, colour, icon states as PNGs |
| 4 — Visual | Xcode MCP `RenderPreview` | on-demand | Layout, colour, icon review during agent sessions |
| 5 — End-to-end | XCUITest (`EncounterUITests`) | ~60 s | Full navigation flows, session lifecycle, real UIKit |

**Decision rule:** if the assertion is "given this model state, the view should have this
structure / label / binding behavior" → write a ViewInspector test. Add a snapshot test
when the visual output itself matters (colour gradients, icon rendering, layout). Only
reach for XCUITest when the full running app is required.

---

## Snapshot Testing

`pointfreeco/swift-snapshot-testing` 1.19.2 — Tier 3 visual regression tests.

### How it works

- Tests are in `EncounterTests/` and guarded `#if os(iOS)`.
- Reference PNGs live in `EncounterTests/__Snapshots__/<SuiteName>/`.
- First run records (test fails by design). Subsequent runs compare pixel-for-pixel.
- To regenerate: delete the PNG file and re-run.
- Run on iOS Simulator (`platform=iOS Simulator,name=iPhone 17 Pro`), not macOS.
  The macOS app sandbox blocks filesystem writes; the Simulator process does not.

### Why iOS Simulator only

macOS unit tests run inside `Encounter.app`'s sandboxed process. The app sandbox
blocks writes to the source tree, so `assertSnapshot` can't write `__Snapshots__/`.
iOS Simulator test processes run outside any app sandbox and CAN write to host
filesystem paths (the standard way snapshot libraries work on iOS).

### Running snapshot tests

```bash
# Record new snapshots (first run — will fail, that's expected)
xcodebuild test \
  -scheme Encounter \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:EncounterTests/TierBadgeViewSnapshotTests

# Verify comparison passes (second run)
xcodebuild test \
  -scheme Encounter \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:EncounterTests/TierBadgeViewSnapshotTests
```

### Parallel clone naming

xcodebuild runs Swift Testing suites in parallel using multiple simulator clones.
Each clone writes its own snapshot copy: `normal.1.png` (clone 1), `normal.2.png`
(clone 2). Both files are committed; both are used as references on subsequent runs.

### Adding a new snapshot test

1. Create `MySuiteSnapshotTests.swift` in `EncounterTests/`, wrapped in `#if os(iOS)`.
2. Import `SnapshotTesting` and call `assertSnapshot(of: myView, as: .image(layout: SnapshotLayout.row))`.
3. Run on iOS Simulator once to record; run again to verify.
4. Commit the PNG files in `__Snapshots__/` alongside the test file.

### Layout presets (`SnapshotHelpers.swift`)

```swift
SnapshotLayout.row    // 390 × 80 pt  — component row
SnapshotLayout.card   // 390 × 200 pt — card panel
SnapshotLayout.badge  // 200 × 44 pt  — small badge
```

### Current suites

| Suite | Components | States |
|---|---|---|
| `TierBadgeViewSnapshotTests` | `TierBadgeView` | below, above, matching tier |
| `PipTrackSnapshotTests` | `PipTrack` | HP full/half/critical, stress, armor, text fallback |
| `AdversaryRunnerRowSnapshotTests` | `AdversaryRunnerRow` | normal, damaged, high stress, conditions, solo, defeated, unknown |

---

## ViewInspector

ViewInspector v0.10.3 runs in the unit-test process (`EncounterTests`). All views are valid
targets because no view reads `@Environment` for a custom store (ADR-0041). Stores are
passed via `init`; `@Environment` is reserved for system values only (`\.dismiss`,
`\.scenePhase`).

### Quick Reference

```swift
import ViewInspector

// Swift 6 inserts an implicit AnyView around view body — unwrap it first
let sut = MyView(store: ..., compendium: ...)
let root = try sut.inspect().implicitAnyView()

// Navigate the tree
.button()                            // Button
.text()                              // Text
.hStack() / .vStack()               // HStack / VStack
.forEach()                           // ForEach; iterate with .view(i)
.find(ViewType.Button.self)          // deep search for first match
.findAll(ViewType.Text.self)         // all matching elements

// Interact
try button.tap()                     // fires action closure (synchronously)

// Read content
try text.string()                    // String
try button.accessibilityLabel()      // InspectableView<ViewType.Text>
try (try button.accessibilityLabel()).string()
try button.accessibilityIdentifier() // String

// Bulk text scan
let strings = try sut.inspect()
    .findAll(ViewType.Text.self)
    .compactMap { try? $0.string() }
```

### Anatomy of a ViewInspector test

```swift
import Testing
import ViewInspector
@testable import Encounter

@MainActor
@Suite("MyView")
struct MyViewTests {

  @Test func showsDefinitionName() throws {
    let def = EncounterDefinition(name: "Goblin Ambush")
    let sut = MyView(definition: def, compendium: PreviewData.compendium())
    let texts = try sut.inspect()
        .findAll(ViewType.Text.self)
        .compactMap { try? $0.string() }
    #expect(texts.contains("Goblin Ambush"))
  }

  @Test func buttonTapSetsBinding() throws {
    var selected: EncounterDefinition? = nil
    let def = EncounterDefinition(name: "Test")
    let binding = Binding(get: { selected }, set: { selected = $0 })
    let sut = MyView(definition: def, onSelect: binding)
    try sut.inspect().implicitAnyView().button().tap()
    #expect(selected?.name == "Test")
  }
}
```

`PreviewData` (in `Encounter/Views/PreviewData.swift`, `#if DEBUG`) provides ready-made
store instances: `PreviewData.compendium()`, `.encounterStore()`, `.playerStore()`,
`.sessionRegistry()`, `.sessionStore()`, `.contentStore()`.

### Run without a simulator

```bash
xcodebuild test -scheme Encounter -destination 'platform=macOS'
```

All ViewInspector tests complete in under one second total.

---

## XCUITest

XCUITest is for end-to-end flows that require a real running app: navigation sequences,
session lifecycle, real UIKit touch delivery. It is not a substitute for ViewInspector at
the view-structure level.

### State isolation

Every test must start from a known-empty state:

```swift
override func setUpWithError() throws {
  continueAfterFailure = false
  app = XCUIApplication()
  app.launchArguments = ["-UITestResetState"]
  app.launch()
}
```

`-UITestResetState` is handled in `EncounterApp.init()` and removes all persisted store
data before any load occurs. `continueAfterFailure = false` stops the test at the first
failure so subsequent steps don't fail with confusing messages.

### Element querying — SwiftUI identifier propagation

| SwiftUI construct | Where the identifier lands | XCUITest query |
|---|---|---|
| `Button { } label: { }` | On the Button element | `app.buttons["id"]` |
| `.accessibilityIdentifier` on `VStack`/`HStack` | Propagates to each `Text` leaf | `app.staticTexts["id"]` |
| `TextField` | On the TextField | `app.textFields["id"]` |
| `Toggle` | On the Switch element | `app.switches["id"]` |
| `Form`/`List` row without a `Button` wrapper | Propagates to leaf cells | `app.cells["id"]` or `app.staticTexts["id"]` |
| `Tab` view in `TabView` | Does NOT propagate to tab bar button | `app.tabBars.buttons["Encounters"]` |

**Tab bar:** iOS 26's `TabView` does not expose custom identifiers on the tab bar buttons.
Always use label-based queries: `app.tabBars.buttons["Encounters"]`.

**Row testability:** Wrap a row in `Button` if it must be queried as `app.buttons`. Apply
`.accessibilityElement(children: .combine)` to a composite row to produce a single AX element
instead of scattering the identifier across leaf nodes.

### AX tap vs HID coordinate tap

`element.tap()` sends `UIAccessibilityActivate` — fires the button action but does NOT
call `resignFirstResponder` on any focused text field.

`element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()` sends a real
UIKit HID touch — calls `resignFirstResponder`, dismisses the keyboard, but does NOT fire
buttons inside `Form`/`List` scroll views (the scroll gesture recognizer has priority).

| Tap method | Resigns first responder? | Fires button in Form/List? | Safe with @Observable mutation on iOS 26? |
|---|---|---|---|
| `element.tap()` | No | Yes | No — can dismiss sheets |
| `coordinate(...).tap()` (inside scroll view) | Yes | No | Yes |
| `coordinate(...).tap()` (outside scroll view) | Yes | Yes | Yes |

**Rule:** Put buttons that need reliable post-keyboard HID taps in `.safeAreaInset(edge: .bottom)`,
not inside `Form`/`List` rows. The button floats above the keyboard automatically and is outside
the scroll gesture recognizer hierarchy.

### Keyboard management

`app.navigationBars["Title"].tap()` is an AX action — it does NOT dismiss the keyboard.

To dismiss a number pad keyboard (no Done key):
```swift
// HID tap in the navigation bar region (~11% down from top)
app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.11)).tap()
```

Better: design the form so the submit button is in `.safeAreaInset` — no manual dismissal
needed in the test.

After keyboard dismissal, form scroll position does not auto-reset. Scroll before querying
fields that were off-screen:
```swift
app.collectionViews["party.form.scroll"].swipeDown()
```

### Sheet behavior

Two `.sheet()` modifiers on the same view is a bug on iOS 16+: the first sheet can dismiss
when the view re-renders. Always consolidate to a single `sheet(item:)` with an enum:

```swift
private enum SheetDestination: Identifiable {
  case add
  case edit(Player)
  var id: String { ... }
}
@State private var sheetDestination: SheetDestination?
// ...
.sheet(item: $sheetDestination) { dest in ... }
```

Even after fixing the two-sheet bug, AX taps (`element.tap()`) on buttons that mutate
`@Observable` stores can cause unexpected sheet dismissal on iOS 26. Use HID coordinate
taps for buttons that must keep a sheet open, and place those buttons outside scroll views.

### Empty TextField value

`element.value as? String` returns the placeholder string when a `TextField` is empty:
```swift
XCTAssertEqual(nameField.value as? String, nameField.placeholderValue,
  "Field should be empty (showing placeholder) after reset")
```

### Form virtualization

`Form` and `List` are backed by `UICollectionView`. Off-screen cells are not in the XCUITest
accessibility tree. `waitForExistence` will time out for a virtualized element even if it
logically exists. Scroll to bring elements into the viewport before querying them.

Navigation bar title is the most reliable sheet-presence indicator — it is always in the AX
tree regardless of form scroll position or keyboard state:
```swift
XCTAssertTrue(app.navigationBars["Add Player"].waitForExistence(timeout: 5),
  "Sheet should still be open")
```

### Test plan parallelism

Run UI tests with serialization on a development machine. Multiple simulator clones cause
resource exhaustion and non-deterministic failures:
```bash
xcodebuild test \
  -scheme Encounter \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -testPlan AllTests
```

---

## AX Tree Debugging

When `waitForExistence` fails unexpectedly, `app.debugDescription` is the ground truth for
what XCUITest sees. It reveals element types, identifiers, frames, z-order, enabled state,
keyboard presence, and off-screen (virtualized) cells.

### Dump the AX tree

```swift
// In a diagnostic XCUITest (EncounterUITests/AccessibilityTreeDump.swift)
func testDumpScreen() throws {
  let app = XCUIApplication()
  app.launchArguments = ["-UITestResetState"]
  app.launch()
  _ = app.navigationBars["Encounters"].waitForExistence(timeout: 3)
  let tree = app.debugDescription
  try? tree.write(toFile: "/tmp/ax_tree.txt", atomically: true, encoding: .utf8)
  let attachment = XCTAttachment(string: tree)
  attachment.lifetime = .keepAlways
  add(attachment)
}
```

```bash
xcodebuild test \
  -scheme Encounter \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -testPlan AllTests \
  -only-testing:EncounterUITests/AccessibilityTreeDump/testDumpScreen \
  -quiet
cat /tmp/ax_tree.txt
```

Must use `-testPlan AllTests` — the default `UnitTests` plan excludes XCUITests.
`print()` output from XCUITest does NOT appear in `xcodebuild` stdout; write to a file
or attach via `XCTAttachment`.

### Output format

```
Application, pid: 31468, label: 'Encounter'
  Window (Main), {{0.0, 0.0}, {402.0, 874.0}}
    NavigationBar, identifier: 'Encounters', {{0.0, 62.0}, {402.0, 54.0}}
      Button, identifier: 'library.create-button', label: 'New Encounter'
        at {{290.7, 66.0}, {37.3, 36.0}}
    CollectionView, identifier: 'library.list', {{0.0, 0.0}, {402.0, 874.0}}
      ...
```

Frames are `{{x, y}, {w, h}}` in logical points.

### AXe as a break-glass tool

AXe (`axe describe-ui`, `axe tap`) interacts with the running simulator via the system
accessibility API and sends HID touch events — a different event model than XCUITest's
`element.tap()`. This means:

- AXe can show a button "working" while XCUITest's `element.tap()` fails (or vice versa)
- AXe cannot assert test outcomes
- `axe describe-ui` is less complete than `app.debugDescription` (some elements are missing)

Use AXe to manually verify that the app behavior is correct at a gross level. Use
`app.debugDescription` when diagnosing `waitForExistence` failures — it shows the same
tree XCUITest operates on.

| Need | Tool |
|---|---|
| Discover element types and identifiers | `app.debugDescription` in a diagnostic XCUITest |
| Manually explore app state without tests | `axe describe-ui` |
| Debug why `waitForExistence` fails | `app.debugDescription` — not `axe describe-ui` |
| Assert correctness programmatically | XCUITest assertions |
| Confirm HID vs AX action difference | Run both; compare outcomes |

---

## Known iOS 26 / SwiftUI Quirks

### Tab bar identifiers do not propagate

`.accessibilityIdentifier` applied to a `Tab` declaration in `TabView` does not appear on
the UITabBar button in the XCUITest AX tree. Use label-based queries:
```swift
app.tabBars.buttons["Encounters"].tap()  // correct
app.buttons["tab.encounters"].tap()      // never works
```

### Two `.sheet()` modifiers — iOS 16+ bug

Two `.sheet()` modifiers on the same view: the first can dismiss when the view re-renders.
Fix: single `sheet(item:)` with an enum destination. See `PartyOverviewView.swift`.

### @Observable mutation during AX activation — sheet dismissal

`element.tap()` → button action mutates an `@Observable` store → SwiftUI re-renders the
sheet's parent view → sheet dismisses. Use HID coordinate taps for buttons that must keep
a sheet open, and place those buttons outside scroll views (e.g., in `.safeAreaInset`).

### Toggle in .safeAreaInset — SwiftUI hit-testing bug

`Toggle` controls inside `.safeAreaInset(edge: .bottom)` on a `Form` do not respond to
any interaction method: XCUITest `.tap()`, HID coordinate tap, AXe tap, Space key —
all fail. The `isHittable` property returns `true`, but the Form's scroll gesture recognizer
intercepts touches before they reach the toggle.

**Workaround (DifficultyAssessorView):** Replace `Toggle` with a custom row using
`HStack + Image(systemName:) + Text + .onTapGesture`. Expose the tap-target to AX with
`.accessibilityElement(children: .ignore)`, `.accessibilityLabel`, `.accessibilityValue`,
and `.accessibilityAddTraits(.isButton)`.

### PlayerStrip tap blocked by NavigationStack overlay — resolved

`EncounterRunnerView` previously pushed via `navigationDestination`. iOS 26's
`NavigationStack` adds a full-screen UIKit gesture-capture view for back-swipe handling
that persists after the push animation and intercepts HID touches at any y coordinate
below the navigation bar. `isHittable` returned `true` because the phantom view is not
interactive in the AX tree.

**Fix (commit c9f86b6):** Present `EncounterRunnerView` as `.fullScreenCover` instead of
a navigation push. `fullScreenCover` does not create the NavigationStack gesture-capture
overlay, so HID touch delivery to `PlayerStrip` is unblocked.

### NavigationBar toolbar buttons collapse into overflow

On iOS 26's liquid glass navigation bar, multiple `ToolbarItem(placement: .primaryAction)`
buttons collapse into an overflow "More" menu (`OverflowBarButtonItem`). XCUITest can
tap the overflow button and then tap individual items by label:
```swift
app.navigationBars.buttons["More"].tap()
app.buttons["Run Encounter"].tap()
```

### Back button label is destination name, not "Back"

`app.navigationBars.buttons["Back"]` never works. The back button's label is the
destination screen name:
```swift
app.navigationBars.buttons["Encounters"].tap()  // go back to Encounters
```
The most robust back navigation is `app.navigationBars.firstMatch.buttons.firstMatch.tap()`
or a left-edge swipe gesture.

---

## Resolved Issues

| Issue | Root cause | Resolution |
|---|---|---|
| PlayerStrip buttons never fired in XCUITest | NavigationStack full-screen gesture-capture overlay intercepting HID events | Changed to `.fullScreenCover` presentation (commit c9f86b6) |
| ViewInspector crashes on views with `@Environment` stores | ViewInspector v0.10.3 crash on `@Observable` types via `@Environment` | All custom stores moved to `init` parameters (ADR-0041) |
| Toggle in `DifficultyAssessorView` unresponsive | SwiftUI hit-testing bug: Form scroll gesture recognizer consumes events in `safeAreaInset` | Replaced `Toggle` with custom `HStack + .onTapGesture` row |
| Two-sheet dismissal bug | iOS 16+: two `.sheet()` modifiers on one view; first dismisses on re-render | Consolidated to single `sheet(item:)` with `PlayerFormDestination` enum |
| Keyboard not dismissed by `navigationBars.tap()` | AX action does not call `resignFirstResponder` | Use `coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.11)).tap()` or redesign to use `safeAreaInset` button |
| XCUITest context budget exhaustion on hit-testing bugs | 60–90 s per iteration; XCUITest can't inspect UIKit `isUserInteractionEnabled` | ViewInspector for view-state assertions; XCUITest only for e2e flows (ADR-0041) |
