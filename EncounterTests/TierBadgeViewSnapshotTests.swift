//
//  TierBadgeViewSnapshotTests.swift
//  EncounterTests
//
//  Visual snapshot tests for TierBadgeView (Tier 3 — Snapshot).
//

#if os(iOS)
  import SnapshotTesting
  import SwiftUI
  import Testing

  @testable import Encounter

  @MainActor
  @Suite("TierBadgeView snapshots")
  struct TierBadgeViewSnapshotTests {

    @Test func belowPartyTier() {
      assertSnapshot(
        of: TierBadgeView(adversaryTier: 1, partyTier: 2).padding(),
        as: .image(layout: SnapshotLayout.badge)
      )
    }

    @Test func abovePartyTier() {
      assertSnapshot(
        of: TierBadgeView(adversaryTier: 3, partyTier: 2).padding(),
        as: .image(layout: SnapshotLayout.badge)
      )
    }

    @Test func matchingTier_rendersEmpty() {
      assertSnapshot(
        of: TierBadgeView(adversaryTier: 2, partyTier: 2).padding(),
        as: .image(layout: SnapshotLayout.badge)
      )
    }
  }
#endif
