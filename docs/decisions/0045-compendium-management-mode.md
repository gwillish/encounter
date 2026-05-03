# ADR-0045: Compendium Management Mode

**Status:** Accepted
**Date:** 2026-05-03

## Context

This changes the status of [ADR-0025](0025-adversary-creator-difficulty-meter-deferred.md) from deferred to active: adversary creation and compendium management are now in scope.

Previously the compendium was only accessible as a modal sheet (`CompendiumBrowserView`) opened from the encounter builder. This made it purely instrumental — a way to select adversaries for an encounter — with no path to browse, create, or manage content independently. Three capabilities had no home:

1. Creating custom (local) adversaries
2. Importing `.dhpack` files to expand the compendium
3. Exporting a local adversary collection as a `.dhpack` for sharing

## Decision

The compendium is a first-class **mode**, not a sheet. Its implementation differs by platform:

### macOS / iPadOS — 2-panel split

When `AppWindowMode == .compendiumManagement`, `ContentView` collapses to 2 columns (`columnVisibility = .doubleColumn`):

- **Left panel (`CompendiumAdversaryListPanel`):** grouped adversary list — SRD section (read-only), one section per loaded DHPack (read-only), Local section (editable). `AdversaryFilterBar` at top filters across all groups. Toolbar actions: Add Adversary, Import DHPack, Export Local.
- **Right panel (`AdversaryInspectorView`):** for SRD and DHPack adversaries, shows the read-only stat card (same content as `AdversaryDetailView`). For local custom adversaries, adds an Edit button that opens `AdversaryCreatorForm` in edit mode. Empty state when nothing is selected.

macOS mode switch: `View → Compendium` / `View → Encounters` menu commands.
iPadOS mode switch: segmented toolbar control.

### iOS — full-screen list

The root toolbar toggle (Encounters | Compendium) switches the entire root content. In Compendium mode, `CompendiumRootView` fills the screen:

- Adversary list with `AdversaryFilterBar` at top
- Grouped sections: SRD | [DHPack name] per loaded pack | Local
- Toolbar: Import DHPack, Export Local, Add Adversary
- Tapping an adversary row pushes to `AdversaryDetailView`; local adversaries get an Edit button there

### DHPack semantics

**DHPacks are import/export bundles only — they are not editable in place.** A loaded DHPack contributes its adversaries to the compendium as a read-only group. The only operations on a loaded pack are remove (unload from compendium) and refresh (re-fetch if from a remote URL).

The export flow (`DHPackExportSheet`) assembles a new `.dhpack` file from a multi-select of local adversaries and presents it via the system share sheet. The resulting file has no connection to previously loaded packs.

### Custom adversary creation (`AdversaryCreatorForm`)

Multi-step form per the ADR-0025 draft (now implemented):

1. **Identity** — name, adversary type, tier; shows 2-3 SRD peers for reference
2. **Stats** — HP, Stress, Difficulty, Thresholds, Evasion; inline soft range indicators (within range / above average / outlier) based on SRD peers; guidance only, never blocks save
3. **Attack & Features** — attack name, modifier, range, damage string; feature list (add passive/action/reaction)
4. **Review** — full stat card preview; soft out-of-range summary; Save

Local adversaries are stored in the `homebrew/` subdirectory of the content directory (already provisioned by `ContentWriter`). `ContentStore` gains `saveLocalAdversary(_:)` and `deleteLocalAdversary(id:)` methods.

### `AdversaryFilterBar` (shared component)

Stateless view accepting bindings: `searchText: Binding<String>`, `selectedTier: Binding<Int?>`, `selectedType: Binding<AdversaryType?>`. Used by:
- `CompendiumAdversaryListPanel` (macOS/iPadOS)
- `CompendiumRootView` (iOS)
- `CompendiumSelectorSheet` (encounter editor selection context)

### `CompendiumSelectorSheet` (encounter editor context)

The modal used when adding adversaries to an encounter. Distinct from the compendium management views — it is selection-only (no create, no export). An "Import DHPack" button is included so GMs can load new content mid-prep without leaving the context. Replaces `CompendiumBrowserView` as the encounter-editor selection entry point.

## Options Considered

- **Expand `CompendiumBrowserView` sheet to include management (rejected).** A sheet constrained by the builder context would be awkward for a management workflow and wouldn't work at all for the macOS/iPadOS always-visible utility panel.
- **Separate app section / tab for compendium (rejected).** Adding a third tab or sidebar item for compendium management returns to the navigation-list model that ADR-0043 replaces. Mode switching is cleaner.
- **Edit DHPacks in place (rejected).** A DHPack is a portable file format shared between tools. Editing it would create confusion about provenance and break the open/portable intent (Principle 7). Adversaries to be edited must be detached from their pack and saved locally.

## Consequences

- `CompendiumBrowserView` is retired as the selection entry point; `CompendiumSelectorSheet` replaces it. `CompendiumBrowserView` may be kept for the standalone browse-without-select path or merged into the management views.
- Four new view files: `CompendiumAdversaryListPanel`, `AdversaryInspectorView`, `CompendiumRootView`, `AdversaryCreatorForm`, `DHPackExportSheet`.
- `ContentStore` gains `saveLocalAdversary(_:)`, `deleteLocalAdversary(id:)`, and `exportPack(adversaryIDs:) async -> URL`.
- `AdversaryCreatorForm` is opened as a `.sheet` on all platforms. On macOS/iPadOS it can also be opened inline in the detail column when editing an existing local adversary.
- The soft power-validation range indicators (ADR-0025 open question) are derived from the same `DifficultyBudget` pure functions already in place; the stats step queries the compendium for SRD peers of the selected type/tier.
