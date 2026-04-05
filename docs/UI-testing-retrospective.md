# UI Testing Retrospective: XCUITest for Party Management (PR #69)

**Date:** 2026-04-05  
**Branch:** `feature/player-party-management`  
**Context:** iOS 26 / SwiftUI / Swift 6 / `@Observable` stores

---

## 1. What Was Being Built

XCUITests covering a new party management feature: a Party tab where the GM adds, edits, and removes players, with the active party roster surfacing in the Encounter builder. The feature uses `@Observable` stores (`PlayerStore`) injected via the SwiftUI environment. Three integration test cases were targeted:

1. Launch → Party tab first, empty-state CTA visible
2. "Add Another" flow → form resets without dismissing, two distinct players committed
3. Add player → switch to Encounters → open builder → roster row visible

---

## 2. Problems Encountered (Chronological)

### 2.1 Tab bar accessibility identifiers not propagating

**Symptom:** `app.buttons["tab.encounters"]` returned no match. `waitForExistence` timed out.

**What was tried:** The tabs in `ContentView` had `.accessibilityIdentifier("tab.encounters")` applied to the `Tab` view. The assumption was that this identifier would appear on the corresponding tab bar button.

**Root cause:** In iOS 26's `TabView`, `.accessibilityIdentifier` applied to a `Tab` declaration does NOT propagate to the UITabBar button element that XCUITest queries. The AX tree exposed by XCUITest shows `TabBarButton` elements with labels (`"Party"`, `"Encounters"`) but no custom identifiers.

**Fix:** Query by label scoped to the tab bar: `app.tabBars.buttons["Encounters"]`. Identifier-based queries on tab buttons are not available without significant SwiftUI workarounds.

**Lesson:** The AX tree dump (`app.debugDescription`) was the diagnostic that revealed this immediately. Without it, trial-and-error on identifier names would have continued indefinitely.

---

### 2.2 Two `.sheet()` modifiers on the same view — iOS 16+ bug

**Symptom:** After tapping "Add Another", the sheet dismissed. AXe manual HID simulation kept the sheet open. Only XCUITest triggered the dismissal.

**What was tried:** Diagnostic tests, AX tree dumps before and after the tap, comparing AXe behavior vs XCUITest behavior.

**Root cause:** `PartyOverviewView` had two separate `.sheet()` modifiers:
```swift
.sheet(isPresented: $showAddPlayer) { ... }
.sheet(item: $editingPlayer) { ... }
```
On iOS 16+, two `.sheet()` modifiers on the same view cause the first to dismiss whenever the view re-renders. When "Add Another" fires `addPlayer` → `PlayerStore` notifies all observers → SwiftUI re-renders `PartyOverviewView` → first sheet dismisses. AXe's HID simulation didn't trigger this because it wasn't tied to the XCUITest process; the test's in-process observation of accessibility events was the trigger.

**Fix:** Consolidated to a single `sheet(item:)` with a `PlayerFormDestination` enum:
```swift
private enum PlayerFormDestination: Identifiable {
    case add
    case edit(Player)
    var id: String { ... }
}
@State private var playerFormDestination: PlayerFormDestination?
// ...
.sheet(item: $playerFormDestination) { destination in ... }
```

**Lesson:** Any view with multiple sheet modifiers is a latent iOS 16+ bug. Always use `sheet(item:)` with an enum for multiple sheet destinations.

---

### 2.3 `app.navigationBars["..."].tap()` does not resign first responder

**Symptom:** After calling `app.navigationBars["Add Player"].tap()` to dismiss the keyboard, the AX tree still showed the keyboard at `{{0, 583}, {402, 233}}`. Coordinate taps at the computed button position were landing on keyboard keys instead of the button.

**Root cause:** `element.tap()` in XCUITest sends a UIAccessibility activate action, not a touch event. For a navigation bar, this fires the bar's accessibility action (focus, announce), but does NOT send a touch through UIKit's responder chain — so UITextField does not receive `touchesBegan` and `resignFirstResponder` is never called.

**Fix:** Use a HID coordinate tap in the navigation bar title area (safe zone, y ≈ 11% of screen height):
```swift
app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.11)).tap()
```
This sends a real touch event through the responder chain, resignFirstResponder fires, keyboard animates out.

**Better fix:** Move the button that needs to be tapped into `safeAreaInset(edge: .bottom)`, which sits above the keyboard. No dismissal step needed at all.

---

### 2.4 AX tap vs HID coordinate tap — what each does and when each causes problems

**Symptom:** `addAnother.tap()` dismissed the sheet. `addAnother.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()` kept the sheet open but the button action didn't fire when the button was inside a `Form`/`List`.

**Root cause (AX tap dismissing sheet):** `element.tap()` sends `UIAccessibilityActivate`. On iOS 26 with `@Observable`, this triggers the button action which mutates the store, which notifies observers, which re-renders the sheet's parent view — all within the accessibility event processing cycle. Combined with the two-sheet bug (see §2.2), this causes the sheet to dismiss. Even after fixing the two-sheet bug, AX taps on buttons that fire `@Observable` mutations can trigger unexpected re-render cycles during the accessibility activation pass.

**Root cause (coordinate tap not firing inside Form/List):** A `Button` inside `Form` or `List` is wrapped in a `UITableViewCell`. The cell's scroll gesture recognizer has priority over tap gesture recognizers for HID touch events. A coordinate tap landing inside the scroll view gets consumed by the scroll recognizer's touchesBegan, not forwarded to the button. This is not a SwiftUI-specific issue — it's how UIKit list cells handle gestures.

**Fix:** Move the "Add Another" button out of the `Form` scroll view into `safeAreaInset(edge: .bottom)`. This places it in a view hierarchy that is NOT under the scroll view, so HID coordinate taps reach the button's gesture recognizer directly:
```swift
.safeAreaInset(edge: .bottom) {
    if case .add = mode {
        Button("Add Another Player") {
            commitPlayer()
            resetFields()
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .accessibilityIdentifier("party.form.add-another-button")
    }
}
```
In the test, use coordinate tap for this button specifically:
```swift
addAnother.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
```

**Summary table:**

| Tap method | Sends | Resigns responder? | Fires button in Form/List? | Sheet-safe on iOS 26? |
|---|---|---|---|---|
| `element.tap()` | UIAccessibilityActivate | No | Yes | No (with @Observable) |
| `element.coordinate(...).tap()` | UIKit HID touch | Yes | No (inside scroll view) | Yes |
| `element.coordinate(...).tap()` | UIKit HID touch | Yes | Yes (outside scroll view) | Yes |

---

### 2.5 After `resetFields()`, form is scrolled — name field is virtualized off-screen

**Symptom:** After "Add Another" committed and reset the form, `waitForExistence` for `party.form.name-field` timed out even though the sheet was open. This was initially misread as the sheet having dismissed.

**Root cause:** The form was scrolled to the bottom (Armor Slots section) before the reset, because that was the last field filled. `resetFields()` clears field values but does not scroll the form back to the top. SwiftUI `Form` (backed by `UICollectionView`) virtualizes off-screen cells — elements not in the visible viewport are not in the XCUITest accessibility tree. `waitForExistence` returns false for virtualized elements even when they exist logically.

**Fix:** After the coordinate tap, verify the sheet is still open via the navigation bar (always visible regardless of scroll position), then swipe down on the form scroll view to bring the name field into view:
```swift
XCTAssertTrue(app.navigationBars["Add Player"].waitForExistence(timeout: 5),
    "Form sheet should remain open after Add Another")
app.collectionViews["party.form.scroll"].swipeDown()
let nameField = app.textFields["party.form.name-field"]
XCTAssertTrue(nameField.waitForExistence(timeout: 3), ...)
```

**Lesson:** Navigation bar title is the most reliable sheet-presence indicator because it is always in the AX tree. Never rely on a Form field's presence as proof the sheet is open.

---

### 2.6 Empty TextField `value` returns placeholder text, not `""`

**Symptom:** After reset, `nameField.value as? String == ""` assertion failed. The value was `"Name"`.

**Root cause:** XCUITest's `element.value` for a `TextField` returns the placeholder string when the field is empty, not `""`. This is how UIAccessibility exposes an empty text field — the placeholder IS the value from the AX perspective.

**Fix:**
```swift
XCTAssertEqual(
    nameField.value as? String, nameField.placeholderValue,
    "Name field should be empty (showing placeholder) after reset")
```

---

### 2.7 `accessibilityIdentifier` on `PlayerPartyRow` (VStack) propagates to `StaticText` leaves

**Symptom:** `app.buttons.matching(identifier: "builder.player-row").firstMatch` returned no match. The test for builder roster integration failed.

**Root cause:** `PlayerRosterSection` applied `.accessibilityIdentifier("builder.player-row")` directly to `PlayerPartyRow`, which is a `VStack` containing `Text` views. When an identifier is set on a `VStack` (not a `Button`), SwiftUI propagates it to each `StaticText` leaf node in the accessibility tree, not to a container `Cell` or `Button` element. Querying `app.buttons` looks for button-type elements; none exist.

**Fix:** Query `staticTexts` instead:
```swift
app.staticTexts.matching(identifier: "builder.player-row").firstMatch
    .waitForExistence(timeout: 5)
```

**Design lesson:** When a row needs to be query-stable from tests, wrap it in a `Button` (which places the identifier on a button-type element) or apply `.accessibilityElement(children: .combine)` to make it a single element. Plain `VStack`/`HStack` content spreads the identifier across all leaf nodes.

---

### 2.8 Simulator resource exhaustion from `parallelizable: true` UI tests

**Symptom:** "Resource temporarily unavailable" launcher errors. Test result bundles were incomplete. Some tests reported spurious failures unrelated to their assertions.

**Root cause:** The test plan had `parallelizable: true`, which caused Xcode to spawn multiple simulator clones simultaneously. Each clone requires significant memory. On a development machine (not a CI host) running other processes, spawning 3-4 simulator instances simultaneously exhausts resources.

**Fix:** Run UI tests with explicit serialization:
```bash
xcodebuild test \
  -scheme Encounter \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:EncounterUITests \
  -testPlan UnitTests \
  -resultBundlePath /tmp/UIOnly.xcresult
```
Or disable parallelization in the test plan for UI test targets.

---

## 3. What the Existing Skills Said vs What Was Needed

### The `axe` skill

AXe is a direct HID simulator automation tool — it fires touch events into a booted simulator process via `simctl` or IDB. The skill is excellent for:
- Manually exploring app state (batch flows, `describe-ui`)
- Verifying that a feature works at all before writing assertions
- Confirming that a bug is in the test harness, not the app

Where it falls short for XCUITest work:
- AXe has no concept of XCUITest's element hierarchy query types (`app.buttons`, `app.staticTexts`, `app.cells`). The `describe-ui` output does not map directly to what `app.debugDescription` returns.
- AXe's `tap --id` uses `AXUniqueId`; XCUITest uses `accessibilityIdentifier`. These are the same underlying value, but the contexts differ: AXe operates on the live simulator process; XCUITest has its own in-process accessibility snapshot.
- AXe cannot assert test outcomes. It fires events and requires separate `describe-ui` verification.
- AXe's HID simulation and XCUITest's `element.tap()` produce different event types. A feature that works with AXe may still fail in XCUITest because of how AX actions interact with SwiftUI's re-render cycle.

**Where the skill led somewhere unhelpful:** When the sheet dismissal bug appeared, using AXe to manually test "Add Another" showed the sheet staying open. This was accurate — AXe uses HID simulation which doesn't trigger the AX-action/re-render race. The conclusion "app behavior is correct, test failure must be in XCUITest layer" was correct, but it directed attention away from the actual root cause (two `.sheet()` modifiers) and toward tap-mechanism differences. Several investigation iterations were spent on tap mechanics before the two-sheet bug was found.

**Rule:** Use AXe to verify that the app behavior is correct at a gross level (does the sheet open? does data appear?). Do not use AXe results to rule out app bugs when XCUITest behavior differs — the event models are different enough to produce different results on iOS 26 with `@Observable`.

### The `ios-simulator-skill`

The skill provides build/test automation scripts and simulator lifecycle management. It is useful for:
- Building the app (`build_and_test.py`)
- Booting/shutting down simulators
- Accessibility audits (WCAG compliance, not element-query debugging)

The skill does not address:
- XCUITest element type semantics (`app.buttons` vs `app.staticTexts` vs `app.cells`)
- How `accessibilityIdentifier` propagates through SwiftUI view hierarchies
- AX tap vs HID tap distinctions within XCUITest
- Sheet dismissal behavior in XCUITest vs direct HID simulation
- Empty `TextField` value semantics

The scripts from this skill were not directly invoked during the XCUITest debugging sessions. The skill's `screen_mapper.py` was consulted once to verify what elements were visible, but its output format differs from `app.debugDescription` enough that it was a secondary tool.

---

## 4. Comprehensive Lessons for Robust UI Verification

### A. Organizing and Structuring XCUITests

**State isolation is non-negotiable.** Every test in the suite must start from a known-empty state. Implement a launch argument reset hook:

```swift
// EncounterApp.swift init()
if CommandLine.arguments.contains("-UITestResetState") {
    try? FileManager.default.removeItem(at: PlayerStore.localDirectory)
    try? FileManager.default.removeItem(at: EncounterStore.localDirectory)
}
```

```swift
// Every XCUITest setUp:
override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-UITestResetState"]
    app.launch()
}
```

`continueAfterFailure = false` is important: when a test's setup assertion fails (e.g., the Party nav bar never appeared), subsequent steps will fail in confusing ways. Stopping immediately produces a clear failure at the real source.

**Disable test plan parallelism for UI tests** unless running on a dedicated CI host with allocated simulator resources. On a development machine, multiple simulator clones cause resource exhaustion and non-deterministic failures.

**Separate diagnostic tests from assertion tests.** Keep `AccessibilityTreeDump` as a non-CI test class (require manual preconditions, document them). Assertion tests should be fully automated and require no manual setup.

### B. XCUITest Element Querying

**Accessibility identifier propagation rules in SwiftUI:**

| SwiftUI construct | Identifier placement | XCUITest element type |
|---|---|---|
| `Button { ... } label: { ... }` | On the `Button` | `app.buttons["id"]` |
| `.accessibilityIdentifier` on `VStack`/`HStack` | Propagates to each `Text` leaf | `app.staticTexts["id"]` |
| `TextField` | On the `TextField` | `app.textFields["id"]` |
| `Toggle` | On the `Toggle` | `app.switches["id"]` |
| `Form`/`List` row without `Button` | Propagates to leaves | `app.cells["id"]` or `app.staticTexts["id"]` |
| Tab bar `Tab` | Does NOT propagate to tab button | Use `app.tabBars.buttons["Label"]` |

**Tab bar:** There is no reliable way to give tab bar buttons custom accessibility identifiers via SwiftUI's `Tab` API in iOS 26. Always use label-based queries: `app.tabBars.buttons["Encounters"]`.

**Empty TextField:** `element.value as? String` returns the placeholder string when the field is empty. Compare against `element.placeholderValue`:
```swift
XCTAssertEqual(nameField.value as? String, nameField.placeholderValue,
    "Field should be empty")
```

**Off-screen elements are virtualized.** `Form` and `List` are backed by `UICollectionView`. Elements outside the visible viewport are not in the XCUITest accessibility tree. `waitForExistence` will time out on a virtualized element even if it logically exists. Scroll the view to bring elements into frame before querying them.

### C. AX Tap vs HID Events in XCUITest

`element.tap()` sends `UIAccessibilityActivate`. This fires the button's action closure but bypasses the UIKit touch delivery chain. Key consequences:
- Does not call `resignFirstResponder` on any focused text field
- On iOS 26 with `@Observable`, firing an action that causes state mutation during the AX activation pass can trigger unexpected view re-renders, causing sheets to dismiss

`element.coordinate(withNormalizedOffset:).tap()` sends a real HID touch event through UIKit's responder chain. Key consequences:
- Calls `resignFirstResponder` on focused text fields (keyboard dismisses)
- Does NOT fire buttons inside `Form`/`List` scroll views reliably (scroll gesture recognizer priority)
- Keeps sheets open when button action mutates `@Observable` state

**The decisive rule:** Put buttons that need reliable HID taps in `safeAreaInset`, not in `Form`/`List` rows. This makes them accessible to coordinate taps AND keeps them visible above the keyboard.

### D. Keyboard Management in XCUITest

Number pad keyboards (`keyboardType(.numberPad)`) have no Done key. There is no `app.keyboards.buttons["Done"]` to tap.

`app.navigationBars["Title"].tap()` is an AX action — it does NOT dismiss the keyboard.

To dismiss the number pad keyboard:
```swift
// HID tap in a safe area (nav bar region, top ~11% of screen)
app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.11)).tap()
```

Better: design the form so the button that must be tapped after filling number fields is in `safeAreaInset`. The button floats above the keyboard automatically — no dismissal step needed in the test.

After keyboard dismissal, form scroll position does not auto-reset. If the form was scrolled to fill later fields, scroll it back before querying early fields:
```swift
app.collectionViews["party.form.scroll"].swipeDown()
```

### E. SwiftUI Sheet Behavior in XCUITest

Two `.sheet()` modifiers on the same view is a bug on iOS 16+:
```swift
// BUG: second sheet can dismiss first on re-render
.sheet(isPresented: $showA) { ... }
.sheet(isPresented: $showB) { ... }
```

Always consolidate:
```swift
private enum SheetDestination: Identifiable { case a, case b(SomeModel) }
@State private var sheetDestination: SheetDestination?
.sheet(item: $sheetDestination) { dest in ... }
```

Even after fixing the two-sheet bug, AX taps (`element.tap()`) on buttons that mutate `@Observable` stores can cause unexpected sheet dismissal on iOS 26. Use HID coordinate taps for buttons that must keep a sheet open, and place those buttons outside scroll views.

### F. Debugging iOS UI State Efficiently

`app.debugDescription` is the ground truth for what XCUITest sees. Use it when `waitForExistence` fails unexpectedly:

```swift
// In a diagnostic test or on failure:
let tree = app.debugDescription
let path = "/tmp/ax_tree.txt"
try? tree.write(toFile: path, atomically: true, encoding: .utf8)
// Also attach to xcresult:
let attachment = XCTAttachment(string: tree)
attachment.lifetime = .keepAlways
add(attachment)
```

Write trees to `/tmp` files and attach as `XCTAttachment` — both patterns are useful: `/tmp` is readable immediately from the shell; `XCTAttachment` persists with the `.xcresult` bundle.

The AX tree reveals: element types (button vs staticText vs cell vs switch), exact frame positions, identifier values, enabled/disabled state, whether the keyboard is showing, and which cells are virtualized (absent from the tree).

---

## 5. Efficient Verification Patterns

**Discovery-first:** Before writing assertion tests for a new screen, write a diagnostic test that dumps the AX tree. Understand what element types and identifiers actually exist before writing a single `waitForExistence` call. One AX dump saves many trial-and-error cycles.

**Run tests in isolation first:** Use `-only-testing:EncounterUITests/PartyManagementUITests/testPartyTabFirstAndEmptyStateCTA` to verify a single test before running the full suite. Failures in one test obscure failures in others when running sequentially.

**Navigation bar title as sheet-presence indicator:** The navigation bar title is always in the AX tree regardless of sheet content scroll position, keyboard state, or form virtualization. `app.navigationBars["Add Player"].waitForExistence(timeout: 5)` is the most reliable way to verify a sheet is open.

**Prefer semantic nav bar waits over element queries for multi-step flows:** After each navigation action (tab switch, sheet open, alert dismiss), wait for a nav bar title before querying elements. Nav bars render before form content.

**Design for testability before writing tests:**
- Add `accessibilityIdentifier` to every interactive element before writing XCUITests
- Wrap rows in `Button` if they need to be queried as `app.buttons`
- Use `.accessibilityElement(children: .combine)` on composite rows to get a single AX element
- Put buttons that need post-keyboard-entry taps in `safeAreaInset`
- Avoid relying on `accessibilityIdentifier` on plain `VStack`/`HStack` content — identifiers propagate to leaves, producing multiple `staticTexts` with the same identifier

---

## 6. Gaps in the Axe and iOS Simulator Skills

Both skills describe tools for direct HID simulation on a booted simulator. They share an important characteristic: they interact with the running app via the system accessibility API, bypassing XCUITest's test process.

**What these tools are for:**
- Exploring app state manually
- Automating sequences for demo/smoke testing without XCTest
- Verifying that app behavior is correct at a gross level
- Capturing screenshots and accessibility trees for debugging

**What they explicitly cannot do:**
- Assert test outcomes (no XCTAssert-equivalent)
- Interact with XCUITest execution (start/stop tests, inject failures)
- Replicate the XCUITest event model (XCUITest uses a combination of AX actions and HID events that differs from pure HID simulation)

**The critical gap — event model distinction:**
AXe sends HID touch events. XCUITest's `element.tap()` sends `UIAccessibilityActivate`. These are different events with different propagation rules. When a bug only manifests with AX actions (not HID simulation), AXe cannot reproduce or diagnose it. This was the case for the sheet dismissal bug: AXe showed the form staying open; XCUITest's `element.tap()` caused dismissal. The correct diagnostic was `app.debugDescription` after an in-process XCUITest run, not AXe.

**Where AXe caused misdirection:** When AXe manual testing showed "Add Another" working correctly, several investigation turns were spent assuming the problem was purely in the tap mechanism (AX vs HID) rather than in the SwiftUI two-sheet bug. The correct conclusion (that the app had a bug that only manifested under XCUITest's event model) took longer to reach because AXe's "it works" result was treated as evidence the app was correct.

**The rule for deciding which tool to use:**

| Goal | Use |
|---|---|
| Verify app behavior manually | AXe batch flow |
| Discover element types and identifiers | `app.debugDescription` in a diagnostic XCUITest |
| Assert correctness programmatically | XCUITest assertions |
| Debug why `waitForExistence` fails | `app.debugDescription` — not AXe `describe-ui` |
| Check if a bug is in the app or the test | Run AXe AND a diagnostic XCUITest; compare |

The `ios-simulator-skill`'s `accessibility_audit.py` checks WCAG compliance — useful for missing labels and small touch targets, but not for XCUITest element hierarchy queries. The `screen_mapper.py` output is more compact than `app.debugDescription` but does not include frame positions or element-type details needed for XCUITest debugging.

Neither skill documents the AX-tap-vs-HID-tap distinction within XCUITest. Neither skill covers SwiftUI identifier propagation rules. These gaps should be filled in project-local documentation (like this retrospective) rather than waiting for the skills to be updated.
