# ADR-0004: Explicit @MainActor on @Observable classes

**Status:** Accepted
**Date:** 2026-03-21

## Context

With `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (ADR-0002), `@Observable` classes
are implicitly `@MainActor`. However, relying on the implicit behavior makes actor
isolation invisible — it's a build-flag detail rather than something expressed in
the code itself. This becomes a problem when reading code in isolation, in PRs, or
if the build flag ever changes.

## Decision

Explicitly annotate all `@Observable` classes with `@MainActor`:

```swift
@MainActor
@Observable
public final class Compendium { ... }

@MainActor
@Observable
public final class EncounterSession: Identifiable, Hashable { ... }
```

The `OSLog` `Logger` instances inside these classes are declared `private let` (not
`nonisolated`) since they are only accessed from the main actor context.

## Options Considered

- **Rely on implicit isolation (rejected):** Works today under the current build
  flags, but the isolation intent is invisible. Any consumer of the type in a
  different module or build configuration would see unexpected behavior.
- **Explicit @MainActor annotation (chosen):** The type's isolation contract is
  self-documenting. Future Swift Package extraction, code review, and agent
  sessions all see the intent without needing to know the build settings.

## Consequences

- `Compendium` and `EncounterSession` are always `@MainActor`. All mutations and
  reads must occur on the main actor.
- Background work (JSON decoding in `Compendium.load()`) is dispatched to a
  detached task and results are published back to the main actor.
- `nonisolated` conformances (`Hashable`, `Equatable`, `Sendable`) on these types
  are explicitly marked and must not capture actor-isolated state.
