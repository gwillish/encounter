# ADR-0024: SRD JSON data format — seansbox/daggerheart-srd

**Status:** Accepted
**Date:** 2026-03-15

## Context

Daggerheart SRD content needs to be represented in a structured, machine-readable
format. Multiple community projects have produced JSON exports of the SRD, but
they use different schemas.

## Decision

Use the **seansbox/daggerheart-srd** JSON format as the canonical data format for
adversaries and environments. This is the format used by the bundled
`adversaries.json` and `environments.json`, and all downloaded content packs
(`.dhpack` files) use this format.

The decoder handles two threshold formats produced by different SRD export
versions:
- Combined string: `"thresholds": "8/15"`
- Pre-split keys: `"threshold_major": 8, "threshold_severe": 15`

The decoder also normalizes adversary type variants (e.g., `"Horde (N/HP)"` →
`.horde`) and handles `"None"` threshold values for adversary types that have no
damage thresholds (e.g., Minions).

## Options Considered

- **daggersearch/daggerheart-data format (rejected for adversaries):** This repo
  focuses on player content (classes, ancestries, items). It does not include
  adversaries and uses a different schema.
- **Custom schema (rejected):** Designing and maintaining a proprietary schema
  would fragment the community tooling ecosystem. Using the community-standard
  format means GMs can author content with existing tools.
- **seansbox format (chosen):** Widest community adoption. The most complete
  adversary dataset available. Existing community tooling targets this format.

## Consequences

- All content packs (`.dhpack` files) must conform to the seansbox schema.
  The `Adversary` and `DaggerheartEnvironment` decoders validate on import.
- The `source` field (ADR-0014) is an extension to this format — it decodes
  as optional with a default of `"srd"` to maintain backward compatibility.
- Future schema additions (e.g., an `overrides` field for homebrew) should
  follow the same optional-with-default pattern.
- `SRDDecodeTests` verify that all bundled adversaries and environments decode
  without error after any decoder changes.
