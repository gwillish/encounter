//
//  PlayerStripRowTests.swift
//  EncounterTests
//
//  ViewInspector unit tests for PlayerStripRow.
//  Validates binding behavior and AX label content without a simulator.
//

import DHKit
import DHModels
import SwiftUI
import Testing
import ViewInspector

@testable import Encounter

@MainActor
@Suite("PlayerStripRow")
struct PlayerStripRowTests {

  private static func makeSession(playerName: String = "Aric") -> EncounterSession {
    EncounterSession(
      name: "Test",
      playerSlots: [
        PlayerState(
          name: playerName,
          maxHP: 6, maxStress: 6, evasion: 12,
          thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3)
      ]
    )
  }

  // MARK: - Button action sets editingPlayer binding

  @Test func buttonTapSetsEditingPlayerBinding() throws {
    let session = Self.makeSession()
    let player = session.playerSlots[0]
    var editingPlayer: PlayerState? = nil
    let binding = Binding(get: { editingPlayer }, set: { editingPlayer = $0 })

    let sut = PlayerStripRow(player: player, session: session, editingPlayer: binding)
    let button = try sut.inspect().implicitAnyView().button()
    try button.tap()

    #expect(
      editingPlayer?.name == "Aric",
      "Tapping the player row should set editingPlayer to the tapped player")
  }

  // MARK: - accessibilityLabel reflects conditions

  @Test func accessibilityLabelWithNoConditionsIsPlayerName() throws {
    let session = Self.makeSession()
    let player = session.playerSlots[0]
    var editingPlayer: PlayerState? = nil
    let binding = Binding(get: { editingPlayer }, set: { editingPlayer = $0 })

    let sut = PlayerStripRow(player: player, session: session, editingPlayer: binding)
    let label = try sut.inspect().implicitAnyView().button().accessibilityLabel()
    #expect(try label.string() == "Aric")
  }

  @Test func accessibilityLabelWithHiddenConditionContainsHidden() throws {
    let session = EncounterSession(
      name: "Test",
      playerSlots: [
        PlayerState(
          name: "Aric",
          maxHP: 6, maxStress: 6, evasion: 12,
          thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3,
          conditions: [.hidden])
      ]
    )
    let player = session.playerSlots[0]
    var editingPlayer: PlayerState? = nil
    let binding = Binding(get: { editingPlayer }, set: { editingPlayer = $0 })

    let sut = PlayerStripRow(player: player, session: session, editingPlayer: binding)
    let label = try sut.inspect().implicitAnyView().button().accessibilityLabel()
    #expect(
      try label.string().contains("Hidden"),
      "Label should include the condition name when a condition is active")
  }

  @Test func accessibilityLabelWithNoConditionsDoesNotContainHidden() throws {
    let session = Self.makeSession()
    let player = session.playerSlots[0]
    var editingPlayer: PlayerState? = nil
    let binding = Binding(get: { editingPlayer }, set: { editingPlayer = $0 })

    let sut = PlayerStripRow(player: player, session: session, editingPlayer: binding)
    let label = try sut.inspect().implicitAnyView().button().accessibilityLabel()
    #expect(
      try !label.string().contains("Hidden"),
      "Label should not include Hidden when no condition is set")
  }

  // MARK: - accessibilityIdentifier

  @Test func playerRowHasCorrectAccessibilityIdentifier() throws {
    let session = Self.makeSession()
    let player = session.playerSlots[0]
    var editingPlayer: PlayerState? = nil
    let binding = Binding(get: { editingPlayer }, set: { editingPlayer = $0 })

    let sut = PlayerStripRow(player: player, session: session, editingPlayer: binding)
    let button = try sut.inspect().implicitAnyView().button()
    #expect(try button.accessibilityIdentifier() == "runner.player-row")
  }
}
