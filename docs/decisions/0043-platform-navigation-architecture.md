# ADR-0043: Platform-Specific Navigation Architecture

**Status:** Accepted
**Date:** 2026-05-03

## Context

This supersedes [ADR-0019](0019-macos-split-view-ios-stack.md) and [ADR-0040](0040-encounters-first-navigation.md).

ADR-0019 established a macOS `NavigationSplitView` / iOS `NavigationStack` split, with the macOS sidebar containing two independent items (Encounters, Party). ADR-0040 made Encounters the default landing destination. Hands-on use exposed three problems:

1. **Mode conflation.** Encounters, party management, compendium browsing, and live running are distinct activities with different information densities. Serving them through a shared sidebar navigation forced constant context-switching rather than mode-switching.
2. **iPad not considered.** ADR-0019 treated iPadOS as equivalent to iOS, placing it on the `NavigationStack` path. A split-view design is better suited to iPadOS's larger canvas and supports a more capable prep workflow.
3. **No first-class run mode.** The encounter runner was a sheet on macOS and a `fullScreenCover` on iOS — both modal overlays. The transition did not communicate the weight of "switching from prep to running a live encounter."

## Decision

Three distinct navigation architectures, one per platform family:

### iOS — `NavigationStack` with toolbar mode toggle

The root screen is a single view containing an encounter list (top) and the party roster (below). A **segmented toolbar control** (Encounters | Compendium) switches the entire root content:

- **Encounters mode:** encounter list + party roster; tapping an encounter pushes to `EncounterEditorView`; from the editor, tapping Run pushes to `EncounterRunnerView`. Both are standard push transitions on the same stack.
- **Compendium mode:** full-screen adversary list with search/filter; create custom adversary, import DHPack, export local collection.

```
NavigationStack
  ├── Root (toggle: Encounters | Compendium)
  │     ├── Encounters: encounter list + party
  │     └── Compendium: adversary list
  └── navigationDestination:
        EncounterDefinition → EncounterEditorView
          └── EncounterSession → EncounterRunnerView
```

The launch-time `ResumePromptView` sheet is retired. Paused sessions are visible inline as "In Progress" badges on the encounter row — no separate modal needed.

### iPadOS — `NavigationSplitView` with segmented toolbar mode switch

A `NavigationSplitView` with `columnVisibility` driven by `AppWindowMode`. Three modes:

| Mode | Left (sidebar) | Center | Right (detail) |
|---|---|---|---|
| Encounter Prep (default) | Encounter list + Party roster | Encounter editor | Compendium utility panel |
| Compendium Management | Adversary list (grouped) | — hidden — | Adversary inspector/editor |
| Running Encounter | Runner rows (adversaries + players) + Pause/End | — hidden — | Selected adversary detail |

Column visibility: `encounterPrep` → `.all` (3 columns); other modes → `.doubleColumn` (sidebar + detail only).

Mode switch: **segmented toolbar control** (`Picker` in toolbar, Encounters | Compendium). Run mode is entered by tapping the Run button in `EncounterEditorView`; it sets `AppWindowMode = .runningEncounter(session)` on `ContentView`.

### macOS — `NavigationSplitView` with menu-driven mode switch

Identical three-mode column structure as iPadOS. Mode switch: **menu command** (`View → Encounters`, `View → Compendium`). Run mode is entered and exited the same way as iPadOS (mode state on ContentView).

## `AppWindowMode` (macOS + iPadOS)

```swift
enum AppWindowMode {
    case encounterPrep
    case compendiumManagement
    case runningEncounter(EncounterSession)
}
```

`ContentView` owns `@State var windowMode: AppWindowMode = .encounterPrep` on the macOS/iPadOS branch. The mode propagates to child views via explicit `init` parameters (ADR-0041).

## Options Considered

- **Three separate navigation roots (rejected):** Clean separation but duplicates structural logic and makes cross-mode state management (e.g. which encounter is selected) harder to coordinate.
- **TabView for all platforms (rejected):** Works for iOS but tab bars on macOS are not idiomatic; tabs do not express the encounter → compendium → run hierarchy.
- **Sheet/fullScreenCover for run mode (prior approach, rejected):** Modal presentations communicate "temporary overlay." Running a live encounter is a first-class mode, not a temporary digression. Mode-swap better communicates the transition.

## Consequences

- `ContentView` is nearly fully rewritten. The macOS/iPadOS branch uses `AppWindowMode`; the iOS branch uses `iOSRootMode` (`.encounters` / `.compendium`).
- The `TabView` structure on iOS is eliminated. `PartyOverviewView` is no longer a tab root; party management moves into the combined root view.
- `ResumePromptView` and `ResumeTarget` are retired.
- The six-variable resume state machine in `ContentView` is replaced by reading `SessionRegistry` for paused sessions and displaying in-progress state inline.
- Shared panel components (`EncounterAndPartyPanel`, `CompendiumUtilityPanel`, `CompendiumAdversaryListPanel`, `AdversaryInspectorView`, `RunnerListPanel`, `RunnerDetailPanel`) are new; they are reused across macOS and iPadOS.
- iOS-specific root views (`EncounterAndPartyRootView`, `CompendiumRootView`) are separate files.
