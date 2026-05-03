# Encounter — First Principles

These principles guide every product and technical decision in this app.
They define what the app is, who it is for, and what it will never become.
When facing an ambiguous decision, return here first.

---

## 1. The GM at the table is the primary user

Every interaction is designed for a Game Master running a game with players watching.
Speed, clarity, and minimal taps during combat take priority over configurability,
data completeness, or power-user features.

If a feature creates friction at the table, it doesn't belong in the runner.
If it belongs in prep, it should be invisible during play.

## 2. The encounter is the unit of work

The app's spine is a single lifecycle: **Plan → Build → Run**.

Features that don't fit somewhere in that arc — campaign arc tracking, world-building,
character advancement, loot tables, NPC relationship webs — are out of scope for
this app. The encounter boundary is the product boundary.

## 3. No surprises during play

Content updates, network fetches, and data migrations are always user-initiated
and happen outside of an active session. Nothing changes state underneath a GM
during combat.

iCloud sync is the one exception — but it must be surfaced, not silently applied
mid-session.

## 4. The app augments the table; it doesn't replace it

Physical dice stay physical. Social moments — rolling, players spending Hope,
the drama of a crit — belong to the players and the table. The app removes
bookkeeping friction; it does not automate or intercept the play experience.

Don't intercede in the physical and social experience at the table unless
explicitly asked.

## 5. Player-owned state stays with the player

The GM app tracks what the GM controls and applies: conditions, adversary state,
the Fear pool. It does not replicate state that belongs to the player — Hope
balances, character advancement, character sheet data.

The architecture leaves the door open for a future player-side app to share
that state bidirectionally. This app does not own it.

## 6. Daggerheart rules are authoritative, not approximated

All mechanics must match the SRD exactly. No house-rule defaults, no "close enough."
When a rule is ambiguous in the SRD, the interpretation is recorded as an ADR.

The app supports the game as written — it is a tool, not a variant ruleset.

## 7. Content is open, not locked

The `.dhpack` format is publicly documented, plain JSON, and independent of this app.
Adversaries and environments are portable across tools.

Any GM should be able to create, share, and import content without approval,
proprietary tooling, or encoding. The app is an open platform for Daggerheart content.

## 8. GM authority is absolute

The SRD provides defaults, formulas, and guidance, and the app implements them
faithfully. But the GM is always in control of every value, regardless of what
the rules say.

HP, Fear, conditions, budget thresholds, damage applied — all must be directly
editable by the GM at any time. A GM should be able to fudge a roll result,
quietly heal an adversary, or ignore the difficulty budget entirely if it serves
the story at the table.

Difficulty warnings and balance indicators are advisory information only.
They never block, prevent, or require confirmation to override.

## 9. Platform-native, not least-common-denominator

iPhone is the primary run-time device (at the table). Mac is the primary prep
device (building encounters, managing content). visionOS is a supported build
target but receives no platform-specific design work at this stage.

Adapt each platform appropriately with `#if os()`, `NavigationSplitView` vs
`NavigationStack`, and platform-idiomatic gestures. Don't force a single layout
on all three platforms.

## 10. Value types for catalog data; observable classes for live state

Immutable catalog data — adversaries, environments, packs — is always value types
(structs and enums). Live session state — `EncounterSession`, `AdversarySlot`,
`PlayerSlot` — is mutable observable classes.

This boundary is not negotiable. Crossing it produces the snapshot/live mismatch
bugs the project has already eliminated (see ADR-0011).

## 11. Local-first, always

All core functionality operates entirely on-device. No required accounts, no
mandatory login, no remote service dependency at runtime.

iCloud sync is additive: it works when available and fails gracefully when not.
Future local-network sharing (GM and player apps on the same table network) and
eventual remote support for distributed play are valid extensions of this
foundation — not requirements that change the core.

## 12. iOS, iPadOS, and macOS are all first-class platform targets

*This supersedes Principle 9.*

iOS, iPadOS, and macOS each receive a navigation model and interaction idiom
appropriate to their input model and screen size:

- **iOS** — push navigation; single-column screens; at-the-table primary device
- **iPadOS** — split-view with toolbar mode switching; covers both prep and run at the table
- **macOS** — split-view with menu-driven mode switching; primary prep device

Each platform gets a distinct root layout. There is no shared-layout compromise.
`#if os(iOS)` / `#if os(macOS)` conditional compilation is used where platforms
diverge; shared components are platform-agnostic and used by all three.

visionOS is a supported build target but receives no platform-specific design
work at this stage — it inherits the iOS layout.

---

*These principles are intended to be stable. If a principle needs to change,
treat it like an ADR: write a new entry that supersedes the old one and
explains what changed and why. Do not silently edit the principles above.*
