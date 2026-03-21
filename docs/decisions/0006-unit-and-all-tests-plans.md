# ADR-0006: UnitTests and AllTests test plans

**Status:** Accepted
**Date:** 2026-03-21

## Context

The project has both unit tests (`EncounterTests`) and UI tests
(`EncounterUITests`). On macOS, UI tests require unlocking the screen and
interact with a live running app. Running UI tests on every save during
development interrupts the iteration loop.

The original `Encounter.xctestplan` had `EncounterUITests` marked
`enabled: false` but still listed a `selectedTests` entry
(`EncounterUITestsLaunchTests/testLaunch()`), which caused the launch test
to still run and trigger the unlock prompt.

## Decision

Replace the single `Encounter.xctestplan` with two named plans:

- **`UnitTests.xctestplan`** — `EncounterTests` only. No UI tests. Set as the
  scheme default so bare `xcodebuild test` never triggers the unlock prompt.
- **`AllTests.xctestplan`** — both `EncounterTests` and `EncounterUITests`.
  Used before PRs and for release validation.

```bash
# Development iteration (default):
xcodebuild test -scheme Encounter -destination 'platform=macOS' \
  -resultBundlePath TestResults.xcresult

# Pre-PR / release validation:
xcodebuild test -scheme Encounter -destination 'platform=macOS' \
  -testPlan AllTests -resultBundlePath TestResults.xcresult
```

## Options Considered

- **`-skip-testing:EncounterUITests` flag (rejected):** Works but must be
  remembered on every invocation. Easy to forget; not enforced for collaborators.
- **Second scheme (rejected):** Schemes are fiddly to manage in `.xcodeproj`;
  test plans are the modern mechanism for this.
- **Two named test plans (chosen):** Intent is in the repo, Xcode's UI shows
  the plans, CI can select the right plan by name.

## Consequences

- The old `Encounter.xctestplan` is deleted.
- The bare `xcodebuild test` command (as documented in `CLAUDE.md`) runs unit
  tests only with no unlock prompt.
- UI test coverage is not skipped — it is deliberately separated into an
  explicit workflow step.
