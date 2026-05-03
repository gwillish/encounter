//
//  TierBadgeViewTests.swift
//  EncounterTests
//

import SwiftUI
import Testing
import ViewInspector

@testable import Encounter

@MainActor
@Suite("TierBadgeView")
struct TierBadgeViewTests {

  // MARK: - Accessibility label

  @Test func belowPartyTierAccessibilityLabel() throws {
    let sut = TierBadgeView(adversaryTier: 1, partyTier: 2)
    let hstack = try sut.inspect().find(ViewType.HStack.self)
    #expect(try hstack.accessibilityLabel().string() == "Tier 1, below party tier")
  }

  @Test func abovePartyTierAccessibilityLabel() throws {
    let sut = TierBadgeView(adversaryTier: 3, partyTier: 2)
    let hstack = try sut.inspect().find(ViewType.HStack.self)
    #expect(try hstack.accessibilityLabel().string() == "Tier 3, above party tier")
  }

  // MARK: - Hidden when tiers match

  @Test func matchingTierRendersNoContent() {
    let sut = TierBadgeView(adversaryTier: 2, partyTier: 2)
    #expect(throws: (any Error).self) {
      try sut.inspect().find(ViewType.HStack.self)
    }
  }
}
