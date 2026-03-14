# Daggerheart Data Schema Reference

This document describes the JSON schemas used by the Encounter app for Daggerheart
adversary and environment data, the community sources they were derived from, and how
they map to the official Daggerheart SRD.

---

## Sources

| Source | URL | Role |
|---|---|---|
| **Daggerheart SRD** (official) | https://www.daggerheart.com/srd/ | Authoritative rule definitions |
| **seansbox/daggerheart-srd** | https://github.com/seansbox/daggerheart-srd | SRD in JSON/CSV/Obsidian MD; primary JSON data source |
| **ly0va/beastvault** | https://github.com/ly0va/beastvault | Obsidian plugin; defines the adversary YAML/JSON import schema |
| **javalent/fantasy-statblocks** | https://github.com/javalent/fantasy-statblocks/blob/main/src/layouts/daggerheart/publish/Daggerheart%20Layouts.md | Obsidian statblock layout with field names |
| **daggersearch/daggerheart-data** | https://github.com/daggersearch/daggerheart-data | Player-facing content (classes, ancestries, items); **no adversaries** |
| **Daggerheart Fight Club** | https://rpgmania.github.io/ | Web encounter tool; cross-reference for adversary display |
| **Heartforge** | https://www.heartforge.app/ | iOS companion app; cross-reference for encounter tracking UX |

The **primary JSON data file** to import SRD adversaries is:
```
seansbox/daggerheart-srd → .build/json/adversaries.json
seansbox/daggerheart-srd → .build/json/environments.json
```

---

## Adversary JSON Schema

### Top-level structure

The community JSON files contain a **top-level array** of adversary objects:

```json
[
  { ... },
  { ... }
]
```

### Adversary object fields

| JSON key | Swift property | Type | Required | Notes |
|---|---|---|---|---|
| `id` | `id` | string | yes | URL-safe slug, e.g. `"acid-burrower"` |
| `name` | `name` | string | yes | Display name |
| `source` | `source` | string | no | `"SRD"`, `"Homebrew"`, book name; defaults to `"Unknown"` |
| `tier` | `tier` | integer | yes | 1–4; matches PC level tiers |
| `type` | `type` | string | yes | See Adversary Types below |
| `description` | `description` | string | yes | One-line appearance/demeanor |
| `motives_and_tactics` | `motivesAndTactics` | string | no | GM-facing play guidance |
| `difficulty` | `difficulty` | integer | yes | DC for all rolls against this adversary |
| `thresholds` | decoded → `thresholdMajor`/`thresholdSevere` | string | either | `"major/severe"` format, e.g. `"8/15"` |
| `threshold_major` | `thresholdMajor` | integer | either | Pre-split alternative to `thresholds` |
| `threshold_severe` | `thresholdSevere` | integer | either | Pre-split alternative to `thresholds` |
| `hp` | `hp` | integer | yes | Hit points |
| `stress` | `stress` | integer | yes | Stress capacity |
| `atk` | `attackModifier` | string | yes | Attack modifier, e.g. `"+3"` |
| `attack` | `attackName` | string | yes | Weapon or attack name |
| `range` | `attackRange` | string | yes | See Attack Ranges below |
| `damage` | `damage` | string | yes | Damage expression, e.g. `"1d12+2 phy"` |
| `experience` | `experience` | string | no | e.g. `"Tremor Sense +2"` |
| `feats` | `features` | array | no | See Feature object below |

> **Threshold decoding note:** The decoder accepts both the combined `"thresholds"` string
> and pre-split `threshold_major` / `threshold_severe` integer keys. The combined string is
> the community standard (seansbox, beastvault); the split keys are used in our own export
> format for clarity.

### Adversary Types

| JSON value | Swift case | Description |
|---|---|---|
| `"Bruiser"` | `.bruiser` | Tough; deliver powerful attacks. Often have extra HP. |
| `"Horde"` | `.horde` | Groups of identical creatures acting as one unit. Special HP/attack rules apply. |
| `"Leader"` | `.leader` | Command and summon other adversaries. High stress capacity. |
| `"Minion"` | `.minion` | Easily dispatched but dangerous in numbers. |
| `"Ranged"` | `.ranged` | Fragile in melee; deal high damage at range. |
| `"Solo"` | `.solo` | Designed for climactic one-on-one encounters. |
| `"Standard"` | `.standard` | Catch-all for adversaries without an explicit type. |

### Attack Ranges

| JSON value | Swift case |
|---|---|
| `"Very Close"` | `.veryClose` |
| `"Close"` | `.close` |
| `"Far"` | `.far` |
| `"Very Far"` | `.veryFar` |

### Damage expression format

Damage strings follow the pattern `XdY+Z type`, e.g.:

- `"1d10+3 phy"` — physical damage
- `"2d6 mag"` — magical damage
- `"1d8+1 phy"` — physical with flat bonus

The `type` suffix is informal; the official SRD uses `phy` (physical) and `mag` (magical).
Parse with a dice library or regex `(\d+)d(\d+)([+-]\d+)?\s*(\w+)?` as needed.

### Feature (feat) object

```json
{
  "name": "Pack Tactics",
  "text": "Deals +1 damage for each other Pack member within Very Close range.",
  "feat_type": "passive"
}
```

| JSON key | Swift property | Type | Values |
|---|---|---|---|
| `name` | `name` | string | Unique within the adversary |
| `text` | `text` | string | Rules text |
| `feat_type` | `featType` | string | `"action"`, `"reaction"`, `"passive"` |

Feature types (from SRD):
- **Actions** — trigger when this adversary has the spotlight
- **Reactions** — trigger regardless of who has the spotlight
- **Passives** — always in effect

---

## Environment JSON Schema

Environments use the same file structure (top-level array) and share the feature schema.
The key difference from adversaries: **no `hp`, `stress`, `atk`, `attack`, `range`, or
`damage` fields**. BeastVault uses the absence of `hp`+`stress` as the discriminant
between adversary and environment entries.

| JSON key | Swift property | Type | Required |
|---|---|---|---|
| `id` | `id` | string | yes |
| `name` | `name` | string | yes |
| `source` | `source` | string | no |
| `description` | `description` | string | yes |
| `feats` | `features` | array | no |

---

## Player-Facing Content (daggersearch/daggerheart-data)

The `daggersearch/daggerheart-data` repo covers SRD content for player characters:
classes, ancestries, communities, domains, subclasses, weapons, armor, and equipment.

**This repo does not include adversaries or environments.** Its schema uses:

```json
{
  "id": "guardian",
  "name": "Guardian",
  "description": "...",
  "source": "SRD",
  "domains": ["Blade", "Bone"],
  "features": [ ... ]
}
```

If player-character content is added to this app in future, use this repo as the source
and adapt the schema accordingly.

---

## Mapping: Community JSON → Official SRD

| SRD term | Community JSON key | Notes |
|---|---|---|
| Difficulty | `difficulty` | Flat DC; replaces Evasion for adversaries |
| Major Threshold | `thresholds` (first number) | Damage required for Major hit |
| Severe Threshold | `thresholds` (second number) | Damage required for Severe hit |
| Hit Points | `hp` | — |
| Stress | `stress` | — |
| Attack Modifier | `atk` | — |
| Standard Attack | `attack` | Name of the weapon/attack |
| Range | `range` | Distance band |
| Damage | `damage` | Dice expression with type suffix |
| Features | `feats` | Actions, reactions, passives |

The official SRD does not tag features with `feat_type` in printed stat blocks —
the community added this field to enable programmatic filtering. The three types
(Actions / Reactions / Passives) are described narratively in the SRD under
"Using Adversaries."

---

## Homebrew Compatibility

The Encounter app's JSON format is designed to be compatible with the community
ecosystem, allowing GMs to:

1. Import adversaries from seansbox/daggerheart-srd directly with no transformation.
2. Import custom adversaries created in BeastVault (export as JSON array).
3. Share homebrew adversaries with other Encounter users in the same JSON format.

The only divergence from the community format is that our **export** uses pre-split
`threshold_major` / `threshold_severe` integers instead of the combined `thresholds`
string. The decoder accepts both.
