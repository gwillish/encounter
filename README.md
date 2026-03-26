# Encounter

Daggerheart encounter prep and run app for iOS and macOS, primarily for game masters
who need to set up and track encounters at the table.

Built with SwiftUI, targeting iOS 26, macOS 26, and visionOS 26.

## Documentation

Full documentation is hosted at **[gwillish.github.io/encounter](https://gwillish.github.io/encounter/documentation/encounter/)** (see [issue #20](https://github.com/gwillish/encounter/issues/20) for CI setup).

- `CLAUDE.md` — full technical context, conventions, and build instructions for
  development with Claude Code
- `docs/data-schema.md` — Daggerheart JSON schema reference and source links
- `docs/decisions/` — Architecture Decision Records (ADRs): the history of
  significant architectural, data-format, and UX choices made during development

## Content Packs

Encounter supports community and homebrew content through the `.dhpack` format — a
plain JSON file containing adversaries, environments, or both.

- [.dhpack format reference](https://gwillish.github.io/encounter/documentation/encounter/dhpackformat) — complete schema, field tables, and examples
- [Authoring a pack](https://gwillish.github.io/encounter/documentation/encounter/authoringapack) — three paths: text editor, in-app export, or programmatic generation
- [Sharing and hosting](https://gwillish.github.io/encounter/documentation/encounter/sharingandhostingpacks) — AirDrop, URL sources, GitHub Releases, jsDelivr, Gist

The JSON Schema for `.dhpack` is maintained in the
[DaggerheartModels](https://github.com/gwillish/DaggerheartModels) repository.
Add `"$schema": "https://raw.githubusercontent.com/gwillish/DaggerheartModels/main/schemas/dhpack.schema.json"`
to your pack file to enable validation and autocomplete in VS Code.

## Architecture Decision Records

Significant decisions are recorded as ADRs in `docs/decisions/`. Each record
captures why a decision was needed, what was decided, what alternatives were
considered, and what consequences follow.

When a decision turns out to be wrong or needs to change, a new ADR is written
that supersedes the original. The original is never edited or deleted — the
reasoning history is preserved. See `docs/decisions/README.md` for the full
process.
