# ADR-0018: User-initiated content refresh — no background fetch

**Status:** Accepted
**Date:** 2026-03-21

## Context

Content source packs (SRD updates, community adversary packs) need to be
refreshed when new versions are available. iOS provides background fetch
mechanisms, but automatic updates carry significant risks for a table tool.

## Decision

Content source updates are **user-initiated only**. There is no automatic
background fetch. GMs explicitly tap "Refresh" on a source to check for and
download updates.

Sources are cached locally on first download. The cached content is what the
app uses — a GM's adversary list never changes unexpectedly during a session.

`URLSession` with a background configuration is used for the actual download so
the transfer continues reliably if the app is backgrounded during a large pull.

## Options Considered

- **Background fetch (rejected):** System-scheduled, ~30-second window, fires
  at unpredictable times. Content could change between when a GM reviews an
  encounter before the game and when they sit down to run it. Unacceptable for
  a table tool.
- **Automatic refresh at launch (rejected):** Same problem — a GM who opens the
  app at the table could see their adversary list change as sources pull.
- **User-initiated refresh (chosen):** GM is in full control of when content
  updates. No surprises during a session. Explicit refresh also makes the
  network request transparent, which is appropriate given jsDelivr's IP logging
  (see ADR-0017).

## Consequences

- The `ContentStore` source list shows each source's `lastFetched` date so GMs
  know how stale their cache is.
- Refreshing a source during an active session has no effect on the running
  `EncounterSession` — the session's adversary slots are snapshots (see ADR-0011).
- Dates are stored as ISO8601 Zulu (see ADR-0013).
