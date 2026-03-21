# ADR-0027: ContentSource exponential backoff with 7-day cap

**Status:** Accepted
**Date:** 2026-03-21

## Context

Remote content sources (`.dhpack` URLs) are user-registered and fetched on
user request (ADR-0018). When a source URL returns an error — 429, 5xx,
network timeout — the app must not hammer the host on every subsequent launch
or manual refresh. `ContentSource` needs a rate-limiting strategy.

## Decision

Use **exponential backoff** with a hard cap:

```
delay = min(1h × 2^consecutiveFailures, 7 days)
```

- 1st failure  → 1 hour
- 2nd failure  → 2 hours
- 3rd failure  → 4 hours
- …
- 10th failure → 7 days (capped)

`ContentSource` tracks two fields:

```swift
public private(set) var consecutiveFailures: Int
public private(set) var nextAllowedFetch: Date?
```

These are updated by pure mutation methods that return new values:

```swift
func recordingFailure(at date: Date = .now) -> ContentSource
func recordingSuccess(fingerprint: ContentFingerprint, at date: Date = .now) -> ContentSource
```

`recordingSuccess` resets `consecutiveFailures` to 0 and clears `nextAllowedFetch`.
Both fields are persisted in the source index (`sources/index.json`) so backoff
survives app restarts.

## Options Considered

- **Fixed cooldown (rejected):** Set `nextAllowedFetch = now + 1 hour` on any
  error. Simple, but treats a transient blip the same as a persistent outage.
  After 10 failures the host is still retried every hour indefinitely.
- **Exponential backoff with cap (chosen):** Retries quickly after brief
  outages; backs off gracefully during extended ones. The 7-day cap prevents
  a source from being permanently silenced while still protecting hosts during
  prolonged downtime.

## Consequences

- A source that fails repeatedly will not be retried for up to 7 days. The UI
  should surface `nextAllowedFetch` so the GM knows why a source is not
  refreshing and can manually override if needed.
- `consecutiveFailures` and `nextAllowedFetch` are `private(set)` on
  `ContentSource` — only mutated via `recordingFailure` and `recordingSuccess`
  to keep the backoff logic in one place.
- Because `ContentSource` is a value type, mutations in `ContentStore` must
  write the updated value back to the `sources` dictionary explicitly.
