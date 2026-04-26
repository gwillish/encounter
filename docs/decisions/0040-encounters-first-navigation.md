# ADR-0040: Encounters as the default landing screen

**Status:** Accepted
**Date:** 2026-04-25

## Context

The original tab order (iOS) and sidebar default (macOS) placed the Party screen first.
Party management is setup work done before a session; during active use at the table the
GM navigates to Encounters immediately. Leading with Party forced an extra tap on every
app launch and buried the primary workflow.

## Decision

Encounters is now the default landing screen on all platforms:

- **iOS/visionOS:** Encounters tab is first (left); Party tab is second.
- **macOS:** sidebar defaults to the Encounters item; Party is listed below it.

## Options Considered

- **Party first (original):** Reflected the setup-before-run mental model but
  front-loaded an extra navigation step for the most common session-start flow.
- **Encounters first (chosen):** Matches GM intent at the table — encounters are the
  focus, party management is secondary. Confirmed by issue #90.

## Consequences

- The app now opens directly into the encounter library, which is the correct default
  for in-session use.
- All UI test launch expectations and navigation helpers updated to reflect Encounters
  as the arrival screen.
- macOS: a nil sidebar selection (user presses Escape to deselect) falls through to the
  Encounters content column, consistent with it being the primary view.
