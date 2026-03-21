# ADR-0009: SessionRegistry — in-memory session cache

**Status:** Accepted
**Date:** 2026-03-17

## Context

When a GM taps "Run Encounter" from the builder, a live `EncounterSession` is
created. If the GM navigates back to the builder and taps "Run Encounter" again,
should they get a fresh session (losing all HP/condition progress) or resume the
existing one?

## Decision

Introduce `SessionRegistry` — an `@Observable` class injected into the SwiftUI
environment at app launch that caches live `EncounterSession` objects keyed by
`EncounterDefinition.ID`.

`session(for:definition:compendium:)` returns an existing session if one is
cached, or creates and caches a new one. `clearSession(for:)` removes a cached
session (explicit "start over" action).

Sessions are **in-memory only**. They are lost when the app is killed.

## Options Considered

- **Create new session on every navigation (rejected):** Simple but loses all
  progress. Unacceptable when a GM leaves the runner to reference a rule and
  returns.
- **Persist sessions to disk (deferred):** Encoding `EncounterSession` as JSON
  would survive app restarts. Deferred because the session state graph is
  complex and the v1 priority is correct in-session behavior.
- **In-memory cache (chosen):** Solves the navigation-away-and-back problem
  with minimal complexity. Acceptable limitation that kill-and-relaunch resets
  the session.

## Consequences

- `EncounterSession` must conform to `Hashable` (using only `id`) so it can be
  used as a `NavigationStack` destination value.
- Session state is lost on app termination. GMs need to be aware of this.
- Cross-launch session persistence is a future enhancement (noted in Known Gaps).
