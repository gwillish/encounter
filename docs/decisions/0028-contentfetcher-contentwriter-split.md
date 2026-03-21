# ADR-0028: ContentFetcher and ContentWriter as single-responsibility nonisolated structs

**Status:** Accepted
**Date:** 2026-03-21

## Context

`ContentStore` is a `@MainActor @Observable` coordinator. Its two heaviest
operations — URLSession fetching and file system I/O — must not run on the
main thread. Putting all three responsibilities (coordination, fetching,
writing) in one class makes unit testing difficult: testing fetch logic
requires a live file system, and testing write logic requires a live network.

## Decision

Split into three types with distinct responsibilities:

| Type | Isolation | Responsibility |
|---|---|---|
| `ContentStore` | `@MainActor @Observable` | Coordination, state, Compendium reload |
| `ContentFetcher` | `nonisolated` struct | URLSession fetch, ETag conditional GET, SHA-256 fingerprint, decode |
| `ContentWriter` | `nonisolated` struct | Atomic file writes, SRD seeding, source index persistence |

`ContentFetcher` and `ContentWriter` are value types (`struct`) with no mutable
state. All their methods are `nonisolated` and run on the cooperative thread
pool. `ContentStore` holds instances of both and delegates to them via
`Task.detached` or `nonisolated` async calls.

```swift
@MainActor @Observable
public final class ContentStore {
    private let fetcher: ContentFetcher
    private let writer:  ContentWriter
    // …
}
```

## Options Considered

- **Monolithic ContentStore (rejected):** All logic in one `@MainActor` class.
  Background work must be explicitly dispatched via `Task.detached`. Testing
  requires mocking both URLSession and FileManager from a single surface.
- **ContentFetcher + ContentWriter split (chosen):** Each type has one reason
  to change. `ContentFetcher` can be tested against a mock URLSession without
  touching the file system. `ContentWriter` can be tested with a temp directory
  without a network. `ContentStore` tests focus on coordination logic only.

## Consequences

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (ADR-0002) means all properties
  and methods on these structs are `@MainActor` by default. Every member that
  must run off the main thread requires an explicit `nonisolated` annotation.
  This is a known consequence of the flag and is the load-bearing reason why
  the `nonisolated` keywords in `ContentFetcher` and `ContentWriter` are not
  optional.
- `ContentFetcher` uses `URLSession.shared` (default session) with async/await,
  consistent with ADR-0018 (user-initiated fetch). Background `URLSession`
  delegate-based sessions are incompatible with async/await and are not used.
- `ContentWriter` uses a temp-file-then-`replaceItemAt` atomic write pattern
  throughout (see ADR-0032).
