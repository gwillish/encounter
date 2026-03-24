# Contributing to Encounter

Encounter is an open-source Daggerheart encounter prep and run app for iOS and
macOS, built for Game Masters who need to set up and track encounters at the table.

Before contributing, read the [first principles](docs/first-principles.md). They
define what this app is, who it is for, and what it will never become. The
guidelines below flow directly from those principles.

---

## Scope

### In scope for v1

- Encounter prep: adversary roster, player configuration, GM notes, difficulty assessor
- Live encounter running: adversary HP/stress/conditions, Fear tracker, player strip
- Compendium: browse and search SRD adversaries and environments
- Content packs: import `.dhpack` files via URL, AirDrop, or file share; remove sources
- Homebrew adversary creation with power validation and export as `.dhpack`
- iCloud sync (ubiquity containers) across a GM's own devices

### Explicitly out of scope for this app

These will not be accepted as contributions, regardless of implementation quality:

| What | Why |
|---|---|
| Campaign management (session history, arc tracking, world state) | Outside the encounter lifecycle — see Principle 2 |
| PC character creation, leveling, or advancement | Not a GM tool responsibility |
| PC character sheets | Demiplane provides this; not in scope here |
| Initiative tracking | Daggerheart uses spotlight rotation, not initiative — see ADR-0021 |
| Dice rolling | Physical dice stay physical — see Principle 4 |
| In-app rules browser or SRD display | Licensing questions unresolved; see Principle 4 |
| Domain ability and class feature browsing | Outside the encounter lifecycle — see Principle 2 |
| Multi-GM collaboration | Single-GM scope only |
| Background sync or push notifications | All updates are user-initiated — see Principle 3 and ADR-0018 |

### Not in scope for this app, but not a hard no

- **Android** — a future Android-native app using Swift for Android is not excluded,
  but it is a separate project and a separate decision
- **Swift Package extraction** — the model layer will be extracted into a shared
  package when a second app is being built that needs it; premature extraction
  adds overhead for one consumer

---

## Proposing features

1. **Open an issue first.** Discuss before writing code.
2. **A human must be the proposer.** AI-generated feature proposals without a human
   author will not be considered. This applies to issues and PRs alike.
3. **Reference the first principles.** Explain how the feature fits within the
   encounter lifecycle and which principle(s) it supports.
4. **For significant design decisions**, an Architecture Decision Record (ADR) in
   `docs/decisions/` is required before implementation begins. See
   [docs/decisions/README.md](docs/decisions/README.md) for the format and process.

---

## Code expectations

- **Language:** Swift 6, latest stable toolchain
- **UI framework:** SwiftUI only — no UIKit imports
- **No force-unwrap** in model or view code — use `guard let` or optional chaining
- **Access control:** `public` on all model types and properties (anticipates future
  Swift Package extraction); `internal` on views
- **Naming:** use Daggerheart game terms as-is (`hp`, `stress`, `fear`, `hope`,
  `difficulty`, `thresholds`) — do not rename to generic equivalents
- **File layout:** one primary type per file; filename matches type name
- **Concurrency:** `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is active — all model
  types must be either Sendable value types or explicitly isolated `@Observable`
  classes; do not add `nonisolated` without a specific reason

---

## Formatting

This project uses **`swift-format`** (the built-in Swift toolchain formatter).
The `.swift-format` file at the project root is the source of truth for all
formatting rules. It contains explicit toolchain defaults so that local runs
and CI agree regardless of toolchain version drift.

Run it before every commit using the project script:

```bash
./Scripts/format.sh
```

The script formats and lints all tracked Swift files using `git ls-files`.
It is equivalent to:

```bash
git ls-files -z '*.swift' | xargs -0 swift format format --parallel --in-place
git ls-files -z '*.swift' | xargs -0 swift format lint --strict --parallel
```

PRs with formatting violations will be asked to reformat before review.

---

## Agentic development tools

The following agent skills and tools enable autonomous UI inspection, accessibility
auditing, and iOS Simulator interaction for AI-assisted development (Issue #23).

### Recommended skill stack

| Skill | Install | Purpose |
|---|---|---|
| swiftui-pro | pre-installed | SwiftUI patterns and best practices |
| swift-concurrency-pro | pre-installed | Async/await and actor correctness |
| swift-testing-pro | pre-installed | Unit + integration test authoring |
| ios-simulator-skill | `git clone https://github.com/conorluddy/ios-simulator-skill.git ~/.claude/skills/ios-simulator-skill` | Build, test, and semantically navigate iOS Simulator |
| axe | `brew tap cameroncooke/axe && brew install axe && axe init --client claude` | iOS Simulator automation: tap, type, screenshot, record |
| ios-accessibility | `npx skills add https://github.com/dadederk/iOS-Accessibility-Agent-Skill --skill ios-accessibility` | VoiceOver, Dynamic Type, and accessibility guidance |
| swift-accessibility-skill | `npx skills add https://github.com/PasqualeVittoriosi/swift-accessibility-skill` | macOS accessibility and WCAG Nutrition Labels |

### macOS native automation (MCP server)

For automating the macOS target, add [mcp-server-macos-use](https://github.com/mediar-ai/mcp-server-macos-use)
as an MCP server in Claude Code settings. After installing, grant Accessibility permission
to the Claude Code process in System Settings > Privacy & Security > Accessibility.

---

## Accessibility identifiers

All interactive SwiftUI views must have `.accessibilityIdentifier()` on interactive
elements. This enables semantic navigation by agent tools (AXe, ios-simulator-skill)
and assistive technology alike — poorly labelled elements fail both.

### Naming convention

Use kebab-case string literals with a feature-area prefix:

| Prefix | Scope |
|---|---|
| `library.*` | EncounterLibraryView and subviews |
| `builder.*` | EncounterBuilderView and subviews |
| `runner.*` | EncounterRunnerView and subviews |
| `compendium.*` | CompendiumBrowserView and subviews |
| `sources.*` | ContentSourcesView |
| `player-form.*` | AddPlayerForm |

Examples: `library.create-button`, `builder.run-button`, `runner.threshold.minor`,
`compendium.adversary-list`, `player-form.name-field`.

Use `.accessibilityValue(name)` on list rows so agent tools can distinguish items
with the same identifier (e.g. multiple `library.row` rows differentiated by name).

---

## Testing

- Tests use **Swift Testing** (`import Testing`), not XCTest
- **TDD:** write a failing test first, then implement — red before green
- All model mutations must have test coverage
- UI tests are required for critical user flows before a PR is ready
- Run the unit test suite before every PR:

```bash
xcodebuild test \
  -scheme Encounter \
  -destination 'platform=macOS' \
  -resultBundlePath TestResults.xcresult
```

---

## Architecture Decision Records

Significant architectural, data-format, and UX decisions are recorded as ADRs in
`docs/decisions/`. See [docs/decisions/README.md](docs/decisions/README.md) for
the full format, lifecycle, and superseded process.

**Never edit or delete an existing ADR.** If a decision was wrong or needs to
change, write a new superseding ADR. The history is preserved intentionally.

---

## Pull request process

1. **Link to an issue.** Every PR must reference the issue it addresses.
2. **Human author required.** AI-generated code is permitted; the PR author and at
   least one reviewer must be human. PRs without a human author will not be merged.
3. **Tests required.** New behavior without tests will not be merged.
4. **swift-format clean.** Run `./Scripts/format.sh` before pushing.
5. **Human review required.** All PRs require approval from a human reviewer before
   merge, regardless of how the code was written.
