# ADR-0041: Explicit Dependency Injection for Custom Stores

**Status:** Accepted

## Context

All custom `@Observable` stores (`Compendium`, `EncounterStore`, `SessionRegistry`,
`SessionStore`, `PlayerStore`, `ContentStore`) were injected via SwiftUI's
`@Environment(StoreType.self)` macro. This created three concrete problems:

1. **ViewInspector incompatibility.** ViewInspector v0.10.3 crashes when inspecting any
   view that reads an `@Observable` type via `@Environment`. This blocked unit-level view
   testing for every store-dependent view, forcing 60–90 s XCUITest round-trips to
   validate binding behavior and view structure.

2. **Implicit dependencies.** A view's `@Environment` reads are invisible at the call
   site. Reading the view's initializer gave no indication of what data it required. This
   made it harder to construct test and preview instances and easier to accidentally omit
   an environment injection.

3. **Preview friction.** Previews had to chain multiple `.environment()` calls and, for
   views that async-load data, wait on `.task` closures before anything rendered. Building
   preview-ready state required knowing the full transitive environment graph.

The motivation to change came from issue #95, which targeted tightening the development
loop so that view-level assertions could run in milliseconds without a simulator.

## Decision

Pass all custom `@Observable` store types to views as explicit `init` parameters. The
`@Environment` property wrapper is reserved for system-provided SwiftUI environment values
(`\.dismiss`, `\.scenePhase`, `\.colorScheme`, etc.).

`EncounterApp` is the sole composition root. It holds all stores as `@State` and passes
them to `ContentView` via init. `ContentView` in turn passes each store only to the
children that need it.

Concrete store types are passed directly — no protocol abstractions are introduced. This
is sufficient: ViewInspector tests the view by instantiating it with a real store instance
(often empty or minimally seeded), and previews use `PreviewData` helpers that return
ready-to-use instances.

## Consequences

- Every view file that previously read a custom store from `@Environment` gains explicit
  `let store: StoreType` init parameters. The set of dependencies is visible at the call
  site.
- `EncounterApp.mainContentView` no longer calls `.environment()` for custom stores. All
  six are passed to `ContentView(...)` by name.
- ViewInspector can inspect any view in the project, because no view reads
  `@Environment(ObservableType.self)`.
- Previews use `PreviewData` factory helpers (`PreviewData.compendium()`,
  `PreviewData.encounterStore()`, etc.) defined in a `#if DEBUG` file. No async loading
  or `.environment()` chains are needed in preview blocks.
- The XCUITest suite is unaffected: it tests the running app, which still wires up through
  `EncounterApp`. No test files change as a result of this ADR.
- Container views (`EncounterBuilderView`, `EncounterRunnerView`) have larger initializer
  signatures (5–6 parameters). This is intentional: the explicit list documents the
  complete dependency surface.
