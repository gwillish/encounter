# ADR-0029: ContentFingerprint unified struct (SHA-256 + ETag)

**Status:** Accepted
**Date:** 2026-03-21

## Context

Detecting whether a remote source pack has changed requires two distinct
mechanisms:

- **SHA-256** — validates that the locally stored bytes match what was
  downloaded. Catches corruption and confirms the content hash before accepting
  a new pack.
- **ETag** — an HTTP response header used for conditional GET
  (`If-None-Match`). Allows the server to return HTTP 304 Not Modified,
  skipping the download entirely when content hasn't changed.

Both pieces of information are derived from the same HTTP response and both
need to survive across app launches (persisted on `ContentSource`).

## Decision

Represent both as a single `ContentFingerprint` struct stored on `ContentSource`:

```swift
public struct ContentFingerprint: Codable, Equatable, Hashable, Sendable {
    public let sha256: String   // hex digest of the downloaded bytes
    public let etag:  String?   // HTTP ETag, nil if server didn't provide one
}
```

`etag` is optional because not all servers include it. `sha256` is always
present after a successful fetch.

## Options Considered

- **Flat fields on ContentSource (rejected):** Two separate `contentHash: String?`
  and `etag: String?` fields work, but staleness detection logic then touches
  two disjoint fields. Passing fingerprint data between `ContentFetcher` and
  `ContentStore` requires two parameters.
- **Unified ContentFingerprint struct (chosen):** All staleness information
  travels as one value. `ContentFetcher.fetch` returns a single `ContentFingerprint`.
  `ContentSource.recordingSuccess(fingerprint:)` takes one argument. Future
  additions (e.g. `lastModified` header) extend the struct without changing
  call sites.

## Consequences

- `ContentFingerprint` is `nonisolated` to remain accessible from
  `ContentFetcher`'s `nonisolated` methods under `SWIFT_DEFAULT_ACTOR_ISOLATION
  = MainActor`.
- SHA-256 is computed by `ContentFetcher.computeSHA256(_:)`, a `nonisolated`
  function that runs on the cooperative thread pool. It must never be called
  from the main actor directly for large data.
- If two fetches return the same SHA-256 but different ETags (an unlikely but
  possible server misconfiguration), the content is treated as unchanged. The
  ETag is updated regardless.
