# ADR-0046: Single Party with Hidden Member Flag

**Status:** Accepted
**Date:** 2026-05-03

## Context

The app has always maintained a single active party (a `Party` value with a `playerIDs: [UUID]` array in `PlayerStore`). There was no documented decision explicitly adopting single-party and rejecting multi-party. Additionally, the only way to exclude a player from active encounters was to remove them from the party entirely — which meant re-entering all their stats when they returned.

Common table situations that needed a solution:
- A player misses a session; their character should not appear in the encounter runner but must remain in the roster for next session.
- A player temporarily leaves the table mid-campaign; their character is not deleted, just absent.

## Decision

**The app supports exactly one party roster. No multi-party switching.**

A player can be **hidden** — excluded from active encounter sessions — without being deleted from the roster. Hidden state is a global roster flag: once hidden, the player is excluded from all encounters until explicitly un-hidden.

### Implementation

`PlayerStore` gains `hiddenPlayerIDs: Set<UUID>` as a persisted property (stored in `<directory>/hidden-players.json`). The computed property `activePartyPlayers` filters hidden IDs:

```swift
public var activePartyPlayers: [Player] {
    party.playerIDs
        .filter { !hiddenPlayerIDs.contains($0) }
        .compactMap { id in players.first { $0.id == id } }
}
```

New methods:
```swift
public func hidePlayer(id: UUID) async
public func showPlayer(id: UUID) async
```

`hidePlayer` adds to `hiddenPlayerIDs` and saves. `showPlayer` removes from `hiddenPlayerIDs` and saves. Deleting a player also removes them from `hiddenPlayerIDs`.

This avoids modifying the DHKit `Player` type while keeping the feature fully at the app layer.

### UI affordances

Hidden players are shown in the party list with a distinct visual style (grayed, `eye.slash` icon) and an Un-hide button. They are always visible in the roster so their existence is not surprising when they reappear. The count of active (non-hidden) party members is what flows into encounter difficulty calculations.

### Why not per-encounter exclusion

Per-encounter exclusion would require each `EncounterDefinition` to store a set of excluded player IDs. This complicates the builder, the difficulty assessor (which player count applies?), and the session factory. The primary use case is a player being absent from a campaign arc — a roster-level signal, not an encounter-level one.

## Options Considered

- **Multi-party support (rejected).** Multiple named parties adds selection UI to every encounter workflow. The party is not a variable in a single-campaign GM tool — it is a stable configuration. If a GM runs multiple campaigns, they use separate app instances or separate encounter stores.
- **Delete and re-add player (prior approach, replaced).** Deleting a player loses all their stat data and history. Re-entry is friction that discourages accuracy.
- **Per-encounter excluded players (rejected).** See above. Roster-level flag matches the real-world signal (player is absent this session / this arc) better than an encounter-level flag.
- **`isHidden` on `Player` in DHKit (considered, rejected).** Adding UI/roster state to the DHKit `Player` type mixes UI concern into the catalog model. The DHKit `Player` should remain a pure data type. `hiddenPlayerIDs` as an app-layer set is the correct separation.

## Consequences

- `PlayerStore` gains `hiddenPlayerIDs`, `hidePlayer(id:)`, `showPlayer(id:)`.
- `PlayerStore.activePartyPlayers` excludes hidden players.
- `EncounterAndPartyRootView` (iOS) and `EncounterAndPartyPanel` (macOS/iPadOS) both display hidden players with a distinct style and unhide affordance.
- `DifficultyAssessorView` already consumes `activePartyPlayers` for party-tier calculations — no change needed there.
- The concept of "Active Party" vs "Roster" in the existing party management UI simplifies: all players in `party.playerIDs` are the party; hidden/shown is the only sub-state. The `removeFromParty` / `addToParty` distinction used in `PartyOverviewView` is retired in favour of the single-party model.
