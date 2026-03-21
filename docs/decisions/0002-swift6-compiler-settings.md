# ADR-0002: Swift 6 compiler settings and default actor isolation

**Status:** Accepted
**Date:** 2026-03-14

## Context

Swift 6 introduced strict concurrency checking. The project needed a concurrency
posture that prevents data races by default without requiring explicit annotations
on every type.

## Decision

Enable the following build settings:

| Flag | Value |
|---|---|
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | `MainActor` |
| `SWIFT_APPROACHABLE_CONCURRENCY` | `YES` |
| `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` | `YES` (SE-0409) |

All non-isolated code defaults to `@MainActor`. All `@Observable` classes are
explicitly annotated `@MainActor` to make the isolation intent visible rather than
inferred (see ADR-0004). `nonisolated` is only used where specifically required
(e.g., `Hashable` conformances, background-safe helper functions).

## Options Considered

- **Default MainActor isolation (chosen):** Safe by default; model types are either
  Sendable value types or explicitly `@MainActor` classes. Reduces annotation noise.
- **No default isolation:** Every type requires explicit actor annotation or
  `nonisolated`. More verbose, more opportunity for omission.
- **Strict Swift 6 without approachable concurrency:** Maximum safety but more
  migration friction for early-stage development.

## Consequences

- Model types must be either Sendable value types (structs/enums — preferred for
  catalog data) or explicitly `@MainActor @Observable` classes.
- `nonisolated` is a deliberate exception that requires justification.
- `Hashable` conformances on `@MainActor` types use `nonisolated` for `==` and
  `hash(into:)` since equality and hashing must not require actor context.
- Future Swift Package extraction of model types must account for these isolation
  requirements.
