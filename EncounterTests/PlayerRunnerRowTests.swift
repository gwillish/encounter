//
//  PlayerRunnerRowTests.swift
//  EncounterTests
//
//  ViewInspector unit tests for PlayerRunnerSection's collapsed row button.
//  The accessibility label and identifier for the collapsed player row live
//  on the Button in PlayerRunnerSection (not on PlayerRunnerRow itself),
//  matching the same pattern as AdversaryRunnerRowTests.
//

import DHKit
import DHModels
import SwiftUI
import Testing
import ViewInspector

@testable import Encounter

@MainActor
@Suite("PlayerRunnerRow")
struct PlayerRunnerRowTests {

  private static func makeSession(player: PlayerState) -> EncounterSession {
    EncounterSession(name: "Test", playerSlots: [player])
  }

  private static func makeSection(
    player: PlayerState,
    expandedPlayerID: UUID? = nil
  ) -> PlayerRunnerSection {
    let session = makeSession(player: player)
    var id: UUID? = expandedPlayerID
    let binding = Binding(get: { id }, set: { id = $0 })
    return PlayerRunnerSection(slots: [player], expandedPlayerID: binding, session: session)
  }

  private static func makeSection(
    player: PlayerState,
    binding: Binding<UUID?>
  ) -> PlayerRunnerSection {
    let session = makeSession(player: player)
    return PlayerRunnerSection(slots: [player], expandedPlayerID: binding, session: session)
  }

  // MARK: - Button action sets expandedPlayerID

  @Test func buttonTapSetsExpandedPlayerID() throws {
    let player = PlayerState(
      name: "Aric", maxHP: 6, maxStress: 6, evasion: 12,
      thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3)
    var expandedID: UUID? = nil
    let binding = Binding(get: { expandedID }, set: { expandedID = $0 })
    let sut = Self.makeSection(player: player, binding: binding)

    let button = try sut.inspect().find(ViewType.Button.self)
    try button.tap()

    #expect(
      expandedID == player.id, "Tapping the row should set expandedPlayerID to the player's ID")
  }

  @Test func expandedPlayerIDShowsCard() throws {
    let player = PlayerState(
      name: "Aric", maxHP: 6, maxStress: 6, evasion: 12,
      thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3)
    let sut = Self.makeSection(player: player, expandedPlayerID: player.id)

    let buttons = try sut.inspect().findAll(ViewType.Button.self)
    let identifiers = buttons.compactMap { try? $0.accessibilityIdentifier() }

    #expect(
      identifiers.contains("runner.player-card.collapse-button"),
      "When player is expanded, PlayerRunnerCard's collapse button should be present")
    #expect(
      !identifiers.contains("runner.player-row"),
      "When player is expanded, the collapsed row button should not be present")
  }

  // MARK: - Accessibility label

  @Test func accessibilityLabelWithNoConditionsIsPlayerName() throws {
    let player = PlayerState(
      name: "Aric", maxHP: 6, maxStress: 6, evasion: 12,
      thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3)
    let sut = Self.makeSection(player: player)

    let button = try sut.inspect().find(ViewType.Button.self)
    #expect(try button.accessibilityLabel().string() == "Aric")
  }

  @Test func accessibilityLabelWithConditionContainsConditionName() throws {
    let player = PlayerState(
      name: "Aric", maxHP: 6, maxStress: 6, evasion: 12,
      thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3,
      conditions: [.hidden])
    let sut = Self.makeSection(player: player)

    let button = try sut.inspect().find(ViewType.Button.self)
    let label = try button.accessibilityLabel().string()

    #expect(
      label.contains("Hidden"),
      "Label '\(label)' should include the condition name when a condition is active")
  }

  @Test func accessibilityLabelWithNoConditionsDoesNotContainHidden() throws {
    let player = PlayerState(
      name: "Aric", maxHP: 6, maxStress: 6, evasion: 12,
      thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3)
    let sut = Self.makeSection(player: player)

    let button = try sut.inspect().find(ViewType.Button.self)
    let label = try button.accessibilityLabel().string()

    #expect(!label.contains("Hidden"), "Label should not mention Hidden when no condition is set")
  }

  // MARK: - AX identifier

  @Test func collapsedRowHasCorrectIdentifier() throws {
    let player = PlayerState(
      name: "Aric", maxHP: 6, maxStress: 6, evasion: 12,
      thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3)
    let sut = Self.makeSection(player: player)

    let button = try sut.inspect().find(ViewType.Button.self)
    #expect(try button.accessibilityIdentifier() == "runner.player-row")
  }
}
