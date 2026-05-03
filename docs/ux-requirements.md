# Encounter — UX Requirements

Per-platform screen structure, interaction patterns, and component responsibilities.
Authoritative reference for all implementation work. Derived from the planning session of 2026-05-03.

For architectural decisions see [ADR-0043](decisions/0043-platform-navigation-architecture.md),
[ADR-0044](decisions/0044-encounter-session-lifecycle.md),
[ADR-0045](decisions/0045-compendium-management-mode.md),
[ADR-0046](decisions/0046-single-party-hidden-members.md).

For the full implementation milestone breakdown see [docs/redesign-plan.md](redesign-plan.md).

---

## Design Principles for This Redesign

1. **Platform-native, not least-common-denominator.** iOS uses push navigation; macOS and iPadOS use split views with mode switching. No shared structural compromise.
2. **Modes, not destinations.** Encounter prep, compendium management, and live running are window/screen *modes* — not screens you navigate to and back from. Transitions communicate the change in context.
3. **Creator and executor are separate.** Prep work (building encounters, managing the compendium) is visually and navigationally distinct from running work (live combat tracking). You cannot accidentally enter prep UI during a live encounter.
4. **The encounter is always the unit of work.** The party, the compendium, and the runner all serve the encounter. Navigation always returns to the encounter list as the root.

---

## Platform Summary

| Platform | Root navigation | Mode switch | Runner transition |
|---|---|---|---|
| iOS | `NavigationStack` | Toolbar segmented toggle | Push on stack |
| iPadOS | `NavigationSplitView` (3-panel) | Toolbar segmented toggle | Same-window mode swap |
| macOS | `NavigationSplitView` (3-panel) | Menu command | Same-window mode swap |
| visionOS | Follows iOS layout | — | — |

---

## iOS Requirements

### Root Screen (`EncounterAndPartyRootView`)

**Navigation:** Root of a `NavigationStack`. No tabs.

**Toolbar:** Centered segmented control — **Encounters** | **Compendium**. Controls `iOSRootMode` state.

**Encounters mode content (default):**

Top half — Encounter list:
- Scrollable list of `EncounterDefinition` rows
- Each row: encounter name + relative modified date
- In-progress badge ("In Progress") shown when a paused session exists for that encounter
- Run affordance: tapping the row body pushes to `EncounterEditorView`; a "Run" / "Resume" button in the row runs or resumes directly
- Swipe actions: rename, delete (with confirmation)
- Empty state: `ContentUnavailableView` with a "New Encounter" button
- New encounter: toolbar (+) button, alert for name

Bottom half — Party list:
- Single party roster; no party switching
- Each player row: name, level/tier badge, hide/unhide toggle
- Hidden players: grayed text, `eye.slash` icon, "Unhide" swipe action
- Active players: normal style, "Hide" swipe action, "Edit" swipe action
- Add player: toolbar (+) button → `PlayerForm` sheet
- Delete player: swipe trailing delete (confirmation required)

**Compendium mode content:**
Entire screen replaced by `CompendiumRootView` — see below.

---

### Compendium Root (`CompendiumRootView`) — iOS only

**Navigation:** Nested within the root `NavigationStack`.

**Content:**
- `AdversaryFilterBar` pinned at top (search + tier + type filters)
- Grouped adversary list: **SRD** section (read-only) | one section per loaded DHPack (read-only) | **Local** section (editable, may be empty)
- Tapping an adversary row pushes to `AdversaryDetailView`
- Local adversary `AdversaryDetailView` includes an "Edit" button → `AdversaryCreatorForm` sheet

**Toolbar actions:**
- "Add Adversary" (+) → `AdversaryCreatorForm` sheet (creates in Local section)
- "Import DHPack" (archive icon) → file importer → `contentStore.importPack(from:)`
- "Export Local" (share icon) → `DHPackExportSheet` sheet (only enabled when Local section is non-empty)

---

### Encounter Editor (`EncounterEditorView`) — iOS

**Navigation:** Pushed from encounter row in `EncounterAndPartyRootView`.

**Header:** Encounter name (editable inline or via rename action), back button.

**Toolbar:**
- **Run** button (or **Resume** when a paused session exists) — pushes to `EncounterRunnerView`
- **Browse Compendium** (books icon) → `CompendiumSelectorSheet` sheet

**Form sections:**
1. Adversaries — editable list; "+" opens `CompendiumSelectorSheet`; swipe-to-delete
2. Environment — 0 or 1; "Add" / "Replace" button
3. Notes — collapsible `DisclosureGroup` with `TextEditor`

**Footer (fixed, non-scrolling):**
- `DifficultyAssessorView` — budget summary + color indicator + GM toggles

---

### Compendium Selector Sheet (`CompendiumSelectorSheet`) — iOS (and all platforms)

**Presentation:** `.sheet` from encounter editor.

**Purpose:** Selection only — not management. Adds adversaries to the current encounter.

**Content:**
- `AdversaryFilterBar` at top
- Filtered adversary list (all sources: SRD + DHPacks + Local)
- Tapping a row calls `onSelect(adversary)` and dismisses the sheet
- "Import DHPack" toolbar button — adds a pack to the compendium without dismissing

---

### Encounter Runner (`EncounterRunnerView`) — iOS

**Navigation:** Pushed from `EncounterEditorView`. Standard push transition.

**Layout:** Single `List` with accordion sections:
1. Adversary runner section (collapsed/expanded rows per ADR-0042 + ADR-0022)
2. Player runner section (same accordion pattern)

**Toolbar:**
- Fear tracker button (🔥 N) — popover
- **Pause** button — calls `session.pause()`, saves session, pops navigation back to editor
- **End Encounter** button — destructive confirm → clears session, pops navigation

**On pop (Pause):** encounter row in the root list now shows "In Progress" badge. "Resume" re-enters the runner with the saved session.

---

## iPadOS and macOS Requirements

iPadOS and macOS share the same `AppWindowMode`-driven layout. They differ only in the mode switch control and minor idiom adjustments.

---

### `AppWindowMode` states

| Mode | Columns visible | Left panel | Right panel |
|---|---|---|---|
| `.encounterPrep` | 3 | `EncounterAndPartyPanel` | `CompendiumUtilityPanel` |
| `.compendiumManagement` | 2 (sidebar + detail) | `CompendiumAdversaryListPanel` | `AdversaryInspectorView` |
| `.runningEncounter(session)` | 2 (sidebar + detail) | `RunnerListPanel` | `RunnerDetailPanel` |

Center column: `EncounterEditorView` (only visible in `.encounterPrep`).

---

### Encounter Prep Mode — 3-panel

**Left panel (`EncounterAndPartyPanel`):**

Top section — Encounter list:
- Rows: name, in-progress badge, "Run" / "Resume" button per row
- Tapping row body selects the encounter (drives center column)
- Context menu: rename, delete
- Toolbar: "+" to create new encounter

Bottom section — Party roster:
- Single party; no party switching
- Each player: name, level/tier badge
- Hidden players: grayed, `eye.slash` icon, "Unhide" contextual action
- Add player: "+" button → `PlayerForm` sheet
- Edit player: contextual action → `PlayerForm` sheet
- Delete player: contextual action (confirmation)
- Hide/unhide player: contextual action

**Center column (`EncounterEditorView`):**
- Same sections as iOS editor (Adversaries, Environment, Notes, `DifficultyAssessorView`)
- No "Browse Compendium" sheet button — the right panel replaces it
- "Run" / "Resume" toolbar button → sets `windowMode = .runningEncounter(session)`

**Right panel (`CompendiumUtilityPanel`):**
- `AdversaryFilterBar` at top
- Filtered adversary list (all sources); tapping a row calls `onSelect` to add to the currently selected encounter
- "Import DHPack" button at bottom
- Empty state when no encounter is selected in the center column

---

### Compendium Management Mode — 2-panel

**Mode entry:**
- macOS: `View → Compendium` menu command
- iPadOS: segmented toolbar toggle (Encounters | Compendium)

**Left panel (`CompendiumAdversaryListPanel`):**
- `AdversaryFilterBar` at top (filters all groups)
- Grouped list: **SRD** | [DHPack name] per loaded pack | **Local**
- Selection drives right panel
- Toolbar: "+" → `AdversaryCreatorForm`; "Import DHPack" icon; "Export Local" icon

**Right panel (`AdversaryInspectorView`):**
- No adversary selected: empty state / placeholder
- SRD or DHPack adversary selected: read-only stat card (full `AdversaryDetailView` content)
- Local adversary selected: same stat card + "Edit" button → `AdversaryCreatorForm` in edit mode (presented as sheet or inline)
- No "Add to Encounter" action (this mode is for management, not selection)

**Mode exit:**
- macOS: `View → Encounters` menu command
- iPadOS: segmented toolbar toggle back to Encounters
- `windowMode` returns to `.encounterPrep`

---

### Run Mode — 2-panel

**Mode entry:** "Run" / "Resume" button in `EncounterEditorView` toolbar. Sets `windowMode = .runningEncounter(session)`.

**Left panel (`RunnerListPanel`):**
- Adversary section: `AdversaryRunnerSection` (reused — accordion rows)
- Player section: `PlayerRunnerSection` (reused — accordion rows)
- Expanding a row drives the right panel
- Defeated adversaries: dimmed, sorted to bottom
- **Pause** button: calls `session.pause()`, saves, resets `windowMode = .encounterPrep`
- **End Encounter** button: destructive confirm, clears session, resets `windowMode = .encounterPrep`
- Fear tracker: accessible from this panel (popover button or inline display)

**Right panel (`RunnerDetailPanel`):**
- Nothing expanded: empty state / placeholder
- Adversary expanded: read-only `AdversaryStatReference` + `FeatureSectionsView` for the selected slot's adversary
- Player expanded: `PlayerRunnerCard` content (HP/Stress/Armor steppers + conditions) — note: editing player state from the right panel is acceptable since the accordion card in the left panel and the right panel can show complementary information
- Right panel is reference/context; damage/stress actions stay in the left accordion card

---

## Shared Component Requirements

### `AdversaryFilterBar`

**Inputs (bindings):** `searchText: String`, `selectedTier: Int?`, `selectedType: AdversaryType?`

**Controls:**
- Text search field — filters by adversary name (case-insensitive, partial match)
- Tier picker — nil = all tiers; 1–5 for specific tier
- Type filter menu — nil = all types; one of `AdversaryType` cases

**Filtering logic:** All active filters compose with AND. Empty search text + nil tier + nil type = no filter (show all).

**Used by:** `CompendiumSelectorSheet`, `CompendiumAdversaryListPanel`, `CompendiumRootView`, `CompendiumUtilityPanel`

---

### `CompendiumSelectorSheet`

**Init parameters:** `compendium: Compendium`, `contentStore: ContentStore`, `onSelect: (Adversary) -> Void`

**Content:** `AdversaryFilterBar` + filtered adversary list (all sources)

**Behaviors:**
- Tapping an adversary row immediately calls `onSelect(_:)` and dismisses
- "Import DHPack" toolbar button presents file importer; successful import adds pack to compendium without dismissing the sheet
- "Done" button always visible to dismiss without selection

---

### `AdversaryCreatorForm`

**Modes:** create (new local adversary) or edit (existing local adversary)

**Steps:**
1. Identity — name, `AdversaryType` picker, tier (1–5 stepper); reference panel shows 2–3 SRD peers
2. Stats — HP, stress, difficulty, major threshold, severe threshold, evasion; each numeric field shows a soft range indicator (teal = within range, amber = above average, red = outlier) derived from SRD peer stats
3. Attack & Features — attack name, modifier (Int), range (text), damage string; feature list with add/remove (each feature has name, kind: passive/action/reaction, description)
4. Review — full stat card preview matching how the adversary will appear in `AdversaryDetailView`; list of any out-of-range stats (advisory only); Save button

**Validation:**
- Name must be non-empty and unique within local collection (soft error on Save, not on typing)
- Out-of-range stats are surfaced as soft warnings, never as hard blocks
- All fields have defaults based on tier and type

**Save behavior:** calls `contentStore.saveLocalAdversary(_:)` → adversary appears in Local section of compendium views

---

### `DHPackExportSheet`

**Init parameter:** `contentStore: ContentStore` (provides local adversary list)

**Content:** Multi-select list of local adversaries (name + tier + type); "Export Selected" button (disabled when nothing selected)

**Export flow:** assembles `DHPackContent` from selected adversaries → writes to `FileManager.default.temporaryDirectory/<name>.dhpack` → presents `ShareLink` (or `UIActivityViewController` on iOS < 16)

---

## Encounter Session Lifecycle

```
(session created from encounter definition) → phase = .running → EncounterRunnerView / RunnerListPanel
  │
  ├── GM taps Pause
  │     └── session.pause() → SessionStore.save() → return to encounter list/editor
  │           └── encounter row shows "In Progress" badge
  │                 ├── GM taps Resume → session.resume() → re-enter runner
  │                 └── GM taps End (from paused) → SessionStore.delete() + SessionRegistry.clear() → badge gone
  │
  └── GM taps End Encounter (while running)
        └── SessionStore.delete() + SessionRegistry.clear() → return to encounter list/editor
```

Sessions with `phase == .paused` are displayed inline; no launch-time modal needed.

---

## Party Requirements

- **Single party:** one party roster, no switching
- **Hidden members:** `PlayerStore.hiddenPlayerIDs: Set<UUID>` — players in this set are excluded from `activePartyPlayers` and from session snapshots
- **Display:** hidden players shown in party list with distinct style (`eye.slash` icon, grayed); always visible so they can be un-hidden
- **Party management location:** bottom section of the left panel on macOS/iPadOS; bottom section of the encounters mode root view on iOS

---

## Difficulty Indicator

`DifficultyAssessorView` remains in the encounter editor (iOS: fixed to bottom; macOS/iPadOS: fixed to bottom of center column). It consumes `activePartyPlayers` (which excludes hidden members) for party-tier calculations. No change to the underlying `DifficultyBudget` logic.

---

## Content Sources (DHPack)

DHPacks are import/export bundles. They are not editable in place.

| Operation | Where |
|---|---|
| Import DHPack | Compendium selector sheet (all platforms), Compendium root view (iOS), Compendium list panel (macOS/iPadOS) |
| Export local collection | Compendium root view toolbar (iOS), Compendium list panel toolbar (macOS/iPadOS) |
| Remove loaded DHPack | Content Sources management (existing `ContentSourcesView`) |
| View loaded DHPacks | Grouped sections in compendium list views |

---

## Accessibility Identifiers (New and Changed)

| Element | Identifier |
|---|---|
| Root mode toggle | `root.mode-toggle` |
| Encounter row (iOS root) | `root.encounter-row` |
| Party row (iOS root) | `root.party-row` |
| Hide player button | `party.hide-button` |
| Unhide player button | `party.unhide-button` |
| In-progress badge | `library.row.in-progress-badge` |
| Resume button (row) | `library.row.resume-button` |
| Compendium utility panel | `compendium.utility-panel` |
| Adversary filter bar | `compendium.filter-bar` |
| Filter bar search field | `compendium.filter-bar.search` |
| Filter bar tier picker | `compendium.filter-bar.tier` |
| Filter bar type menu | `compendium.filter-bar.type` |
| Compendium selector sheet | `compendium.selector-sheet` |
| Adversary inspector | `compendium.inspector` |
| Adversary creator form | `adversary-creator.form` |
| Creator step indicator | `adversary-creator.step` |
| Creator next button | `adversary-creator.next-button` |
| Creator back button | `adversary-creator.back-button` |
| Creator save button | `adversary-creator.save-button` |
| DHPack export sheet | `dhpack-export.sheet` |
| DHPack export button | `dhpack-export.export-button` |
| Runner list panel | `runner.list-panel` |
| Runner detail panel | `runner.detail-panel` |
| Pause button | `runner.pause-button` |
| Window mode toggle (iPadOS) | `window.mode-toggle` |

---

## macOS and iPadOS Native Design

Full specification in [ADR-0047](decisions/0047-macos-ipados-toolbar-menu-keyboard.md).
This section is the authoritative implementation reference extracted from that ADR.

---

### Inspector (Right Panel)

The right panel is implemented as an AppKit/SwiftUI inspector using `.inspectorTrackingSeparator` and `.toggleInspector`. It is user-hideable.

**Default visibility per mode:**

| Mode | Default | Rationale |
|---|---|---|
| `.encounterPrep` | **Open** | The compendium utility panel is the primary workflow affordance in prep |
| `.compendiumManagement` | **Open** | The adversary inspector is the central detail view in management mode |
| `.runningEncounter` | **Hidden** | Runner list gets full width by default; GM reveals reference panel when needed |

Toggle shortcut: `⌃⌘I` (AppKit `.toggleInspector` built-in). Anchored as trailing-most toolbar item in all modes.

---

### Toolbar Design per Mode

Toolbar items follow mental-model ordering (most-used → left). Use AppKit built-in identifiers where available.

**Fixed items present in all modes:**

- Leading anchor: `.toggleSidebar` + `.sidebarTrackingSeparator`
- Trailing anchor: `.inspectorTrackingSeparator` + `.toggleInspector`

**Encounter Prep — content zone items (contributed by `EncounterEditorView`):**
- Run / Resume button (enabled only when an encounter is open in the center column)

**Compendium Management — content zone items:**
- No additional toolbar items; all management actions (Add, Import, Export) live in the sidebar bottom bar
- `NSSearchToolbarItem` may be added here if global search is desired

**Running Encounter — content zone items:**
- Pause button (`⌘.`)
- End Encounter button (no keyboard shortcut — destructive)
- Fear Tracker button (`FearTrackerButton`)

**iPadOS only — centered item (contributed by `ContentView`):**
- `NSToolbarItemGroup` segmented picker: Encounters | Compendium (mode switch)

---

### Sidebar Bottom Bars

Per Mario Guzmán's sidebar guidelines, actions that create, delete, or modify sidebar content belong in the **sidebar's bottom bar** (`safeAreaBar(edge:alignment:spacing:content:)`), not the toolbar zone.

**`EncounterAndPartyPanel` — Encounter list bottom bar:**
- [+] New Encounter
- [−] Delete selected encounter (enabled when an encounter is selected; confirmation required)

**`EncounterAndPartyPanel` — Party list bottom bar:**
- [+] Add Player → `PlayerForm` sheet
- [−] Remove selected player (confirmation required)

**`CompendiumAdversaryListPanel` — Adversary list bottom bar:**
- [+] Add Adversary → `AdversaryCreatorForm`
- [↓] Import DHPack → file importer
- [↑] Export Local → `DHPackExportSheet`

The sidebar toolbar zone contains only `.toggleSidebar` and `.sidebarTrackingSeparator` — no additional items.

---

### Menu Structure

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

Encounter                                   (top-level menu; actions are contextual)
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
- `CommandMenu("File")` is context-sensitive: checks `AppWindowMode` — creates encounter in `.encounterPrep`, creates adversary in `.compendiumManagement`
- `CommandMenu("Encounter")` uses `CommandMenu("Encounter")`. Items enable/disable based on `encounterSelection` and `AppWindowMode`
- `Run Encounter` / `Resume Encounter` share `⌘R`; only one is enabled at a time
- `EncounterApp.swift` gains a full `Commands` block with `CommandMenu("File")`, `CommandMenu("Encounter")`, `CommandMenu("View")`, and `CommandGroup(replacing:)` entries

---

### Keyboard Shortcuts

| Action | macOS | iPadOS | Notes |
|---|---|---|---|
| New Encounter (encounter mode) | ⌘N | ⌘N | |
| New Adversary (compendium mode) | ⌘N | ⌘N | Same key, different context |
| Delete selected item | ⌫ | ⌫ | Confirmation required |
| Rename selected item | ↩ | ↩ | Opens inline rename or alert |
| Open / edit selected encounter | ⌘↩ | ⌘↩ | Focus center column |
| Run Encounter | ⌘R | ⌘R | Disabled when running; shows Resume label when paused |
| Resume Encounter | ⌘R | ⌘R | Shares key with Run; only one enabled at a time |
| Pause Encounter | ⌘. | ⌘. | Standard Mac "stop" chord |
| End Encounter | — | — | No shortcut — destructive |
| Reset Encounter | — | — | No shortcut — destructive |
| Mode: Encounters | ⌘1 | ⌘1 | |
| Mode: Compendium | ⌘2 | ⌘2 | |
| Toggle Sidebar | ⌃⌘S | ⌃⌘S | AppKit `.toggleSidebar` built-in |
| Toggle Inspector | ⌃⌘I | ⌃⌘I | AppKit `.toggleInspector` built-in |
| Focus search / filter bar | ⌘F | ⌘F | |
| Add Adversary to Encounter | ⌘⇧A | ⌘⇧A | From compendium row or utility panel |
| Import DHPack | ⌘⇧I | — | |
| Settings | ⌘, | — | |

**No shortcut for Fear Tracker** — GM uses pointing device during a run; the Fear popover is the right affordance.
**No shortcuts for End or Reset** — both are destructive; deliberate menu navigation or button tap is the intended path.

**iPadOS hardware keyboard:** All shortcuts above apply. Additionally: arrow keys navigate selected list item; Return opens/renames; Escape dismisses sheets and deselects.

---

### Drag and Drop

- **Source:** Adversary rows in `CompendiumUtilityPanel` (prep mode, right panel)
- **Target:** Adversary list in `EncounterEditorView` (center column)
- **Behavior:** Drop adds the adversary to the encounter (same as tapping the row). Duplicate detection: if already in encounter, ask to add a second slot or do nothing.
- **API:** `draggable(adversary)` on the row; `.dropDestination(for: Adversary.self)` on the list or an explicit drop zone within the adversaries section
- **iPadOS:** Touch drag works with the same SwiftUI API

Drag is not in scope between other panels (no reorder, no drag from runner, etc.).

---

### Window and Panel Constraints

```swift
// WindowGroup content (EncounterApp.swift)
.frame(minWidth: 900, minHeight: 560)

// Sidebar (EncounterAndPartyPanel, CompendiumAdversaryListPanel, RunnerListPanel)
// min 240 pt, max 360 pt

// Inspector (CompendiumUtilityPanel, AdversaryInspectorView, RunnerDetailPanel)
// min 280 pt, max 400 pt
```

---

### Mac Polish Requirements

All interactive controls **must** have a `.help("description")` tooltip modifier.

**State restoration:** Use `@SceneStorage` for `AppWindowMode` and `selectedEncounterID` so the window state persists across launches.

**Dock menu:** Override `applicationDockMenu` to offer:
- "New Encounter" (always)
- "Resume [encounter name]" (only when a paused session exists)

**Spotlight keywords** in `Info.plist` (`MDItemKeywords`):
`daggerheart, encounter, gm, gamemaster, ttrpg, rpg, adversary, combat`

**Credits.rtf** in bundle resources for the standard About window.
