//
//  PipTrackTests.swift
//  EncounterTests
//
//  Unit tests for PipTrack.pipColor — the gradient and tint logic.
//

import SwiftUI
import Testing

@testable import Encounter

@MainActor struct PipTrackTests {

  // MARK: - HP gradient (tint == nil)

  @Test func hpAbove66PercentReturnsCrimson() {
    let track = PipTrack(current: 5, maximum: 6, filledSymbol: "heart.fill", emptySymbol: "heart")
    #expect(track.pipColor == Color(red: 0.75, green: 0.22, blue: 0.17))
  }

  @Test func hpAt4of6ReturnsCrimson() {
    // 4/6 = 0.6̄ which IS > 0.66, so it stays in the crimson band
    let track = PipTrack(current: 4, maximum: 6, filledSymbol: "heart.fill", emptySymbol: "heart")
    #expect(track.pipColor == Color(red: 0.75, green: 0.22, blue: 0.17))
  }

  @Test func hpBetween33And66PercentIsOrange() {
    // 3/6 = 0.5, clearly in the orange band
    let track = PipTrack(current: 3, maximum: 6, filledSymbol: "heart.fill", emptySymbol: "heart")
    #expect(track.pipColor == .orange)
  }

  @Test func hpAt2of6ReturnsOrange() {
    // 2/6 = 0.3̄ which IS > 0.33, so it stays in the orange band
    let track = PipTrack(current: 2, maximum: 6, filledSymbol: "heart.fill", emptySymbol: "heart")
    #expect(track.pipColor == .orange)
  }

  @Test func hpJustBelow33PercentIsRed() {
    // 2/7 ≈ 0.286, which is not > 0.33, so it falls into the red band
    let track = PipTrack(current: 2, maximum: 7, filledSymbol: "heart.fill", emptySymbol: "heart")
    #expect(track.pipColor == .red)
  }

  @Test func hpBelowThresholdIsRed() {
    let track = PipTrack(current: 1, maximum: 6, filledSymbol: "heart.fill", emptySymbol: "heart")
    #expect(track.pipColor == .red)
  }

  @Test func hpEmptyIsRed() {
    let track = PipTrack(current: 0, maximum: 6, filledSymbol: "heart.fill", emptySymbol: "heart")
    #expect(track.pipColor == .red)
  }

  @Test func maximumZeroReturnsPrimary() {
    let track = PipTrack(current: 0, maximum: 0, filledSymbol: "heart.fill", emptySymbol: "heart")
    #expect(track.pipColor == .primary)
  }

  // MARK: - Tinted variants

  @Test func stressTintReturnsPrimary() {
    let track = PipTrack(
      current: 2, maximum: 6, filledSymbol: "bolt.fill", emptySymbol: "bolt", tint: .primary)
    #expect(track.pipColor == .primary)
  }

  @Test func armorTintReturnsSecondary() {
    let track = PipTrack(
      current: 1, maximum: 3, filledSymbol: "shield.fill", emptySymbol: "shield", tint: .secondary)
    #expect(track.pipColor == .secondary)
  }

  @Test func tintTakesPrecedenceOverGradient() {
    let track = PipTrack(
      current: 0, maximum: 6, filledSymbol: "bolt.fill", emptySymbol: "bolt", tint: .primary)
    #expect(track.pipColor == .primary)
  }
}
