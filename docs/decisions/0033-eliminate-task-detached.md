# ADR-0033: Eliminate Task.detached — use nonisolated async with @concurrent instead

**Status:** Accepted
**Date:** 2026-03-21

## Context

The initial content architecture (ADR-0028) described background I/O work as being
dispatched via `Task.detached` or `nonisolated` async calls. ADR-0004's Consequences
section also referenced "dispatched to a detached task" as the mechanism for running
JSON decoding off the main actor.

`Task.detached` has several correctness problems in a `@MainActor`-default codebase:

- **Breaks structured concurrency.** A detached task is not a child of the spawning
  task. It does not inherit the parent's priority, task-local values, or cancellation
  signal. If the parent is cancelled (e.g. a view disappears), an in-flight detached
  task continues running unobserved.
- **Explicit actor hopping required.** Results must be explicitly marshalled back to
  the main actor via `await MainActor.run { }`, adding boilerplate and making the
  data-flow harder to follow.
- **Hard to test.** Detached tasks run asynchronously outside the test's structured
  scope, requiring `Task.sleep` or similar delays to observe results.

Swift 6.1 introduced `@concurrent` as an explicit, compiler-enforced declaration that
a method runs on the cooperative thread pool rather than the calling actor. This is
exactly what was needed to replace `Task.detached`.

## Decision

**No `Task.detached` anywhere in the codebase.** All background work is performed via
`nonisolated` async methods, annotated with `@concurrent` on Swift 6.1+, called from
`@MainActor` contexts via `await`.

```swift
// Pattern used in ContentFetcher and ContentWriter:
@concurrent
nonisolated public func fetch(source: ContentSource) async throws -> Outcome {
    // Runs on the cooperative thread pool.
    // Caller (ContentStore, @MainActor) simply awaits:
    let outcome = try await fetcher.fetch(source: source)
    // Back on the main actor here — no MainActor.run { } needed.
}
```

The call site on `ContentStore` (`@MainActor`) looks like a normal `await`:

```swift
let outcome = try await fetcher.fetch(source: source)
```

Swift automatically suspends the main actor, runs the `@concurrent` method on the
cooperative thread pool, then resumes on the main actor with the result. Cancellation,
priority, and task-local values are all propagated correctly.

## Options Considered

- **Keep `Task.detached` (rejected):** Breaks structured concurrency. Results require
  explicit marshalling back to the main actor. Cancellation is not propagated.
  Difficult to test reliably.
- **`DispatchQueue.global().async` (rejected):** GCD has no place in a Swift
  Concurrency codebase. Data races are not checked by the compiler.
- **`nonisolated async` without `@concurrent` (acceptable but weaker):** Before Swift
  6.1, `nonisolated async` methods called from `@MainActor` ran on the cooperative
  thread pool as a side-effect of nonisolation, but this was implicit. The `@concurrent`
  annotation makes the intent explicit and is verified at compile time.
- **`@concurrent nonisolated async` (chosen):** Explicit, compiler-verified, structured,
  and cancellation-aware. Requires Swift 6.1+, which matches the project target.

## Consequences

- `ContentFetcher` and `ContentWriter` methods are `@concurrent nonisolated`.
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (ADR-0002) means `nonisolated` is
  required on every member that must not run on the main actor.
- `ContentStore` (`@MainActor`) calls these methods with plain `await`. No
  `Task.detached`, `MainActor.run`, or `DispatchQueue` is used anywhere.
- ADR-0004's Consequences section referenced "dispatched to a detached task." That
  implementation no longer exists; all background dispatch now uses the pattern above.
- `@concurrent` is a Swift 6.1 feature. Deployment targets are iOS 26.2 / macOS 26.2,
  so this is safe.
- If a future contributor sees a need for `Task.detached`, this ADR explains why it
  was removed and what to use instead.
