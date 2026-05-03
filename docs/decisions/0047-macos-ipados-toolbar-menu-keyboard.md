# ADR-0047: macOS/iPadOS Toolbar, Menu Structure, Inspector, and Keyboard Model

**Status:** Accepted
**Date:** 2026-05-03

## Context

ADR-0043 established the three-mode `NavigationSplitView` architecture for macOS and iPadOS but did not specify:

- What items appear in the window toolbar and in which order
- The full macOS menu structure
- Whether the right panel is a toggleable inspector or always-visible
- Keyboard shortcuts for the primary workflows
- Drag and drop between the compendium utility panel and the encounter editor
- Sidebar bottom bar placement for management actions

A review against Mario Guzmán's Mac Platform Design Guidelines (marioaguzman.github.io/design/) identified these as critical gaps for a native-feeling macOS app.

## Decisions

### 1. Right panel as a toggleable inspector

The right panel (`CompendiumUtilityPanel`, `AdversaryInspectorView`, `RunnerDetailPanel`) is implemented as an AppKit/SwiftUI inspector using `.inspectorTrackingSeparator` and `.toggleInspector`. It is hideable/showable by the user.

**Default visibility per mode:**
- `.encounterPrep` — **open** (the compendium utility panel is the point of the right column in prep mode)
- `.compendiumManagement` — **open** (adversary inspector is central to that mode)
- `.runningEncounter` — **hidden** (runner list gets full width by default; GM can reveal the adversary reference panel when needed)

The inspector toggle (`⌃⌘I`) is anchored as the trailing-most toolbar item in all modes.

### 2. Toolbar design per mode

Toolbar items follow the mental-model ordering rule (most-used → left) and use AppKit built-in identifiers where available.

**All modes — fixed items:**
- Leading anchor: `.toggleSidebar` + `.sidebarTrackingSeparator`
- Trailing anchor: `.inspectorTrackingSeparator` + `.toggleInspector`

**Encounter Prep — content zone items (contributed by `EncounterEditorView` when active):**
- Run / Resume button (enabled only when an encounter is open in the center column)

**iPadOS only — centered item (contributed by `ContentView`):**
- `NSToolbarItemGroup` segmented picker: Encounters | Compendium (mode switch)

**Compendium Management — content zone items:**
- No additional toolbar items; all management actions (Add, Import, Export) live in the sidebar bottom bar.
- `NSSearchToolbarItem` for search (expands in place) may be added here.

**Running Encounter — content zone items:**
- Pause button (⌘.)
- End Encounter button (no keyboard shortcut — destructive)
- Fear Tracker button (existing `FearTrackerButton`)

In run mode, the sidebar toggle remains present but the left runner panel is not typically hidden; the inspector toggle controls the right adversary reference panel.

### 3. Sidebar bottom bars for management actions

Per the sidebar guidelines, actions that create, delete, or modify sidebar content belong in the **sidebar's bottom bar** (`safeAreaBar(edge:alignment:spacing:content:)`), not in the toolbar zone.

Encounter list bottom bar (in `EncounterAndPartyPanel`):
- [+] New Encounter
- [−] Delete selected encounter (enabled when an encounter is selected; confirmation required)

Party list bottom bar (in `EncounterAndPartyPanel`):
- [+] Add Player → `PlayerForm` sheet
- [−] Remove selected player (confirmation required)

Compendium adversary list bottom bar (in `CompendiumAdversaryListPanel`):
- [+] Add Adversary → `AdversaryCreatorForm`
- [↓] Import DHPack → file importer
- [↑] Export Local → `DHPackExportSheet`

The sidebar toolbar zone contains only `.toggleSidebar` and `.sidebarTrackingSeparator`.

### 4. Menu structure

```
Encounter (app menu)
  About Encounter
  ─────
  Settings…                     ⌘,
  ─────
  Hide Encounter                 ⌘H
  Hide Others                    ⌥⌘H
  Quit Encounter                 ⌘Q

File
  New Encounter                  ⌘N         (context: encounter mode)
  New Adversary                  ⌘N         (context: compendium mode)
  ─────
  Rename…                                   (enabled: item selected)
  Delete…                        ⌫          (enabled: item selected; confirmation required)
  ─────
  Import DHPack…                 ⇧⌘I
  Export Local Adversaries…                 (enabled: local adversaries exist)

Edit
  Undo                           ⌘Z
  Redo                           ⇧⌘Z
  ─────
  Cut                            ⌘X
  Copy                           ⌘C
  Paste                          ⌘V
  Select All                     ⌘A

Encounter                                   (top-level; actions are contextual)
  Run Encounter                  ⌘R         (enabled: encounter selected, no active session)
  Resume Encounter               ⌘R         (enabled: paused session for selection)
  ─────
  Pause Encounter                ⌘.         (enabled: session running)
  End Encounter                             (enabled: session running or paused; confirmation)
  ─────
  Reset Encounter                           (enabled: session exists; confirmation)

View
  Show/Hide Sidebar              ⌃⌘S
  Show/Hide Inspector            ⌃⌘I
  ─────
  Encounters                     ⌘1         (mode switch)
  Compendium                     ⌘2         (mode switch)

Window
  (standard AppKit items)

Help
  Encounter Help
  (search bar)
```

**Implementation notes:**
- `⌘N` is context-sensitive: `CommandMenu("File")` checks the current `AppWindowMode` — creates an encounter in `.encounterPrep`, creates an adversary in `.compendiumManagement`.
- `⌘R` is also context-sensitive: enabled and labeled "Run" or "Resume" based on whether a paused session exists.
- The "Encounter" top-level menu uses `CommandMenu("Encounter")`. Its items enable/disable based on `encounterSelection` and `AppWindowMode` in `ContentView`.
- `Run Encounter` / `Resume Encounter` share the `⌘R` key; only one is enabled at a time.

### 5. Keyboard shortcuts

Full shortcut table:

| Action | macOS | iPadOS | Notes |
|---|---|---|---|
| New Encounter (in encounter mode) | ⌘N | ⌘N | |
| New Adversary (in compendium mode) | ⌘N | ⌘N | Same key, different context |
| Delete selected item | ⌫ | ⌫ | Confirmation required |
| Rename selected item | ↩ | ↩ | Opens inline rename or alert |
| Open / edit selected encounter | ⌘↩ | ⌘↩ | Focus center column |
| Run Encounter | ⌘R | ⌘R | Disabled when running; shows Resume label when paused |
| Resume Encounter | ⌘R | ⌘R | Shares key with Run; only one enabled at a time |
| Pause Encounter | ⌘. | ⌘. | Standard Mac "stop" chord |
| End Encounter | — | — | No shortcut; deliberate — destructive |
| Reset Encounter | — | — | No shortcut; deliberate — destructive |
| Mode: Encounters | ⌘1 | ⌘1 | |
| Mode: Compendium | ⌘2 | ⌘2 | |
| Toggle Sidebar | ⌃⌘S | ⌃⌘S | AppKit `.toggleSidebar` built-in |
| Toggle Inspector | ⌃⌘I | ⌃⌘I | AppKit `.toggleInspector` built-in |
| Focus search / filter bar | ⌘F | ⌘F | |
| Add Adversary to Encounter | ⌘⇧A | ⌘⇧A | From compendium row or utility panel |
| Import DHPack | ⌘⇧I | — | |
| Settings | ⌘, | — | |

**No keyboard shortcut for Fear Tracker** — the GM is typically using pointing device to manage the runner list; the Fear popover button is the right affordance.

**No keyboard shortcuts for End or Reset** — both are destructive. Deliberate menu navigation or button click is the intended path.

**iPadOS hardware keyboard:** All of the above apply when a hardware keyboard is connected. SwiftUI `Commands` work on iPadOS. Additionally:
- Arrow keys navigate selected list item
- Return opens/renames the selected item (consistent with macOS)
- Escape dismisses sheets and deselects

### 6. Drag and drop

In scope for the macOS/iPadOS redesign (Milestone 4):

- **Source:** Adversary rows in `CompendiumUtilityPanel` (prep mode, right panel)
- **Target:** Adversary list in `EncounterEditorView` (center column)
- **Behavior:** Dropping an adversary row onto the list adds it to the encounter (same as tapping the row). Duplicate detection: if the adversary is already in the encounter, ask to add a second slot or do nothing.
- **Implementation:** `draggable(adversary)` on the row, `.dropDestination(for: Adversary.self)` on the list or an explicit drop zone within the section.
- **iPadOS:** Touch drag works with the same API.

Drag is not implemented between other panels (e.g., no drag from the encounter editor to the runner, no drag to reorder adversary slots — those are separate features).

### 7. Mac polish requirements

The following are required for a native-feeling app but are not tracked as separate ADRs:

- **Tooltips** on all interactive controls (toolbar buttons, sidebar bottom bar buttons, condition toggles). Add `.help("description")` modifier.
- **Minimum window size:** 900 pt wide × 560 pt tall. Enforced with `.frame(minWidth: 900, minHeight: 560)` on the `WindowGroup`'s content. Sidebar min width 240 pt, max 360 pt; inspector min width 280 pt, max 400 pt.
- **State restoration:** `AppWindowMode` and `selectedEncounterID` should restore on relaunch. Use `@SceneStorage` for the mode and selection.
- **Dock menu:** Override `applicationDockMenu` to offer "New Encounter" and, when a paused session exists, "Resume [encounter name]".
- **Spotlight keywords** in `Info.plist` (`MDItemKeywords`): "daggerheart, encounter, gm, gamemaster, ttrpg, rpg, adversary, combat".
- **Credits.rtf** in bundle resources for the standard About window.

## Options Considered

- **Pause/End in the left runner panel vs. toolbar (decided: toolbar).** Window-mode commands (pause, end) should not scroll with content. The toolbar is the stable, always-visible location for them.
- **Fear shortcut (decided: no shortcut).** The GM is already using the trackpad/mouse during a run. A keyboard shortcut for Fear adds memorization burden for an action that has a one-tap affordance.
- **Drag from compendium utility panel (decided: in scope).** The tap-to-add callback is simpler to build but click-drag is the idiomatic Mac interaction for "move this thing into that list." Both coexist — tapping still calls `onSelect` directly.

## Consequences

- `EncounterApp.swift` gains a full `Commands` block with `CommandMenu("File")`, `CommandMenu("Encounter")`, `CommandMenu("View")`, and several `CommandGroup(replacing:)` entries.
- `ContentView` (macOS/iPadOS branch) adds `@SceneStorage` for `AppWindowMode` and selection.
- `WindowGroup` in `EncounterApp.swift` gets `.frame(minWidth: 900, minHeight: 560)` and sidebar/inspector width constraints.
- `EncounterAndPartyPanel` and `CompendiumAdversaryListPanel` gain sidebar bottom bars instead of inline toolbar buttons.
- `RunnerListPanel` loses its Pause/End header buttons; these move to the toolbar (contributed when `AppWindowMode == .runningEncounter`).
- Drag source added to adversary rows in `CompendiumUtilityPanel`; drop target added to `EncounterEditorView` adversary list section.
- All interactive controls gain `.help("…")` tooltips.
