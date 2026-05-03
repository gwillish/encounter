# Encounter UX Redesign — Implementation Plans

## Context

The prototype has exposed fundamental navigation and mode-mixing problems. The app conflates creator and executor workflows, uses a generic cross-platform layout rather than platform-native patterns, and lacks a first-class encounter lifecycle (pause/resume/end). This plan rebuilds the UX layer from documented decisions while preserving the working model and services layer.

Design decisions recorded during planning session (2026-05-03):
- macOS/iPadOS compendium mode: 2-panel collapse (adversary list | detail/inspector)
- macOS run mode: same-window mode swap (no new window)
- Player hide: global party flag (roster-wide, not per-encounter)
- Custom adversary creation: full multi-step form (ADR-0025 draft)
- DHPacks are import/export bundles only — not editable in place

---

## Platform Architecture

### Shared concept: `AppWindowMode` (macOS + iPadOS)

```swift
enum AppWindowMode {
    case encounterPrep                         // 3-panel
    case compendiumManagement                  // 2-panel
    case runningEncounter(EncounterSession)    // 2-panel
}
```

`NavigationSplitView` column visibility changes with mode:
- `.encounterPrep` → `columnVisibility = .all` (3 columns)
- `.compendiumManagement` / `.runningEncounter` → `columnVisibility = .doubleColumn` (sidebar + detail only)

### macOS layout per mode

| Mode | Left (sidebar) | Center | Right (detail) |
|---|---|---|---|
| Encounter Prep | Encounter list + Party list | Encounter editor | Compendium utility panel |
| Compendium Management | Adversary list (grouped) | — hidden — | Adversary inspector/editor |
| Running Encounter | Adversary runner rows + Player section + Pause/End | — hidden — | Selected adversary detail |

Mode switch: **menu command** (`View → Compendium` / `View → Encounters`)

### iPadOS layout per mode

Same 3-panel structure as macOS. Mode switch: **segmented toolbar control** (Encounters | Compendium).

Run mode is triggered by a "Run" button in the encounter editor toolbar; the window transitions in place (same as macOS).

### iOS layout

Root view is a single `NavigationStack`. The root screen has a **segmented toolbar toggle** (Encounters | Compendium):

- **Encounters mode** — encounter list (top) + party list (below); tapping a row pushes to the encounter editor; run affordance pushes to run mode
- **Compendium mode** — adversary list (full screen); searchable/filterable; create custom adversary, import DHPack, export local collection

Push hierarchy:
```
NavigationStack
  Root (Encounters|Compendium toggle)
    └── EncounterEditorView        ← push from encounter row
          └── EncounterRunnerView  ← push from Run button
```

---

## Model Changes Required

These must land before any platform work begins.

### 1. `SessionPhase` — DHKit package update (gwillish/DHModels)

Add to `EncounterSession`:
```swift
public enum SessionPhase: String, Codable { case running, paused }
public var phase: SessionPhase = .running
```

`SessionStore` must persist and restore `phase`. The resume prompt and in-progress indicators read `phase == .paused`.

### 2. Player `isHidden` — app-level, `PlayerStore`

Add `hiddenPlayerIDs: Set<UUID>` as a persisted property on `PlayerStore` (JSON file alongside `party.json`). Update `activePartyPlayers` to filter out hidden IDs. Add `hidePlayer(id:)` / `showPlayer(id:)` methods.

This avoids modifying the DHKit `Player` type while cleanly modelling the roster-level flag.

### 3. Encounter in-progress state — `EncounterLibraryRow`

`SessionRegistry` already keys sessions by `EncounterDefinition.ID`. Pass `isPaused: Bool` to `EncounterLibraryRow` (derived from `SessionRegistry` in the parent). Show a visual indicator when a paused session exists for the row's definition. Change the run affordance label: "Run" → "Resume".

---

## New Shared Components

These components are platform-agnostic and consumed on all three platforms.

| Component | Purpose |
|---|---|
| `AdversaryFilterBar` | Text search + tier picker + type filter menu; accepts bindings, emits filter state |
| `CompendiumSelectorSheet` | Modal adversary selector: parameterized search, add-to-encounter callback, import DHPack button |
| `AdversaryCreatorForm` | Multi-step form: Identity → Stats → Attack & Features → Review (ADR-0025 draft) |
| `DHPackExportSheet` | Multi-select list of local adversaries → export as `.dhpack` via system share sheet |
| `SessionLifecycleButton` | Reusable Pause / End button component used in runner panels on all platforms |

---

## Milestone 0: Documentation and ADRs

Write before implementation begins. These record decisions made in this planning session and guide all downstream work.

**ADRs to write:**

| ADR | Title | Supersedes |
|---|---|---|
| 0043 | Platform-specific navigation architecture | ADR-0019, ADR-0040 |
| 0044 | Encounter session lifecycle (running / paused / ended) | — |
| 0045 | Compendium management mode | ADR-0025 (changes deferred status) |
| 0046 | Single party with hidden member flag | — |
| 0047 | macOS/iPadOS toolbar, menu structure, inspector, and keyboard model | — |

**Update status lines (one-line edit only):**
- `docs/decisions/0019-macos-split-view-ios-stack.md` → `Superseded by [ADR-0043](0043-platform-navigation-architecture.md)`
- `docs/decisions/0040-encounters-first-navigation.md` → `Superseded by [ADR-0043](0043-platform-navigation-architecture.md)`

**New docs to write:**
- `docs/ux-requirements.md` — per-platform requirements derived from this plan; canonical reference for screen structure and interaction patterns
- Update `docs/ui-vocabulary.md` — replace navigation map, update screen reference table, add new component glossary entries
- `docs/first-principles.md` — add Principle 12 superseding Principle 9: iOS, iPadOS, and macOS are all first-class platform targets with distinct navigation idioms; visionOS is a supported build target but receives no platform-specific design work

**Issues for this milestone:**
- [x] Write ADR-0043 (navigation architecture)
- [x] Write ADR-0044 (session lifecycle)
- [x] Write ADR-0045 (compendium management mode)
- [x] Write ADR-0046 (party hidden member flag)
- [x] Write ADR-0047 (macOS/iPadOS toolbar, menu, inspector, keyboard)
- [x] Update superseded status on ADR-0019 and ADR-0040
- [x] Write `docs/ux-requirements.md`
- [x] Update `docs/ui-vocabulary.md`
- [x] Add Principle 12 to `docs/first-principles.md`

---

## Milestone 1: Foundation — Model and Shared Infrastructure

All platform work depends on this milestone.

### 1a. DHKit: `SessionPhase`

- **Test first:** `SessionStoreTests` — verify `phase` round-trips through save/load; verify `paused` sessions are not presented to the runner without explicit resume action
- Add `SessionPhase` enum and `phase` property to `EncounterSession` in DHKit (package PR)
- Update `SessionStore.save(_:)` and `SessionStore.load(into:)` to persist `phase`
- Add `pause()` and `resume()` methods on `EncounterSession` that set `phase`

### 1b. App: `PlayerStore` hidden player support

Critical files: `Encounter/Services/PlayerStore.swift`

- **Test first:** `PlayerStoreTests` — hidden player excluded from `activePartyPlayers`; hide/show round-trips through persistence; deleting a player also removes from `hiddenPlayerIDs`
- Add `private(set) var hiddenPlayerIDs: Set<UUID>` to `PlayerStore`
- Add `hidePlayer(id:) async` and `showPlayer(id:) async`
- Update `activePartyPlayers` to filter hidden IDs
- Persist `hiddenPlayerIDs` to `<directory>/hidden-players.json`

### 1c. `EncounterLibraryRow` in-progress indicator

Critical files: `Encounter/Views/EncounterLibraryRow.swift`

- **Test first:** `EncounterLibraryRowTests` — row with a paused session shows indicator; row without session does not
- Pass `isPaused: Bool` into `EncounterLibraryRow` (derived from `SessionRegistry` in the parent)
- Show a capsule badge ("In Progress") and change run button label to "Resume"

### 1d. Shared `AdversaryFilterBar`

New file: `Encounter/Views/AdversaryFilterBar.swift`

- **Test first:** `AdversaryFilterBarTests` — text search filters by name; tier picker filters by tier; type menu filters by type; combined filters compose with AND
- Stateless: accepts bindings `searchText`, `selectedTier`, `selectedType`; renders search field + filter controls
- Used by `CompendiumSelectorSheet`, `CompendiumAdversaryListPanel`, and `CompendiumRootView`

### 1e. `CompendiumSelectorSheet`

New file: `Encounter/Views/CompendiumSelectorSheet.swift`

- **Test first:** `CompendiumSelectorSheetTests` — shows `AdversaryFilterBar`; adversary row tap calls `onSelect`; import DHPack button present
- Props: `compendium: Compendium`, `contentStore: ContentStore`, `onSelect: (Adversary) -> Void`
- Contains `AdversaryFilterBar` + filtered adversary list
- "Import DHPack" toolbar button calls `contentStore.importPack(from:)` via file importer
- Replaces `CompendiumBrowserView` as the selection-mode entry point from the encounter editor

**Issues for this milestone:**
- [ ] DHKit PR: add `SessionPhase`, `pause()`, `resume()` to `EncounterSession`
- [ ] App: update `SessionStore` to persist `SessionPhase` (save/load round-trip)
- [ ] `PlayerStore`: `hiddenPlayerIDs` persistence + hide/show methods
- [ ] `EncounterLibraryRow`: in-progress indicator + resume label
- [ ] `AdversaryFilterBar` shared component
- [ ] `CompendiumSelectorSheet` shared component

---

## Holistic Plan: iOS Redesign

**Goal:** Single `NavigationStack` root with toolbar mode toggle. Encounters + party co-located on root screen. Push navigation through edit → run. Full pause/resume/end lifecycle. No tabs.

**Replaces:** `ContentView` iOS branch, `TabView`, `EncounterLibraryView` as root, `PartyOverviewView` as a tab

### Milestone 2: iOS Root View Redesign

#### 2a. `EncounterAndPartyRootView` (new)

New file: `Encounter/Views/EncounterAndPartyRootView.swift`

- **Test first:** `EncounterAndPartyRootViewTests` — encounter list visible; party list visible below; segmented toolbar toggle present; switching to compendium replaces list content
- Top section: scrollable encounter list (reuses `EncounterLibraryList`); each row has name, in-progress badge, run/resume affordance button
- Bottom section: party member list (add/delete/hide controls); hidden members shown with a distinct style (grayed, `eye.slash` icon) with unhide affordance
- Toolbar: centered `Picker` segmented control (Encounters | Compendium)
- State: `@State var rootMode: iOSRootMode` where `iOSRootMode` is `.encounters` or `.compendium`

#### 2b. `CompendiumRootView` (new, iOS)

New file: `Encounter/Views/CompendiumRootView.swift`

- **Test first:** `CompendiumRootViewTests` — adversary list visible; `AdversaryFilterBar` present; DHPack import button present; export button present
- Full-screen adversary list; `AdversaryFilterBar` at top
- Grouped sections: SRD | [DHPack name] | Local
- Toolbar: "Import DHPack" (file importer), "Export Local" (→ `DHPackExportSheet`), "Add Adversary" (→ `AdversaryCreatorForm`)
- Tapping adversary row pushes to `AdversaryDetailView`

#### 2c. Update `ContentView` iOS branch

Critical file: `Encounter/ContentView.swift`

Replace the `TabView` iOS branch with a `NavigationStack` wrapping `EncounterAndPartyRootView`. The stack's `navigationDestination` bindings cover:
- `EncounterDefinition` → `EncounterEditorView`
- `EncounterSession` → `EncounterRunnerView`
- `Adversary` → `AdversaryDetailView`

Simplify resume state: replace the 6-variable resume state machine with paused sessions visible inline in the encounter list. `ResumePromptView` is retired.

**Issues for this milestone:**
- [ ] `EncounterAndPartyRootView`: encounter list + party section + toolbar toggle
- [ ] `CompendiumRootView`: adversary list with filter, grouped sections, import/export
- [ ] `ContentView` iOS branch: replace TabView with NavigationStack, simplify resume state
- [ ] Retire `ResumePromptView`, `PartyOverviewView` (iOS tab usage)

### Milestone 3: iOS Encounter Editor and Run Mode

#### 3a. `EncounterEditorView` (rename/update from `EncounterBuilderView`)

Critical file: `Encounter/Views/EncounterBuilderView.swift`

- **Test first:** `EncounterEditorViewTests` — Run button shown when no session; Resume button shown when paused session exists; "Browse Compendium" opens `CompendiumSelectorSheet` (not `CompendiumBrowserView`)
- Replace `.fullScreenCover` runner presentation with `NavigationLink` push
- Replace `CompendiumBrowserView` sheet with `CompendiumSelectorSheet` sheet
- `DifficultyAssessorView` remains fixed to bottom

#### 3b. `EncounterRunnerView` pause/resume/end lifecycle

Critical file: `Encounter/Views/EncounterRunnerView.swift`

- **Test first:** `EncounterRunnerViewTests` — Pause button calls `session.pause()`; End button calls `store.clearSession(for:)`; paused session persists in `SessionStore`
- Add "Pause" toolbar/nav button that calls `session.pause()`, saves via `SessionStore`, then pops navigation
- "End Encounter" existing button clears session entirely
- No change to the accordion runner list or player section

**Issues for this milestone:**
- [ ] `EncounterEditorView`: replace `.fullScreenCover` runner presentation with `NavigationLink` push
- [ ] `EncounterEditorView`: replace `CompendiumBrowserView` sheet with `CompendiumSelectorSheet` (depends on M1e)
- [ ] `EncounterEditorView`: show Resume label and behavior when a paused session exists (depends on M1a + M1c)
- [ ] `EncounterRunnerView`: Pause action + session lifecycle wiring

---

## Holistic Plan: iPadOS and macOS Redesign

iPadOS and macOS share the `AppWindowMode` state machine and the same three-panel/two-panel `NavigationSplitView` structure. They share all panel components. iPadOS gets the segmented toolbar control; macOS gets menu commands.

### Milestone 4: macOS/iPadOS — Encounter Prep (3-panel)

#### 4a. `AppWindowMode` and updated `ContentView` macOS/iPadOS branch

Critical file: `Encounter/ContentView.swift`

- **Test first:** `AppWindowMode` transitions; `columnVisibility = .all` in prep mode; `columnVisibility = .doubleColumn` in compendium/run mode
- Replace the current `NavigationSplitView` sidebar (2-item list) with the new 3-panel structure keyed on `AppWindowMode`
- Mode switch for iPadOS: `Picker` segmented in toolbar
- Mode switch for macOS: `Commands` menu (`View → Encounters`, `View → Compendium`)

#### 4b. `EncounterAndPartyPanel` (new, sidebar — encounter prep mode)

New file: `Encounter/Views/EncounterAndPartyPanel.swift`

- **Test first:** encounter list shows in-progress badges; party section below with hide/unhide
- Encounter list (top): rows with name, in-progress badge, "Run"/"Resume" button per row
- Party section (bottom): player list, add/delete, hide/unhide affordances
- Selection drives the center column (`EncounterEditorView`)

#### 4c. `CompendiumUtilityPanel` (new, detail column — encounter prep mode)

New file: `Encounter/Views/CompendiumUtilityPanel.swift`

- **Test first:** `AdversaryFilterBar` visible; filtered list shows; tapping adversary adds to encounter via callback
- Right utility panel — always visible in encounter prep mode; replaces the Browse Compendium sheet button
- Accepts `onSelect: (Adversary) -> Void` callback
- Contains `AdversaryFilterBar` + filtered adversary list; tapping a row calls `onSelect` immediately
- "Import DHPack" button at bottom

#### 4d. Update `EncounterEditorView` for macOS/iPadOS

- Hide the "Browse Compendium" sheet button when on macOS/iPadOS (right panel replaces it)
- `DifficultyAssessorView` stays

#### 4e. Toolbar, Commands, and Keyboard (macOS/iPadOS)

Per ADR-0047.

- **Test first:** `CommandsTests` — `⌘N` creates encounter in prep mode; `⌘1`/`⌘2` switch modes; `⌘R` enables when encounter selected and no running session; `⌘.` only enabled when session running
- Add full `Commands` block in `EncounterApp.swift`: `CommandMenu("File")`, `CommandMenu("Encounter")`, `CommandMenu("View")`, `CommandGroup(replacing: .newItem)`, `CommandGroup(replacing: .appInfo)`
- `⌘N` context-sensitive: checks `AppWindowMode`
- `⌘R` Run/Resume context-sensitive: enabled and labeled based on session state
- `⌘.` Pause: enabled only while `.runningEncounter`
- `⌘1`/`⌘2` mode switch
- `⌃⌘S` / `⌃⌘I` sidebar/inspector toggles (AppKit built-ins; also hooked in `View` menu)
- iPadOS: `NSToolbarItemGroup` segmented mode picker centered in toolbar

#### 4f. Inspector toggle defaults and sidebar bottom bars

Per ADR-0047.

- **Test first:** inspector open by default in prep mode; sidebar bottom bars render correct action buttons per section
- Right panel implemented as inspector: `.inspectorTrackingSeparator` + `.toggleInspector`; default open in `.encounterPrep`
- `EncounterAndPartyPanel`: encounter list bottom bar ([+] New, [−] Delete); party list bottom bar ([+] Add Player, [−] Remove)
- All bottom bars use `safeAreaBar(edge:alignment:spacing:content:)`
- Toolbar zone: only `.toggleSidebar` + `.sidebarTrackingSeparator` (no action buttons in toolbar zone)

#### 4g. Run button in encounter prep toolbar

- Toolbar content zone (contributed by `EncounterEditorView`): Run / Resume button enabled only when an encounter is selected in the center column
- Wired to the same `windowMode = .runningEncounter(session)` transition as the in-row button

#### 4h. Drag and drop: CompendiumUtilityPanel → EncounterEditorView

Per ADR-0047.

- **Test first:** `DragDropTests` — dragging an adversary row from the utility panel and dropping on the encounter adversary list calls `onSelect`; duplicate adversary triggers confirmation
- `draggable(adversary)` on adversary rows in `CompendiumUtilityPanel`
- `.dropDestination(for: Adversary.self)` on the adversary list section in `EncounterEditorView`
- Duplicate detection: ask to add second slot or do nothing

#### 4i. Window constraints and state restoration

Per ADR-0047.

- `WindowGroup` content: `.frame(minWidth: 900, minHeight: 560)`
- Sidebar min 240 pt, max 360 pt; inspector min 280 pt, max 400 pt
- `@SceneStorage` for `AppWindowMode` and `selectedEncounterID` in `ContentView` (macOS/iPadOS branch)

#### 4j. Tooltips on all interactive controls (prep mode)

- Add `.help("…")` to every toolbar button, sidebar bottom bar button, and condition toggle in prep-mode views
- Tooltip text follows: verb + noun pattern (e.g. "Add a new encounter", "Delete selected encounter")

#### 4k. Mac polish: Dock menu, Spotlight keywords, Credits.rtf

- `EncounterApp.swift` / `AppDelegate`: override `applicationDockMenu` — offer "New Encounter" always; "Resume [name]" when a paused session exists in `SessionRegistry`
- `Info.plist`: add `MDItemKeywords` = `daggerheart, encounter, gm, gamemaster, ttrpg, rpg, adversary, combat`
- Add `Credits.rtf` to bundle resources (Copy Bundle Resources build phase)

**Issues for this milestone:**
- [ ] `AppWindowMode` enum + `NavigationSplitView` 3-panel structure + column visibility transitions in `ContentView`
- [ ] iPadOS segmented toolbar mode picker (`NSToolbarItemGroup` centered in toolbar, `ContentView`)
- [ ] `EncounterAndPartyPanel` sidebar (prep mode)
- [ ] `CompendiumUtilityPanel` right panel (prep mode)
- [ ] `EncounterEditorView` conditional Browse button suppression on macOS/iPadOS
- [ ] `Commands` block in `EncounterApp.swift`: File menu, Encounter menu, View menu + all keyboard shortcuts (ADR-0047)
- [ ] Inspector toggle wiring: `.inspectorTrackingSeparator` + `.toggleInspector`; open by default in prep mode
- [ ] Sidebar bottom bars: `EncounterAndPartyPanel` (encounter list section + party section)
- [ ] Run button in encounter prep toolbar (contributed by `EncounterEditorView`)
- [ ] Drag and drop: `CompendiumUtilityPanel` rows → `EncounterEditorView` adversary list
- [ ] Window and panel size constraints: min window 900×560pt, sidebar 240–360pt, inspector 280–400pt
- [ ] `@SceneStorage` state restoration for `AppWindowMode` and `selectedEncounterID`
- [ ] Tooltips (`.help()`) on all prep-mode interactive controls
- [ ] Mac polish: Dock menu override, Spotlight keywords (`Info.plist`), `Credits.rtf` in bundle

### Milestone 5: macOS/iPadOS — Compendium Management Mode (2-panel)

#### 5a. `CompendiumAdversaryListPanel` (new, sidebar — compendium mode)

New file: `Encounter/Views/CompendiumAdversaryListPanel.swift`

- **Test first:** SRD group visible; DHPack groups visible; Local group visible; `AdversaryFilterBar` filters all groups
- Grouped `List`: SRD | [DHPack name] per loaded pack | Local
- `AdversaryFilterBar` at top (filters across all groups)
- Selection drives `AdversaryInspectorView`
- "Add Adversary" (+) button → `AdversaryCreatorForm`; "Import DHPack" → file importer; "Export Local" → `DHPackExportSheet`

#### 5b. `AdversaryInspectorView` (new, detail — compendium mode)

New file: `Encounter/Views/AdversaryInspectorView.swift`

- **Test first:** SRD adversary shows read-only detail; local adversary shows edit controls; no selection shows empty state
- SRD/DHPack adversaries: read-only stat card
- Local adversaries: adds Edit button → `AdversaryCreatorForm` in edit mode
- No "Add to Encounter" button (this is management mode, not selection mode)

#### 5c. Sidebar bottom bar and inspector toggle for compendium mode

Per ADR-0047.

- `CompendiumAdversaryListPanel` bottom bar: [+] Add Adversary, [↓] Import DHPack, [↑] Export Local (enabled when local adversaries exist)
- Inspector default: **open** in `.compendiumManagement`
- All bottom bar buttons have `.help("…")` tooltips

**Issues for this milestone:**
- [ ] `CompendiumAdversaryListPanel` with grouped sections + filter + bottom bar actions (Add, Import, Export)
- [ ] `AdversaryInspectorView` with read-only and edit paths
- [ ] Inspector open by default in compendium mode
- [ ] Tooltips on all compendium-mode interactive controls

### Milestone 6: macOS/iPadOS — Run Mode (2-panel)

#### 6a. `RunnerListPanel` (new, sidebar — run mode)

New file: `Encounter/Views/RunnerListPanel.swift`

- **Test first:** adversary rows sorted (defeated at bottom); player section below; accordion selection drives the right panel
- Adversary section: `AdversaryRunnerSection` (reused)
- Player section: `PlayerRunnerSection` (reused)
- Expanded accordion selection drives the right panel
- Pause and End controls live in the window toolbar (see 6d), not in this panel

#### 6b. `RunnerDetailPanel` (new, detail — run mode)

New file: `Encounter/Views/RunnerDetailPanel.swift`

- **Test first:** selected adversary stats visible; no adversary selected shows placeholder
- Shows `AdversaryStatReference` and `FeatureSectionsView` for expanded adversary
- Read-only reference — damage/stress controls remain in the left accordion card
- Players show `PlayerRunnerCard` content when a player row is expanded

#### 6c. Run mode activation and deactivation

Critical file: `Encounter/ContentView.swift` (macOS/iPadOS branch)

- **Test first:** Run button sets `windowMode = .runningEncounter(session)`; Pause resets to `.encounterPrep`; End clears session and resets to `.encounterPrep`
- Run button in `EncounterEditorView` calls `windowMode = .runningEncounter(session)` via callback/binding (ADR-0041)

#### 6d. Toolbar in run mode and inspector toggle

Per ADR-0047.

- Toolbar content zone (contributed when `windowMode == .runningEncounter`): Pause (`⌘.`), End Encounter (no shortcut), Fear Tracker button
- Inspector default: **hidden** in `.runningEncounter`; user can reveal adversary reference panel via `⌃⌘I`
- Pause and End toolbar buttons are the authoritative controls; remove any Pause/End from the `RunnerListPanel` header (they move to the toolbar)
- All run-mode toolbar and panel controls have `.help("…")` tooltips

**Issues for this milestone:**
- [ ] `RunnerListPanel` with adversary + player sections (Pause/End controls removed — they are in the toolbar)
- [ ] `RunnerDetailPanel` for adversary/player detail in split
- [ ] Run mode activation/deactivation wired through `AppWindowMode`
- [ ] Run mode toolbar items: Pause, End, Fear Tracker (contributed by mode switch)
- [ ] Inspector hidden by default in run mode
- [ ] Tooltips on all run-mode interactive controls

---

## Holistic Plan: Compendium Management Features

Shared across all platforms. Builds on compendium mode views from Milestones 2 and 5.

### Milestone 7: Custom Adversary Creation (`AdversaryCreatorForm`)

Multi-step form per ADR-0025 draft. Local adversaries saved in `homebrew/` directory (already provisioned by `ContentWriter`).

#### Step structure
1. **Identity** — name, type (AdversaryType picker), tier (1–5); surfaces 2-3 SRD peers for stat reference
2. **Stats** — HP, Stress, Difficulty, Thresholds (Major/Severe), Evasion; inline soft-range indicators per field (within range / above average / outlier) based on SRD peers; guidance only, never blocks save
3. **Attack & Features** — attack name, modifier, range, damage string; feature list (add passive/action/reaction)
4. **Review** — full stat card preview; soft out-of-range summary; Save

New file: `Encounter/Views/AdversaryCreatorForm.swift`

- **Test first:** each step renders; Next/Back navigation; Save on review persists to `ContentStore`; out-of-range field shows warning label; duplicate name validation
- Opened as `.sheet` on all platforms; on macOS/iPadOS also used inline in detail column for existing local adversaries
- Edit mode: pre-fills all steps with existing local adversary data

**Issues for this milestone:**
- [ ] `ContentStore`: `saveLocalAdversary(_:)` and `deleteLocalAdversary(id:)` methods (unblocks all form steps)
- [ ] `AdversaryCreatorForm` step 1: Identity + reference panel
- [ ] `AdversaryCreatorForm` step 2: Stats + soft range indicators
- [ ] `AdversaryCreatorForm` step 3: Attack & features list
- [ ] `AdversaryCreatorForm` step 4: Review + save to local source
- [ ] Edit mode: pre-fill from existing local adversary

### Milestone 8: DHPack Export

New file: `Encounter/Views/DHPackExportSheet.swift`

- **Test first:** local adversaries listed; multi-select toggles; Export button disabled when nothing selected; tapping Export invokes system share sheet
- Lists all local custom adversaries with checkboxes
- "Export Selected" → assembles `DHPackContent` → writes temporary `.dhpack` → presents `ShareLink`

**Issues for this milestone:**
- [ ] `DHPackExportSheet` with multi-select and share sheet integration
- [ ] `ContentStore`: `exportPack(adversaryIDs:) async -> URL` helper method

---

## Critical Files

| File | Change |
|---|---|
| `Encounter/ContentView.swift` | Near-complete rewrite of both platform branches |
| `Encounter/Views/EncounterBuilderView.swift` | Push nav, CompendiumSelectorSheet, Resume mode |
| `Encounter/Views/EncounterRunnerView.swift` | Add Pause action, lifecycle wiring |
| `Encounter/Views/EncounterLibraryRow.swift` | In-progress badge, Resume label |
| `Encounter/Services/PlayerStore.swift` | `hiddenPlayerIDs`, hide/show methods |
| `Encounter/Services/SessionStore.swift` | Persist `SessionPhase` |
| DHKit `EncounterSession` | Add `SessionPhase`, `pause()`, `resume()` |

**New files:**
```
Encounter/Views/EncounterAndPartyRootView.swift    (iOS)
Encounter/Views/CompendiumRootView.swift           (iOS)
Encounter/Views/EncounterAndPartyPanel.swift       (macOS/iPadOS sidebar)
Encounter/Views/CompendiumUtilityPanel.swift       (macOS/iPadOS right — prep mode)
Encounter/Views/CompendiumAdversaryListPanel.swift (macOS/iPadOS sidebar — compendium mode)
Encounter/Views/AdversaryInspectorView.swift       (macOS/iPadOS right — compendium mode)
Encounter/Views/RunnerListPanel.swift              (macOS/iPadOS sidebar — run mode)
Encounter/Views/RunnerDetailPanel.swift            (macOS/iPadOS right — run mode)
Encounter/Views/AdversaryFilterBar.swift           (shared)
Encounter/Views/CompendiumSelectorSheet.swift      (shared)
Encounter/Views/AdversaryCreatorForm.swift         (shared)
Encounter/Views/DHPackExportSheet.swift            (shared)
```

**Files retired (delete after replacement is in place):**
```
Encounter/Views/ResumePromptView.swift
Encounter/Views/ResumeTarget.swift
```

---

## GitHub Milestones

```
Milestone 0: Documentation & ADRs
Milestone 1: Foundation — Model and Shared Infrastructure
Milestone 2: iOS Root View Redesign
Milestone 3: iOS Encounter Editor and Run Mode
Milestone 4: macOS/iPadOS — Encounter Prep (3-panel)
Milestone 5: macOS/iPadOS — Compendium Management Mode
Milestone 6: macOS/iPadOS — Run Mode
Milestone 7: Custom Adversary Creation
Milestone 8: DHPack Export
```

Dependency order: Milestone 1 → all others. Milestones 2–3 (iOS) and 4–6 (macOS/iPadOS) can proceed in parallel after Milestone 1. Milestones 7–8 follow all platform milestones.

---

## TDD Approach

Each view and service follows the **red → green** cycle:

1. Write the Swift Testing `@Test` that exercises the new behaviour
2. Run `xcodebuild test -scheme Encounter -destination 'platform=macOS'` → confirm red
3. Implement the minimum code to pass
4. Run tests again → green
5. `swift-format format --recursive --in-place Encounter/`
6. Commit

View tests use ViewInspector for structure/binding assertions. Model tests use Swift Testing directly. UIKit-requiring flows use XCUITest (`-testPlan AllTests`).

---

## Verification per Milestone

- **After Milestone 1:** `SessionStoreTests` phase round-trip; `PlayerStoreTests` hide/show; `EncounterLibraryRowTests` badge
- **After Milestones 2–3 (iOS):** XCUITest — launch → encounter list → push editor → run → pause → in-progress badge → resume → end
- **After Milestones 4–6 (macOS/iPadOS):** macOS XCUITest — launch → 3-panel → select encounter → add adversary from right panel → run → pause → compendium mode → browse
- **After Milestones 7–8:** XCUITest — create local adversary → add to encounter → export as DHPack → import DHPack
