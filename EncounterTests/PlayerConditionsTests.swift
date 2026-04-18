//
//  PlayerConditionsTests.swift
//  EncounterTests
//
//  Unit tests for player condition apply/remove via EncounterSession,
//  covering the logic exercised by PlayerConditionsSection.
//

import DHKit
import DHModels
import Foundation
import Testing

@testable import Encounter

@MainActor struct PlayerConditionsTests {

  // Returns a session and a snapshot of playerSlots[0] at creation time.
  // Post-mutation assertions must use session.playerSlots[0], not the returned player.
  private func makeSession() -> (EncounterSession, PlayerState) {
    let session = EncounterSession(name: "Test")
    session.add(
      player: PlayerState(
        name: "Aric", maxHP: 6, maxStress: 6, evasion: 12,
        thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3
      ))
    let player = session.playerSlots[0]
    return (session, player)
  }

  // MARK: - applyCondition

  @Test func applyConditionAddsToPlayerSlot() {
    let (session, player) = makeSession()
    session.applyCondition(.hidden, to: player.id)
    #expect(session.playerSlots[0].conditions.contains(.hidden))
  }

  @Test func applyConditionIsIdempotent() {
    let (session, player) = makeSession()
    session.applyCondition(.restrained, to: player.id)
    session.applyCondition(.restrained, to: player.id)
    #expect(session.playerSlots[0].conditions.count == 1)
  }

  @Test func applyMultipleConditions() {
    let (session, player) = makeSession()
    session.applyCondition(.hidden, to: player.id)
    session.applyCondition(.vulnerable, to: player.id)
    #expect(session.playerSlots[0].conditions.count == 2)
    #expect(session.playerSlots[0].conditions.contains(.hidden))
    #expect(session.playerSlots[0].conditions.contains(.vulnerable))
  }

  // MARK: - removeCondition

  @Test func removeConditionClearsFromPlayerSlot() {
    let (session, player) = makeSession()
    session.applyCondition(.restrained, to: player.id)
    session.removeCondition(.restrained, from: player.id)
    #expect(session.playerSlots[0].conditions.isEmpty)
  }

  @Test func removeConditionOnlyRemovesTarget() {
    let (session, player) = makeSession()
    session.applyCondition(.hidden, to: player.id)
    session.applyCondition(.vulnerable, to: player.id)
    session.removeCondition(.hidden, from: player.id)
    #expect(!session.playerSlots[0].conditions.contains(.hidden))
    #expect(session.playerSlots[0].conditions.contains(.vulnerable))
  }

  @Test func removeConditionNotPresentIsNoOp() {
    let (session, player) = makeSession()
    session.removeCondition(.restrained, from: player.id)
    #expect(session.playerSlots[0].conditions.isEmpty)
  }

  // MARK: - Strip row accessibility label

  @Test func conditionNamesIncludedInAccessibilityLabelWhenActive() {
    let (session, player) = makeSession()
    session.applyCondition(.restrained, to: player.id)
    let updated = session.playerSlots[0]
    let label =
      updated.conditions.isEmpty
      ? updated.name
      : updated.name + ", "
        + updated.conditions.map(\.displayName).sorted().joined(separator: ", ")
    #expect(label.contains("Restrained"))
    #expect(label.contains("Aric"))
  }

  @Test func accessibilityLabelIsNameOnlyWhenNoConditions() {
    let (_, player) = makeSession()
    let label =
      player.conditions.isEmpty
      ? player.name
      : player.name + ", "
        + player.conditions.map(\.displayName).sorted().joined(separator: ", ")
    #expect(label == "Aric")
  }
}
