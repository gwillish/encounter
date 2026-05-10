//
//  EncounterEditorViewTests.swift
//  EncounterTests
//
//  Unit tests for EncounterEditorView.
//  Tests the pausedSession computed property, which drives the Run vs Resume
//  toolbar button label and action.
//

import DHKit
import DHModels
import SwiftUI
import Testing
import ViewInspector

@testable import Encounter

@MainActor
@Suite("EncounterEditorView")
struct EncounterEditorViewTests {

  // MARK: - Helpers

  private static func makeAdversary(id: String = "goblin") -> Adversary {
    Adversary(
      id: id, name: "Goblin", tier: 1, role: .minion,
      flavorText: "", difficulty: 10,
      thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
      attackModifier: "+2", attackName: "Bite",
      attackRange: .veryClose, damage: "1d4 phy"
    )
  }

  private func makeDefinition() -> EncounterDefinition {
    var def = EncounterDefinition(name: "Goblin Ambush")
    def.adversaryIDs = ["goblin"]
    return def
  }

  private func makeSUT(
    definition: EncounterDefinition,
    sessionRegistry: SessionRegistry? = nil
  ) -> EncounterEditorView {
    let compendium = Compendium()
    compendium.addAdversary(Self.makeAdversary())
    return EncounterEditorView(
      definition: definition,
      store: EncounterStore(directory: .temporaryDirectory),
      compendium: compendium,
      contentStore: ContentStore(contentDirectory: .temporaryDirectory, compendium: compendium),
      sessionRegistry: sessionRegistry ?? SessionRegistry(),
      sessionStore: SessionStore(directory: .temporaryDirectory),
      playerStore: PlayerStore(directory: .temporaryDirectory)
    )
  }

  // MARK: - Run vs Resume

  // pausedSession drives the toolbar button: nil → Run label; non-nil → Resume label.

  @Test func runButtonShownWhenNoSession() {
    let def = makeDefinition()
    let sut = makeSUT(definition: def)
    #expect(sut.pausedSession == nil, "No paused session: Run button should be shown")
  }

  @Test func resumeButtonShownWhenPausedSessionExists() {
    let def = makeDefinition()
    let registry = SessionRegistry()
    let session = EncounterSession(name: def.name, phase: .paused, definitionID: def.id)
    registry.insert(session)

    let sut = makeSUT(definition: def, sessionRegistry: registry)
    #expect(sut.pausedSession != nil, "Paused session exists: Resume button should be shown")
  }

  @Test func runButtonShownWhenSessionIsRunning() {
    let def = makeDefinition()
    let registry = SessionRegistry()
    let session = EncounterSession(name: def.name, phase: .running, definitionID: def.id)
    registry.insert(session)

    let sut = makeSUT(definition: def, sessionRegistry: registry)
    #expect(sut.pausedSession == nil, "Running session: Run button should be shown, not Resume")
  }
}
