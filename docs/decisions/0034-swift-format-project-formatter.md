# ADR-0034: swift-format as project formatter

**Status:** Accepted
**Date:** 2026-03-22

## Context

As the project grows and opens to contributors (including agentic ones), consistent
code formatting becomes important for readability and review. Several tools are
available for Swift projects. We needed to pick one and commit to it so that
`CONTRIBUTING.md` and eventual CI enforcement have a clear target.

## Decision

Use the Swift toolchain's built-in `swift-format` for all code formatting and
linting. Run it before every commit as a convention; enforce it in CI as part of
the Phase 6 contributor guidelines work (issue #49).

```bash
swift-format format --recursive --in-place Encounter/
swift-format lint --recursive Encounter/
```

## Options Considered

**SwiftLint** — widely used, large rule set, supports custom rules and inline
disable comments. Requires an external dependency (SPM or Homebrew). Does not
auto-format; only warns. Would need SwiftFormat alongside it for actual
reformatting.

**SwiftFormat (Nicklockwood)** — popular auto-formatter with extensive options.
Another external dependency. Separate from the toolchain; version pinning required.

**No formatter** — inconsistent style across contributors and AI-generated code.
Harder to review diffs. Not acceptable for an open-source project.

**swift-format (chosen)** — ships with the Swift toolchain; no additional
dependency to install or version-pin. Updated with the language. Enforces a
consistent style that tracks the official Swift style guidelines. Reformats
automatically with `--in-place`. The `lint` subcommand can gate PRs in CI
without requiring a separate tool.

## Consequences

- All contributors and AI agents must run `swift-format format` before committing.
- PRs with formatting violations will be asked to reformat before review.
- CI will enforce `swift-format lint` in Phase 6 (issue #49).
- No additional package or Homebrew dependency is introduced.
- Style is determined by swift-format's defaults; project-specific overrides can
  be added via a `.swift-format` configuration file if needed in the future.
