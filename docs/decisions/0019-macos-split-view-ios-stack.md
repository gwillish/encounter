# ADR-0019: macOS NavigationSplitView, iOS NavigationStack

**Status:** Superseded by [ADR-0043](0043-platform-navigation-architecture.md)
**Date:** 2026-03-17

## Context

The app targets both iPhone and Mac. The initial implementation used
`NavigationStack` on all platforms (push-based navigation). On macOS this
produced a narrow column experience that didn't make good use of the wider
screen, and the detail pane showed blank when no encounter was selected.

## Decision

`ContentView` owns a `selection: EncounterDefinition.ID?` state variable and
renders the appropriate navigation container per platform:

- **macOS:** `NavigationSplitView` with library list in the sidebar and encounter
  builder in the detail column. `EncounterLibraryList` uses plain tappable rows
  (no `NavigationLink`) that update the selection binding.
- **iOS:** `NavigationStack` with push-based navigation. `EncounterLibraryList`
  uses `NavigationLink` + `.navigationDestination` for standard push behavior.

A `ProgressView` is shown in the library while `store.isLoading` is true,
eliminating the blank-state flash on first load.

## Options Considered

- **NavigationStack on all platforms (rejected):** Works on iOS but wastes Mac
  screen real estate. The builder and runner feel cramped in a single column.
- **NavigationSplitView on all platforms (rejected):** Awkward on iPhone — the
  sidebar/detail model doesn't translate well to a small screen.
- **Platform-adaptive split (chosen):** Each platform gets the navigation
  pattern its users expect. Code is conditionally compiled with `#if os(macOS)`.

## Consequences

- `ContentView` is the single owner of `selection` state on macOS; detail pane
  visibility is driven by this binding.
- iOS and macOS share the same model layer and most view components; only the
  navigation container and library list interaction differ.
- The runner (`EncounterRunnerView`) is presented via `navigationDestination`
  on iOS and as a detail column or sheet on macOS.
