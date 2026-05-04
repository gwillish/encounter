# ADR-0048 — Snapshot Testing with swift-snapshot-testing

**Status:** Accepted

---

## Context

The testing pyramid had four tiers: model (Swift Testing), view structure (ViewInspector),
visual (Xcode MCP RenderPreview), and end-to-end (XCUITest). There was no automated
visual regression layer — catching layout regressions required a human to manually trigger
`RenderPreview` during a review session.

GitHub issue #95 asked for a snapshot-based alternative to XCUITest screenshots that could
serve as a lower-friction visual regression layer: an agent sets data state, captures a PNG,
and commits it; future CI runs detect pixel-level changes.

---

## Decision

Add `pointfreeco/swift-snapshot-testing` (1.19.2) as a Tier 3 snapshot testing layer.

Tests live in `EncounterTests/`, guarded `#if os(iOS)`, and run on iOS Simulator.
Reference PNGs are committed to `EncounterTests/__Snapshots__/` alongside the test source.
The five-tier pyramid is now: model → view structure → snapshot → RenderPreview → XCUITest.

---

## Rationale

### Why iOS Simulator only, not macOS

macOS unit tests run inside `Encounter.app`'s sandboxed process. The app entitlement
`com.apple.security.app-sandbox = true` blocks filesystem writes to the source tree.
`assertSnapshot` fails immediately when it cannot create the `__Snapshots__/` directory.

The entitlements workaround (`temporary-exception.files.absolute-path.read-write`) was
attempted but Xcode's test infrastructure overrides signed entitlements during test
injection — the custom entitlement never appeared in the final signed binary.

iOS Simulator test processes run outside any app sandbox and can write to host filesystem
paths. This is the standard mechanism used by all snapshot libraries on iOS. Running on
iPhone 17 Pro Simulator produces consistent, reproducible output.

### Why not a separate test target

A separate non-sandboxed macOS test target was considered. It was rejected because:
- It requires maintaining a second host app target or a library-style bundle
- iOS Simulator captures the actual rendering environment the app ships on
- Snapshot images would differ between macOS and iOS, reducing utility for designers

### Why committed PNGs, not generated at CI time

Committed PNGs make visual diffs visible in PR review without any CI tooling. Any reviewer
can see changed images in a GitHub PR diff. Regeneration is deliberate: delete the file and
re-run. This matches the design intent of swift-snapshot-testing.

### Parallel clone behavior

xcodebuild runs Swift Testing suites across parallel simulator clones. Each clone generates
its own snapshot file with a numeric suffix (`.1.png`, `.2.png`). Both files are recorded
on the first run and used as references on subsequent runs. All clones pass on comparison.
This behavior is inherent to swift-snapshot-testing's Swift Testing integration and is
expected and stable.

---

## Consequences

- Snapshot tests must always be run on iOS Simulator, not macOS.
- Reference PNGs add ~50–200 KB per test to the repo. This is acceptable for the number of
  components covered.
- Parallel execution produces two PNG copies per test (`.1.png`, `.2.png`). Both are
  committed and both are valid references.
- The testing pyramid is renumbered: what was Tier 3 (RenderPreview) is now Tier 4;
  what was Tier 4 (XCUITest) is now Tier 5.
