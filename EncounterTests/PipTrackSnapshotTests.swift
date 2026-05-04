//
//  PipTrackSnapshotTests.swift
//  EncounterTests
//
//  Visual snapshot tests for PipTrack (Tier 3 — Snapshot).
//  Covers HP gradient bands, tinted (stress/armor) variants, and text fallback.
//

#if os(iOS)
import SnapshotTesting
import SwiftUI
import Testing

@testable import Encounter

@MainActor
@Suite("PipTrack snapshots")
struct PipTrackSnapshotTests {

  // MARK: - HP gradient

  @Test func hp_full() {
    assertSnapshot(
      of: PipTrack(current: 6, maximum: 6, filledSymbol: "heart.fill", emptySymbol: "heart").padding(),
      as: .image(layout: SnapshotLayout.badge)
    )
  }

  @Test func hp_half() {
    assertSnapshot(
      of: PipTrack(current: 3, maximum: 6, filledSymbol: "heart.fill", emptySymbol: "heart").padding(),
      as: .image(layout: SnapshotLayout.badge)
    )
  }

  @Test func hp_critical() {
    assertSnapshot(
      of: PipTrack(current: 1, maximum: 6, filledSymbol: "heart.fill", emptySymbol: "heart").padding(),
      as: .image(layout: SnapshotLayout.badge)
    )
  }

  // MARK: - Tinted (stress, armor)

  @Test func stress_full() {
    assertSnapshot(
      of: PipTrack(
        current: 5, maximum: 5,
        filledSymbol: "bolt.fill", emptySymbol: "bolt",
        tint: .primary
      ).padding(),
      as: .image(layout: SnapshotLayout.badge)
    )
  }

  @Test func armor_partial() {
    assertSnapshot(
      of: PipTrack(
        current: 1, maximum: 3,
        filledSymbol: "shield.fill", emptySymbol: "shield",
        tint: .secondary
      ).padding(),
      as: .image(layout: SnapshotLayout.badge)
    )
  }

  // MARK: - Text fallback (maximum > 12)

  @Test func textFallback() {
    assertSnapshot(
      of: PipTrack(current: 8, maximum: 14, filledSymbol: "heart.fill", emptySymbol: "heart").padding(),
      as: .image(layout: SnapshotLayout.badge)
    )
  }
}
#endif
