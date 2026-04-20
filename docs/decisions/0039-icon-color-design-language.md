# ADR-0039: Icon and Color Design Language

**Status:** Accepted

---

## Context

As the app grows toward a runner screen, a player companion app, and potential GM tools, we need a consistent visual vocabulary for core Daggerheart mechanics. Icons and tints should reinforce game meaning — not just decorate — so a GM can read game state at a glance.

The core mechanics requiring visual representation:

| Concept | Role |
|---|---|
| Hit Points (HP) | Player/adversary health resource |
| Armor | Damage mitigation resource |
| Stress | Cumulative wear resource (player) |
| Fear | GM momentum resource (spending fuel) |
| Hope | Player momentum resource (agency fuel) |

Four proposals were evaluated against the SF Symbols 7 catalog (9,184 confirmed symbols) and Daggerheart's hopepunk design language as documented in the SRD. All symbol names were verified in the SF Symbols 7 app bundle.

---

## Decision

**Proposal 1 — "The Duality"** is adopted as the standard.

| Concept | Symbol | Tint |
|---|---|---|
| Hit Points | `heart.fill` | Crimson `#C0392B` |
| Armor | `shield.fill` | Steel gray (system secondary label) |
| Stress | `bolt.fill` | Amber `#E67E22` |
| Fear | `flame.fill` | System orange (already in use) |
| Hope | `bolt.heart.fill` | Warm gold `#F0C040` |

**Color palette**

| Role | Color | Rationale |
|---|---|---|
| Player resources (Hope, HP, Armor) | Warm spectrum: crimson, steel, gold | Human, vital, owned |
| GM/threat (Fear, high Stress) | Orange → amber | Escalating danger, same fire register |
| Inactive / depleted | System secondary | Emptiness is visually quiet |

**Condition icons** (confirmed in SF Symbols 7)

| Condition | Symbol |
|---|---|
| Hidden | `eye.slash.fill` |
| Restrained | `link.circle.fill` |
| Vulnerable | `shield.slash.fill` |

**Rationale for `bolt.heart.fill` as Hope:**
Hope in Daggerheart is not passive optimism — it is active energy that powers player agency. `bolt.heart.fill` (a lightning bolt through a heart) conveys energy flowing into vitality, which maps directly to the mechanical role of hope tokens. It visually contrasts with `flame.fill` (Fear) through shape rather than color alone, making the duality legible even in monochrome or under color-impaired vision. No other confirmed symbol in SF Symbols 7 captures this combination of energy and care.

**Rationale for `bolt.fill` as Stress:**
Stress is cumulative electrical tension — it builds, it crackles, and at maximum it breaks. `bolt.fill` is compact, legible at 16pt, and shares the "energy" register with Hope (`bolt.heart.fill`) while belonging to the threat/pressure column by color. This visual kinship reflects the mechanical relationship: stress is often caused by spending hope.

---

## Considered Alternatives

### Proposal 2 — "Blade & Spirit"

All system colors; classic RPG icon vocabulary.

| Concept | Symbol | Tint |
|---|---|---|
| Hit Points | `heart.fill` | `.systemRed` |
| Armor | `shield.fill` | `.systemBlue` |
| Stress | `waveform.path.ecg` | `.systemPurple` |
| Fear | `flame.fill` | `.systemOrange` |
| Hope | `star.fill` | `.systemYellow` |

**Why not chosen:** Zero custom palette makes maintenance easy, but the result reads as a generic health/fitness app rather than a distinctive Daggerheart tool. `star.fill` for hope is universally legible but doesn't carry any Daggerheart-specific meaning. `waveform.path.ecg` is evocative of vital signs under pressure but requires more render area than `bolt.fill` to be legible at pip-track sizes. System blue for armor looks defensive/trustworthy but clashes with the warm hopepunk aesthetic.

### Proposal 3 — "Beacon & Storm"

Atmospheric; leverages SF Symbols 7 palette rendering.

| Concept | Symbol | Tint |
|---|---|---|
| Hit Points | `heart.fill` | Warm rose |
| Armor | `shield.lefthalf.filled` | Warm bronze |
| Stress | `waveform` | Amber, fades gray at depletion |
| Fear | `cloud.bolt.fill` | Storm gray (cloud) + electric orange (bolt) — palette mode |
| Hope | `rays` | Warm gold |

**Why not chosen:** `cloud.bolt.fill` is atmospherically compelling — fear as a gathering storm rather than an open flame — but it conflicts with the iCloud/system UI association users have for cloud symbols on Apple platforms. `rays` for hope is beautiful but loses the energy/agency metaphor that `bolt.heart.fill` carries. `waveform` for stress is subtle but may not read as "damage" at pip-track sizes without surrounding context. Worth revisiting if the app expands to a more narrative/evocative presentation mode.

### Proposal 4 — "Signal Board"

Two-color tactical system optimized for runner-screen legibility.

| Concept | Symbol | Tint |
|---|---|---|
| Hit Points | `heart.fill` | Teal |
| Armor | `shield.fill` | Teal |
| Stress | `bolt.circle.fill` | Amber |
| Fear | `flame.fill` | Orange |
| Hope | `sparkles` | Teal |

**Why not chosen:** The two-color split (teal = player, amber/orange = threat) produces the most scannable runner screen in low-light table conditions. However, teal HP is unconventional enough to require learning — users expect red for health. `sparkles` for hope is clean but AI/magic-assistant associations (Siri, AI features) may compete. This proposal remains the strongest fallback if the runner screen proves too visually noisy in practice.

---

## Visual record

All four proposals were rendered side-by-side in the UI exploration harness (issue #84) at 20/28/44pt with mock adversary and player rows, on both platforms. Screenshots are in `docs/screenshots/icon-design-language/`.

| File | Content |
|---|---|
| `ios-design-language.png` | iOS — all four proposals at 20/28/44pt + mock rows |
| `ios-runner-row.png` | iOS — `AdversaryRunnerRow` in 9 states |
| `ios-player-strip.png` | iOS — `PlayerStrip` with varied player states |
| `macos-design-language.png` | macOS — same view in `NavigationSplitView` |
| `macos-runner-row.png` | macOS — adversary runner row states |
| `macos-player-strip.png` | macOS — player strip states |

No legibility or aesthetic problems were identified. Proposal 1 — "The Duality" is confirmed as the standard.

---

## Consequences

- All new views use the symbols and tints specified in the Decision section.
- The `docs/ui-vocabulary.md` Design Language section is the canonical reference.
- Future player companion app and GM screen tools should adopt the same icon set for consistency across the Daggerheart tool family.
- `dice.fill` and `die.face.N.fill` (confirmed in SF Symbols 7) are reserved for a future dice-roll feature.
- `wand.and.sparkles` is reserved for the future LLM encounter-generation feature.
