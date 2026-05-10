//
//  EncounterRunnerViewTests.swift
//  EncounterTests
//
//  Tests for EncounterRunnerView lifecycle actions: Pause and End Encounter.
//  Tests verify the model-level behavior that each action triggers, and that
//  the editor correctly reflects a paused session (Resume button visible).
//

import DHKit
import DHModels
import Foundation
import Testing

@testable import Encounter

@MainActor
@Suite("EncounterRunnerView")
struct EncounterRunnerViewTests {

  // MARK: - Helpers

  private func makeAdversary(id: String = "goblin") -> Adversary {
    Adversary(
      id: id, name: "Goblin", tier: 1, role: .minion,
      flavorText: "", difficulty: 10,
      thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
      attackModifier: "+2", attackName: "Bite",
      attackRange: .veryClose, damage: "1d4 phy"
    )
  }

  private func makeDefinitionAndSession() -> (EncounterDefinition, EncounterSession) {
    var def = EncounterDefinition(name: "Goblin Ambush")
    def.adversaryIDs = ["goblin"]
    let session = EncounterSession(name: def.name, definitionID: def.id)
    return (def, session)
  }

  private func tempDir() -> URL {
    let dir = FileManager.default.temporaryDirectory
      .appending(path: "EncounterRunnerViewTests-\(UUID())", directoryHint: .isDirectory)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
  }

  // MARK: - Pause action

  @Test func pauseActionChangesSessionPhase() {
    let (_, session) = makeDefinitionAndSession()
    #expect(session.phase == .running)
    session.pause()
    #expect(session.phase == .paused)
  }

  @Test func pausedSessionPersistedWithPausedPhase() async throws {
    let dir = tempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let store = SessionStore(directory: dir)
    let (_, session) = makeDefinitionAndSession()

    session.pause()
    await store.save(session)

    let registry = SessionRegistry()
    await store.load(into: registry)

    let defID = try #require(session.definitionID)
    let restored = try #require(registry.sessions[defID])
    #expect(restored.phase == .paused)
  }

  // MARK: - End Encounter action

  @Test func endEncounterClearsSessionFromRegistry() {
    let (def, session) = makeDefinitionAndSession()
    let registry = SessionRegistry()
    registry.insert(session)
    #expect(registry.sessions[def.id] != nil)

    registry.clearSession(for: def.id)

    #expect(registry.sessions[def.id] == nil)
  }

  @Test func endEncounterDeletesPersistedSession() async {
    let dir = tempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let store = SessionStore(directory: dir)
    let (_, session) = makeDefinitionAndSession()

    await store.save(session)
    await store.delete(sessionID: session.id)

    let registry = SessionRegistry()
    await store.load(into: registry)
    #expect(registry.sessions.isEmpty)
  }

  // MARK: - Editor reflects paused session

  @Test func editorShowsResumeWhenSessionIsPaused() {
    var def = EncounterDefinition(name: "Goblin Ambush")
    def.adversaryIDs = ["goblin"]
    let registry = SessionRegistry()
    let session = EncounterSession(name: def.name, phase: .paused, definitionID: def.id)
    registry.insert(session)

    let compendium = Compendium()
    compendium.addAdversary(makeAdversary())
    let editor = EncounterEditorView(
      definition: def,
      store: EncounterStore(directory: .temporaryDirectory),
      compendium: compendium,
      contentStore: ContentStore(contentDirectory: .temporaryDirectory, compendium: compendium),
      sessionRegistry: registry,
      sessionStore: SessionStore(directory: .temporaryDirectory),
      playerStore: PlayerStore(directory: .temporaryDirectory)
    )

    #expect(
      editor.pausedSession != nil, "Editor should expose paused session for the Resume button")
  }
}
