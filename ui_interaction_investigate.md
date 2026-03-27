# AXe iOS Simulator Interaction — Review and Investigation Notes

Session: March 2026 — Verifying issues #26–#30 on iPhone 17 iOS 26.4
Simulator UDID: `C4AA568E-AE48-4B82-9434-4F420A6594FC`

---

## What Worked Well

### `axe describe-ui`
Reliable for exploring the accessibility tree. The most useful command in the workflow.
Best practice: pipe to a Python one-liner to filter by `AXUniqueId`, `AXLabel`, `AXValue`, or `role`:
```bash
axe describe-ui --udid <UDID> | python3 -c "
import json, sys
data = json.load(sys.stdin)
def f(n):
    uid = n.get('AXUniqueId',''); label = n.get('AXLabel','')
    if uid or label: print(uid, '|', label)
    for c in n.get('children',[]): f(c)
f(data[0])
"
```

### `axe tap --id <id>`
Reliable when elements have unique `accessibilityIdentifier` values.
Works for: form fields (`player-form.name-field`), section buttons (`builder.add-player-button`), list section header buttons.

### `axe tap -x -y` (coordinate taps)
Reliable fallback when elements lack IDs or aren't in the AX tree.
Coordinates come from `AXFrame` in `describe-ui` output (logical points, not pixels).

### `axe swipe --start-x --start-y --end-x --end-y --duration`
Works for swipe-to-delete. Required parameters:
- Kebab-case flags: `--start-x`, not `--startX`
- Long swipe distance: start at ~350, end at ~50 (full row width)
- `--duration 0.5` — short durations don't trigger the List delete action

### `axe gesture swipe-from-left-edge`
The only reliable way to trigger the iOS back navigation gesture.
`axe tap --label "Back"` fails — the back button is not exposed via AXLabel in iOS 26.
`axe tap -x 30 -y 60` (coordinate back tap) also unreliable.

### `axe batch --stdin`
Good for multi-step flows. Use heredoc:
```bash
axe batch --udid <UDID> --stdin <<'EOF'
tap --id some.element
sleep 0.3
type 'text'
EOF
```
`--step` flag does not exist — must use `--stdin` or `--file`.

### `axe key <keycode>` (HID numeric keycodes)
- `axe key 41` — Escape. Dismisses sheets and keyboards. **Useful.**
- `axe key 44` — Space. Does not activate Toggle controls (see failures below).
Strings like `axe key --key return` are invalid — only numeric HID keycodes work.

### `axe screenshot`
Reliable. Always use after interaction sequences to verify actual outcome.

---

## What Failed or Was Tricky

### 1. `axe tap --label` on list rows with duplicate IDs
**What happened:** Compendium adversary rows all share `AXUniqueId = "compendium.adversary-row"`.
`axe tap --label "Acid Burrower"` failed because the actual AXLabel was the composed string `"Acid Burrower, Solo · Tier 1 · DC 14"` — not the plain name.
**Workaround:** Coordinate tap using `y` from `describe-ui` AXFrame.
**To fix in code:** Give each adversary row a unique `accessibilityIdentifier` (e.g., append the adversary ID slug). Or use full composed label string with `axe tap --label`.

### 2. `axe key-combo` requires `--modifiers`
`axe key-combo --keys "escape"` fails — `key-combo` requires `--modifiers` (modifier keys to hold) AND `--key` (the key to press). It is not for single-key presses. Use `axe key <keycode>` for single keys.

### 3. iOS 26 toolbar buttons not in the accessibility tree
**What happened:** Both `ToolbarItem(placement: .primaryAction)` buttons in `EncounterBuilderView` ("Run Encounter" and "Browse Compendium") were absent from `axe describe-ui` output. The same was true for the AddPlayerForm's "Cancel" and "Add" buttons, the compendium detail's "Add to Encounter" button, and the library's "+" new encounter button.

**Workaround:** The `...` overflow menu at `(372, 75)` revealed the toolbar items, and `axe tap --label "Run Encounter"` worked once the menu was open. For modal form buttons (Cancel/Add), had to probe coordinates manually — `(370, 100)` worked for Add.

**Status: INVESTIGATE** — This may be a regression in iOS 26's new navigation bar design (liquid glass toolbar). Toolbar buttons should be accessible via `accessibilityIdentifier`. Check whether:
- Adding `.accessibilityElement(children: .ignore)` + explicit `.accessibilityLabel` to the button makes it appear
- Using `.toolbar` placement variants other than `.primaryAction` (e.g., `.navigationBarTrailing`) changes AX exposure
- This is a known iOS 26 bug (check Apple Developer Forums / Feedback Assistant)

### 4. Library "+" new encounter button never reachable
**What happened:** The floating "+" button for creating a new encounter in the library view was never found in the AX tree and never responded to coordinate taps. This blocked creating clean test encounters during the session.

**Status: INVESTIGATE** — The library floating action button (iOS 26 design) may need a different accessibility approach. Check `describe-ui` on the library screen and look for it — it may have an `AXUniqueId` that simply wasn't captured during the session, or it may require a scroll/focus change to appear in the AX tree.

### 5. Toggle controls inside `.safeAreaInset` did not respond to any input
**What happened:** The four `Toggle` controls in `DifficultyAssessorView` (presented via `.safeAreaInset(edge: .bottom)` on a `Form`) were visible in the AX tree with correct IDs and `AXValue = '0'`, but no interaction changed their state:
- `axe tap --id builder.difficulty.toggle.harderFight` → ✓ tap confirmed, value stays `'0'`
- `axe tap -x 201 -y 758` (center of element) → no change
- `axe tap -x 370 -y 758` (right side, where the switch thumb is) → no change
- `axe swipe` across the switch → no change
- `axe touch --down --delay 0.1 --up` → no change
- `axe key 44` (Space after focusing) → no change
- AppleScript via System Events → timeout

The AX tree always reported all four toggles as `enabled=True`, `AXValue='0'` after every attempt.

**Status: INVESTIGATE** — Several possible causes:

  **a) Form scroll view gesture interception** — SwiftUI's `Form` renders as a `UITableView`/`UICollectionView`. Its scroll gesture recognizers may extend their touch-handling region to cover the `safeAreaInset` view below. The HID touch events sent by AXe land in that region and are consumed by the scroll view before reaching the Toggle. Investigation: try replacing `Form` with `List` or `ScrollView + LazyVStack` and see if toggles become interactive.

  **b) `safeAreaInset` z-ordering / hit testing in iOS 26** — The `.safeAreaInset` modifier may place the view in a layer that the HID event pipeline reaches correctly for visual rendering but not for touch dispatch in iOS 26's new rendering system. Investigation: try placing the assessor inside the Form as its last `Section` and see if toggles work there.

  **c) `Binding(get:set:)` re-render race** — The `toggleBinding(for:)` helper creates a fresh `Binding` on every render. If a toggle tap triggers a SwiftUI re-render before the UISwitch interaction completes, the switch could be replaced with a new instance that reverts to its initial state. Code analysis suggests this is unlikely (standard SwiftUI pattern), but worth testing: refactor to `@State var manualEasier = false` etc. and see if toggles respond.

  **d) AXe bug with `AXCheckBox` activation** — `Toggle` is reported as `AXCheckBox` in the AX tree. AXe's `tap` sends a HID touch event at the element center, not an accessibility action. For `AXCheckBox`, the correct accessibility interaction would be `AXPress` (a performAction call), not a coordinate tap. AXe may need a way to trigger accessibility actions directly.

  **Recommended test:** Open the app in Xcode Simulator (not via AXe) and click the toggles with the mouse cursor. If they respond, the bug is in AXe's HID simulation for this context. If they don't respond even with mouse clicks, it's a SwiftUI layout/hit-testing bug.

### 6. Player form "Add" button required keyboard dismissal first
**What happened:** After filling all fields, `axe tap -x 370 -y 55` (visually where "Add" appears) did not submit the form while a number field had keyboard focus. The keyboard was occupying the lower half of the screen, and the tap coordinates worked visually but the keyboard intercepted them.

**Workaround:** Tap a section header at `(201, 132)` first to dismiss the keyboard, then tap at `(370, 100)` for the Add button.

**Note:** This is expected iOS behavior, not an AXe bug. The reliable approach for forms: always dismiss the keyboard before tapping toolbar buttons.

---

## Accessibility Identifier Gaps Found

These elements lacked `accessibilityIdentifier` values, forcing coordinate-based taps:

| Element | Location | Impact |
|---|---|---|
| Compendium adversary rows | `CompendiumBrowserView` | All rows share one ID; can't select by name |
| Adversary detail "Add to Encounter" | `CompendiumBrowserView` detail | Coordinate tap required |
| `AddPlayerForm` Cancel/Add buttons | `AddPlayerForm` toolbar | Coordinate tap required; keyboard timing matters |
| Nav bar back button | All navigation screens | Must use `swipe-from-left-edge` |
| Library "+" new encounter button | `EncounterLibraryView` | Completely unreachable |

---

---

## Alternative: XCUITest `debugDescription`

### What it is

`XCUIApplication().debugDescription` inside a running XCUITest dumps the complete accessibility
tree as a structured text tree. It uses the XCTest framework's own accessibility layer — the same
one Apple's UI test automation is built on — rather than the AXe HID/AX API.

### How to use it

Write a test that writes `debugDescription` to a known file path, then run it with xcodebuild:

```swift
// EncounterUITests/AccessibilityTreeDump.swift
func testDumpScreen() throws {
  let app = XCUIApplication()
  app.launch()
  _ = app.navigationBars["Encounters"].waitForExistence(timeout: 3)
  let tree = app.debugDescription
  try? tree.write(toFile: "/tmp/ax_tree.txt", atomically: true, encoding: .utf8)
}
```

```bash
xcodebuild test \
  -scheme Encounter \
  -destination 'platform=iOS Simulator,id=<UDID>' \
  -testPlan AllTests \
  -only-testing:EncounterUITests/AccessibilityTreeDump/testDumpScreen \
  -quiet
cat /tmp/ax_tree.txt
```

**Important:** Must use `-testPlan AllTests` — the default UnitTests plan excludes UITests.
`print()` from XCUITest does NOT appear in xcodebuild stdout; write to file or use `XCTAttachment`.

### What it reveals that AXe misses

Running this against the Encounter app exposed several elements that `axe describe-ui` never reported:

#### 1. Library "+" / New Encounter button — FOUND

```
Button, identifier: 'library.create-button', label: 'New Encounter'
  at {{290.7, 66.0}, {37.3, 36.0}}
```

AXe's `describe-ui` never surfaces this button. Its identifier is `library.create-button` and its
center is at **(309, 84)**. Coordinate tap at (309, 84) successfully opened the "New Encounter"
dialog. The `--id library.create-button` selector in AXe still fails — the button simply isn't in
AXe's accessibility tree, but the coordinate is now reliably known.

#### 2. Back button — FOUND

```
Button, identifier: 'BackButton', label: 'Encounters'
  at {{16.0, 62.0}, {44.0, 44.0}}
```

AXe's `--label "Back"` always failed. XCUITest reveals the correct label is `'Encounters'` (the
destination screen name) and the identifier is `'BackButton'`. Center: **(38, 84)**. The `swipe-from-left-edge`
gesture remains the most robust back navigation, but `axe tap --label "Encounters"` or `axe tap -x 38 -y 84`
are now confirmed working alternatives.

#### 3. Toggle inner Switch sub-element — FOUND, but still broken

Each `Toggle` in the `DifficultyAssessorView` has a child `Switch` element that AXe doesn't expose:

```
Switch, identifier: 'builder.difficulty.toggle.easierFight'
  at {{16.0, 714.0}, {370.0, 28.0}}, value: 0      ← outer wrapper (what AXe sees)
  └─ Switch, at {{325.0, 714.0}, {63.0, 28.0}}, value: 0   ← actual UISwitch thumb control
```

The actual interactive `UISwitch` control is at **x=325–388, y=714–742** (center: 356, 728). AXe was
tapping the outer wrapper's center at x=201, which is just the label area. The inner switch center is
at **(356, 728)**.

**However:** Tapping at (356, 728) via AXe HID still does not change the toggle value. And running
`easierToggle.tap()` directly in XCUITest also leaves value at `0`. **The toggle failure is a confirmed
SwiftUI bug, not an AXe limitation.** Both the XCTest framework's own tap and AXe's HID simulation
fail identically.

#### 4. Toolbar buttons — behind OverflowBarButtonItem (confirmed)

```
Button, identifier: 'OverflowBarButtonItem', label: 'More'
  at {{344.0, 66.0}, {38.0, 36.0}}
```

The builder's "Run Encounter" and "Browse Compendium" buttons are collapsed into the overflow menu.
The overflow button's center is **(363, 85)** — close to but not identical to the y=75 probe that
was found empirically. `axe tap -x 363 -y 85` is now a precise, documented tap target.

### Output format

`debugDescription` produces indented text (not JSON). Example structure:
```
Application, pid: 31468, label: 'Encounter'
  Window (Main), {{0.0, 0.0}, {402.0, 874.0}}
    NavigationBar, identifier: 'Dragon Lair...', {{0.0, 62.0}, {402.0, 54.0}}
      Button, identifier: 'BackButton', label: 'Encounters', {{16.0, 62.0}, {44.0, 44.0}}
      Button, identifier: 'OverflowBarButtonItem', label: 'More', {{344.0, 66.0}, {38.0, 36.0}}
    CollectionView, identifier: 'library.list', {{0.0, 0.0}, {402.0, 874.0}}
      Cell, {{16.0, 156.3}, {370.0, 70.7}}
        Switch, identifier: 'builder.difficulty.toggle.easierFight', value: 0
          Switch, {{325.0, 714.0}, {63.0, 28.0}}, value: 0   ← child UISwitch
```

Frames are `{{x, y}, {w, h}}` in logical points. Element addresses (e.g. `0x117014000`) change
per launch and are not useful for automation.

### When to use it vs. AXe

| Need | Tool |
|---|---|
| Find unknown element coordinates | `debugDescription` first, then AXe coordinates |
| Discover accessibility identifiers | `debugDescription` (more complete tree) |
| Interact with known elements | AXe (faster, no build required) |
| Confirm a tap worked | AXe `screenshot` |
| Debug element hierarchy / z-order | `debugDescription` (shows nesting, sub-elements) |
| Investigate unresponsive elements | `debugDescription` reveals child elements AXe misses |

### Confirmed bugs vs. tooling limitations (updated)

| Issue | Previously thought | Now confirmed |
|---|---|---|
| Toggle in `safeAreaInset` unresponsive | AXe HID limitation | **SwiftUI bug** — XCUITest `.tap()` also fails |
| Library "+" button unreachable | Unknown — not in AXe tree | **AXe tree gap** — coordinates (309, 84) work via AXe tap |
| Toolbar buttons not in AXe tree | iOS 26 regression | **Confirmed** — they exist but only inside `OverflowBarButtonItem`; `OverflowBarButtonItem` center is (363, 85) |

---

## Alternative: `ios-simulator-skill` (Python scripts via IDB)

### What it is

A separate global skill at `~/.claude/skills/ios-simulator-skill/` with 21 Python scripts
(`screen_mapper.py`, `navigator.py`, `gesture.py`, `keyboard.py`, `accessibility_audit.py`, etc.)
that use a semantic, accessibility-first approach — finding elements by meaning rather than coordinates.

The design goal directly addresses the weakness of AXe: instead of sending raw HID touch events,
`navigator.py` finds elements by label/type/ID and dispatches via the IDB accessibility API, which
can trigger `AXPress` actions rather than simulated finger taps. This is the right primitive for
activating `AXCheckBox` (Toggle) controls and other elements that AXe's HID approach misses.

### Hard requirement: IDB

Every script routes through **IDB (iOS Development Bridge)** — Facebook's open-source iOS automation
tool. The skill has no fallback to simctl or AXe.

Two components are needed:
- `idb-companion` — a gRPC server that attaches to the simulator (binary, installable via Homebrew)
- `idb` — the Python CLI client that sends commands to the companion

```bash
brew tap facebook/fb
brew install facebook/fb/idb-companion   # installs idb_companion binary
pip install fb-idb                        # installs idb Python CLI client
```

### Python version compatibility problem

`idb-companion` 1.1.8 (current Homebrew release, built August 2022) and the `fb-idb` Python client
use `asyncio.get_event_loop()` without first creating an event loop. This API was deprecated in
Python 3.10 and became a hard `RuntimeError` in Python 3.12+.

**Result:** `idb` crashes immediately on Python 3.13 and 3.14 (the only versions installed on this machine):
```
RuntimeError: There is no current event loop in thread 'MainThread'.
```

**The IDB project appears unmaintained** — last `idb-companion` Homebrew release was August 2022,
the Python package is 1.1.7 (matching the companion), and the GitHub repo has open issues about
Python 3.12+ compatibility with no recent activity.

### Status: Blocked — IDB not usable on this machine

The `ios-simulator-skill` scripts cannot run without a working `idb` CLI. Options to unblock:

1. **Install Python 3.11** via pyenv or asdf (last Python before asyncio changes became strict)
   and create a virtualenv with `fb-idb` installed. Then patch the skill scripts to use that
   interpreter explicitly.

2. **Patch `idb/cli/main.py`** — the fix is one line: replace `asyncio.get_event_loop()`
   with `asyncio.new_event_loop()` or wrap main in `asyncio.run(...)`. Since this is installed
   as a package, editing the installed file at
   `/opt/homebrew/lib/python3.14/site-packages/idb/cli/main.py` would work until the package
   is reinstalled.

3. **Build IDB from source** — the `idb` monorepo on GitHub may have a more recent commit with
   the Python 3.12+ fix even though no release has been tagged.

4. **Accept the limitation** — use AXe for what it handles well and note the Toggle / toolbar
   button gaps in the investigation file (this document).

### What it would offer if IDB worked

Based on reading the skill documentation and scripts, IDB's approach would likely solve the two
main AXe failures:

| Failure | Why IDB would help |
|---|---|
| Toggle in `safeAreaInset` unresponsive | `navigator.py` uses `idb ui tap` which dispatches through IDB's accessibility layer, not raw HID. IDB can also trigger `AXPress` actions directly. This bypasses the Form scroll view gesture intercept. |
| Toolbar buttons absent from AX tree | `navigator.py --find-text "Run Encounter"` uses IDB's `idb ui describe-all --json --nested` which exposes a richer tree than AXe's. Toolbar items that AXe misses may appear in IDB's tree. |
| Keyboard `--dismiss` flag | `keyboard.py --dismiss` has a dedicated keyboard-dismiss command; no need to tap a section header as a workaround. |
| Semantic element matching | `navigator.py --find-text "Acid Burrower"` does fuzzy matching across the full tree — no need to know exact composed label strings or Y coordinates. |

---

## Summary: Reliability Tiers

| Interaction | Reliability | Notes |
|---|---|---|
| `describe-ui` + inspect | ✅ Reliable | Core tool |
| `tap --id` on form fields | ✅ Reliable | Needs `accessibilityIdentifier` set |
| `tap --label` on buttons | ✅ Reliable when label is exact | Fails on composed labels |
| `tap -x -y` coordinates | ✅ Reliable | Must probe with `describe-ui` first |
| `swipe` for List delete | ✅ Reliable | Needs duration ≥ 0.5, long distance |
| `gesture swipe-from-left-edge` | ✅ Reliable | Only reliable back navigation |
| `key 41` (Escape) | ✅ Reliable | Dismisses keyboards, sheets |
| `batch --stdin` | ✅ Reliable | Preferred for multi-step |
| iOS 26 toolbar buttons | ⚠️ Partial | Overflow menu at `(372, 75)`; form toolbar requires keyboard dismiss |
| `Toggle` in `safeAreaInset` | ❌ Broken | No interaction method worked; IDB `AXPress` may fix |
| Library "+" button | ❌ Broken | Never reachable via AXe; IDB tree may expose it |
| `ios-simulator-skill` scripts | ❌ Blocked | Requires IDB; IDB Python client broken on Python 3.12+ |
