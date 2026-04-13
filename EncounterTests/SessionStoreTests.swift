//
//  SessionStoreTests.swift
//  EncounterTests
//
//  Unit tests for SessionStore: load/save/delete round-trips,
//  integration with SessionRegistry.insert(_:).
//

import DHKit
import DHModels
import Foundation
import Testing

@testable import Encounter

@MainActor struct SessionStoreTests {

  private func makeCompendium() -> Compendium {
    let c = Compendium()
    c.addAdversary(
      Adversary(
        id: "goblin", name: "Goblin", tier: 1, role: .minion,
        flavorText: "Small and cunning.", difficulty: 10,
        thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
        attackModifier: "+2", attackName: "Rusty Blade",
        attackRange: .veryClose, damage: "1d4 phy"
      ))
    return c
  }

  private func makeSession() -> (EncounterSession, EncounterDefinition) {
    let definition = EncounterDefinition(name: "Test Battle", adversaryIDs: ["goblin"])
    let session = EncounterSession.make(from: definition, using: makeCompendium())
    return (session, definition)
  }

  private func tempDir() -> URL {
    FileManager.default.temporaryDirectory
      .appending(path: "SessionStoreTests-\(UUID())", directoryHint: .isDirectory)
  }

  // MARK: - save / load round-trip

  @Test func saveAndLoadRestoresSession() async throws {
    let dir = tempDir()
    let store = SessionStore(directory: dir)
    let (session, _) = makeSession()
    session.fearPool = 5

    await store.save(session)

    let registry = SessionRegistry()
    await store.load(into: registry)

    let defID = try #require(session.definitionID)
    let restored = try #require(registry.sessions[defID])
    #expect(restored.id == session.id)
    #expect(restored.fearPool == 5)
  }

  @Test func loadSetsIsLoaded() async {
    let dir = tempDir()
    let store = SessionStore(directory: dir)
    #expect(store.isLoaded == false)

    let registry = SessionRegistry()
    await store.load(into: registry)

    #expect(store.isLoaded == true)
  }

  @Test func loadIntoEmptyDirectorySucceeds() async {
    let dir = tempDir()
    let store = SessionStore(directory: dir)
    let registry = SessionRegistry()

    await store.load(into: registry)

    #expect(registry.sessions.isEmpty)
    #expect(store.isLoaded == true)
  }

  // MARK: - adversary slot round-trip

  @Test func saveAndLoadPreservesAdversarySlotState() async throws {
    let dir = tempDir()
    let store = SessionStore(directory: dir)
    let (session, _) = makeSession()

    // Apply damage and stress to the goblin slot so we can verify both round-trip.
    let slotID = try #require(session.adversarySlots.first?.id)
    session.applyDamage(2, to: slotID)
    session.applyStress(1, to: slotID)

    await store.save(session)

    let registry = SessionRegistry()
    await store.load(into: registry)

    let defID = try #require(session.definitionID)
    let restored = try #require(registry.sessions[defID])
    let restoredSlot = try #require(restored.adversarySlots.first)
    // Goblin starts with hp=3; after 2 damage → currentHP should be 1.
    #expect(restoredSlot.currentHP == 1)
    // Goblin starts with stress=2 max; after 1 stress → currentStress should be 1.
    #expect(restoredSlot.currentStress == 1)
  }

  // MARK: - saveAll

  @Test func saveAllPersistsMultipleSessions() async {
    let dir = tempDir()
    let store = SessionStore(directory: dir)
    let compendium = makeCompendium()

    let def1 = EncounterDefinition(name: "Battle 1", adversaryIDs: ["goblin"])
    let def2 = EncounterDefinition(name: "Battle 2", adversaryIDs: ["goblin", "goblin"])
    let registry = SessionRegistry()
    _ = registry.session(for: def1, compendium: compendium)
    _ = registry.session(for: def2, compendium: compendium)

    await store.saveAll(from: registry)

    let fresh = SessionRegistry()
    await store.load(into: fresh)

    #expect(fresh.sessions.count == 2)
  }

  // MARK: - delete

  @Test func deleteRemovesPersistedFile() async {
    let dir = tempDir()
    let store = SessionStore(directory: dir)
    let (session, _) = makeSession()

    await store.save(session)
    await store.delete(sessionID: session.id)

    let registry = SessionRegistry()
    await store.load(into: registry)

    #expect(registry.sessions.isEmpty)
  }

  @Test func deleteNeverSavedSessionIsNoop() async {
    let dir = tempDir()
    let store = SessionStore(directory: dir)

    // Deleting a session that was never saved should not throw or crash.
    await store.delete(sessionID: UUID())

    let registry = SessionRegistry()
    await store.load(into: registry)
    #expect(registry.sessions.isEmpty)
  }

  // MARK: - corrupt file resilience

  @Test func loadIgnoresCorruptFile() async throws {
    let dir = tempDir()
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    // Write a file that matches the .session.json suffix but contains invalid JSON.
    let badFile = dir.appending(path: "corrupt.session.json")
    try "not valid json".data(using: .utf8)!.write(to: badFile)

    let store = SessionStore(directory: dir)
    let registry = SessionRegistry()
    await store.load(into: registry)

    #expect(registry.sessions.isEmpty)
    #expect(store.isLoaded == true)
  }

  // MARK: - insert guard

  @Test func loadDoesNotOverwriteExistingSession() async {
    let dir = tempDir()
    let store = SessionStore(directory: dir)
    let (session, definition) = makeSession()

    // Save a session with fearPool = 3
    session.fearPool = 3
    await store.save(session)

    // Pre-populate the registry with a different session for the same definition
    let registry = SessionRegistry()
    let liveSession = SessionRegistry().session(for: definition, compendium: makeCompendium())
    liveSession.fearPool = 99
    // Manually insert to simulate a live session already being present
    registry.insert(liveSession)

    // load should not overwrite the existing live session
    await store.load(into: registry)

    // The live session (fearPool=99) should still be there, not the saved one (fearPool=3)
    let result = registry.sessions[definition.id]
    #expect(result?.fearPool == 99)
  }
}
