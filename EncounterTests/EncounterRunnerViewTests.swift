//
//  EncounterRunnerViewTests.swift
//  EncounterTests
//
//  Tests for EncounterRunnerView lifecycle actions: Pause, Resume, End Encounter, Reset Session.
//  Tests verify the model-level behavior each action triggers (phase transitions, registry
//  mutations, persistence round-trips).
//
//  Button-tap verification (that the actual SwiftUI buttons invoke these operations and dismiss)
//  lives in EncounterUITests/.
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

  private func makeDefinitionAndSession() -> (EncounterDefinition, EncounterSession) {
    var def = EncounterDefinition(name: "Goblin Ambush")
    def.adversaryIDs = ["goblin"]
    let session = EncounterSession(name: def.name, definitionID: def.id)
    return (def, session)
  }

  private static func tempDir() -> URL {
    let dir = FileManager.default.temporaryDirectory
      .appending(path: "EncounterRunnerViewTests-\(UUID())", directoryHint: .isDirectory)
    try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
  }

  // MARK: - Pause action

  @Test func pauseActionChangesSessionPhase() {
    let (_, session) = makeDefinitionAndSession()
    #expect(session.phase == .running)
    session.pause()
    #expect(session.phase == .paused)
  }

  @Test func resumeActionChangesSessionPhaseToRunning() {
    let (_, session) = makeDefinitionAndSession()
    session.pause()
    session.resume()
    #expect(session.phase == .running)
  }

  @Test func pausedSessionPersistedWithPausedPhase() async throws {
    let dir = Self.tempDir()
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
    let dir = Self.tempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let store = SessionStore(directory: dir)
    let (_, session) = makeDefinitionAndSession()

    await store.save(session)
    await store.delete(sessionID: session.id)

    let registry = SessionRegistry()
    await store.load(into: registry)
    #expect(registry.sessions.isEmpty)
  }

}
