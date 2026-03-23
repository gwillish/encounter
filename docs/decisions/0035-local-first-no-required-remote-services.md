# ADR-0035: Local-first architecture — no required remote services

**Status:** Accepted
**Date:** 2026-03-22

## Context

The app targets Game Masters running sessions at a physical table, often in
environments with unreliable or absent network connectivity (game stores, homes
with spotty Wi-Fi, conventions). A GM mid-combat cannot afford an app that
stalls, shows a loading spinner, or loses state because a remote service is
unavailable.

Additionally, requiring an account or backend login adds friction for a GM who
just wants to open the app and run a game. We needed to establish a clear
architectural position on remote service dependency before building the UI layers.

## Decision

All core functionality — building encounters, running sessions, browsing the
compendium, managing content sources — operates entirely on-device. No account,
login, or remote service is required at runtime.

Remote connectivity is additive:

- **iCloud sync** (ubiquity containers, ADR-0008) is the one opt-in remote
  feature. It syncs when available and fails gracefully when not. The app never
  blocks on it.
- **Content source fetching** (ADR-0018) is always user-initiated. The app never
  fetches in the background. Cached content is always available regardless of
  network state.
- **Future extensions** — local-network sharing between GM and player apps, and
  eventual remote sync for distributed/online play — are valid extensions of this
  foundation. They must be designed as additive layers, not replacements for the
  on-device core.

## Options Considered

**Require a backend for sync from the start** — enables richer multi-device
features, but couples app availability to service availability. A GM at the
table is blocked if the backend is down. Violates Principle 3 (no surprises
during play).

**Require iCloud account** — simpler than a custom backend, but excludes
offline use and users without Apple IDs. Adds a login step before first use.

**Local-only, no sync ever** — simplest, but GMs with both a Mac and iPhone
lose the ability to prep on one device and run on another. iCloud sync is
specifically valued for this use case.

**Local-first with iCloud as additive (chosen)** — the app always works
fully offline. iCloud sync is a background capability that improves the
experience when available without ever being required for it.

## Consequences

- `EncounterStore`, `ContentStore`, `SessionRegistry`, and `Compendium` must
  all function fully without network access.
- `ContentSource` fetch failures are non-fatal — cached content remains
  available; the user is informed but not blocked.
- No user account, login screen, or authentication flow is introduced for v1.
- Future player-sync and remote-play features must be designed as additive
  layers that degrade gracefully to local-only when unavailable.
- iCloud sync failure must be surfaced to the user (not silently ignored) but
  must never block the encounter workflow.
