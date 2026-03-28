//
//  ContentSourceIntegrationTests.swift
//  EncounterTests
//
//  Integration tests for the full import → verify → remove lifecycle using
//  the sample-homebrew.dhpack fixture in EncounterTests/Fixtures/.
//

import DHKit
import DHModels
import Foundation
import Testing

@testable import Encounter

// Used only to resolve the test bundle; Bundle.module is not available for
// app test targets (only Swift packages).
private final class FixtureBundleToken {}

@MainActor struct ContentSourceIntegrationTests {

  private func makeStore(compendium: Compendium? = nil) -> ContentStore {
    let dir = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    return ContentStore(contentDirectory: dir, compendium: compendium ?? Compendium())
  }

  private func fixtureURL() throws -> URL {
    let bundle = Bundle(for: FixtureBundleToken.self)
    return try #require(
      bundle.url(forResource: "sample-homebrew", withExtension: "dhpack"),
      "sample-homebrew.dhpack fixture not found in test bundle"
    )
  }

  // MARK: - Import

  @Test func importPackRegistersSource() async throws {
    let store = makeStore()
    await store.loadOnStartup()
    await store.importPack(from: try fixtureURL())
    #expect(store.sources["sample-homebrew"] != nil)
    let source = try #require(store.sources["sample-homebrew"])
    #expect(source.isLocalImport)
    #expect(source.name == "sample-homebrew")
    #expect(source.lastFetched != nil)
  }

  @Test func importPackLoadsAdversariesIntoCompendium() async throws {
    let compendium = Compendium()
    let store = makeStore(compendium: compendium)
    await store.loadOnStartup()
    await store.importPack(from: try fixtureURL())
    #expect(compendium.adversariesByID["test-goblin"] != nil)
    #expect(compendium.adversariesByID["test-troll"] != nil)
    #expect(compendium.environmentsByID["test-dungeon"] != nil)
  }

  // MARK: - Remove

  @Test func removeSourceEvictsContentFromCompendium() async throws {
    let compendium = Compendium()
    let store = makeStore(compendium: compendium)
    await store.loadOnStartup()
    await store.importPack(from: try fixtureURL())
    #expect(compendium.adversariesByID["test-goblin"] != nil)

    await store.removeSource(id: "sample-homebrew")

    #expect(store.sources["sample-homebrew"] == nil)
    #expect(compendium.adversariesByID["test-goblin"] == nil)
    #expect(compendium.adversariesByID["test-troll"] == nil)
    #expect(compendium.environmentsByID["test-dungeon"] == nil)
  }
}
