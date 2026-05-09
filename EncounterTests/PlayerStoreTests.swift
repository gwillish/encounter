//
//  PlayerStoreTests.swift
//  EncounterTests
//
//  Unit tests for PlayerStore: add/update/delete players, party membership
//  operations, sorted-by-name invariant, and JSON round-trip persistence.
//

import DHModels
import Foundation
import Testing

@testable import Encounter

@MainActor struct PlayerStoreTests {

  // MARK: - Fixtures

  private func makeStore() -> PlayerStore {
    let dir = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    return PlayerStore(directory: dir)
  }

  private func makePlayer(name: String = "Aric", level: Int = 1) -> Player {
    Player(
      name: name, level: level, maxHP: 6, maxStress: 6, evasion: 12,
      thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3
    )
  }

  // MARK: - addPlayer

  @Test func addPlayerAppendsToPlayers() async {
    let store = makeStore()
    await store.addPlayer(makePlayer())
    #expect(store.players.count == 1)
  }

  @Test func addPlayerSortsByName() async {
    let store = makeStore()
    await store.addPlayer(makePlayer(name: "Zara"))
    await store.addPlayer(makePlayer(name: "Aric"))
    await store.addPlayer(makePlayer(name: "Mira"))
    #expect(store.players.map(\.name) == ["Aric", "Mira", "Zara"])
  }

  // MARK: - updatePlayer

  @Test func updatePlayerReplacesExistingRecord() async {
    let store = makeStore()
    var player = makePlayer()
    await store.addPlayer(player)
    player.name = "Aric the Bold"
    await store.updatePlayer(player)
    #expect(store.players.count == 1)
    #expect(store.players[0].name == "Aric the Bold")
  }

  @Test func updatePlayerPreservesID() async {
    let store = makeStore()
    let player = makePlayer()
    let originalID = player.id
    await store.addPlayer(player)
    var updated = player
    updated.maxHP = 10
    await store.updatePlayer(updated)
    #expect(store.players[0].id == originalID)
    #expect(store.players[0].maxHP == 10)
  }

  @Test func updatePlayerResortsByName() async {
    let store = makeStore()
    var aric = makePlayer(name: "Aric")
    await store.addPlayer(aric)
    await store.addPlayer(makePlayer(name: "Mira"))
    aric.name = "Zara"
    await store.updatePlayer(aric)
    #expect(store.players.map(\.name) == ["Mira", "Zara"])
  }

  @Test func updateUnknownPlayerIsNoOp() async {
    let store = makeStore()
    await store.addPlayer(makePlayer(name: "Aric"))
    let stranger = makePlayer(name: "Stranger")
    await store.updatePlayer(stranger)
    #expect(store.players.count == 1)
    #expect(store.players[0].name == "Aric")
  }

  // MARK: - deletePlayer

  @Test func deletePlayerRemovesFromList() async {
    let store = makeStore()
    let player = makePlayer()
    await store.addPlayer(player)
    await store.deletePlayer(id: player.id)
    #expect(store.players.isEmpty)
  }

  @Test func deletePlayerAlsoRemovesFromParty() async {
    let store = makeStore()
    let player = makePlayer()
    await store.addPlayer(player)
    await store.addToParty(id: player.id)
    #expect(store.party.playerIDs.contains(player.id))
    await store.deletePlayer(id: player.id)
    #expect(!store.party.playerIDs.contains(player.id))
    #expect(store.players.isEmpty)
  }

  @Test func deleteUnknownPlayerIsNoOp() async {
    let store = makeStore()
    await store.addPlayer(makePlayer())
    await store.deletePlayer(id: UUID())
    #expect(store.players.count == 1)
  }

  // MARK: - addToParty / removeFromParty

  @Test func addToPartyAddsPlayerID() async {
    let store = makeStore()
    let player = makePlayer()
    await store.addPlayer(player)
    await store.addToParty(id: player.id)
    #expect(store.party.playerIDs.contains(player.id))
  }

  @Test func addToPartyIsIdempotent() async {
    let store = makeStore()
    let player = makePlayer()
    await store.addPlayer(player)
    await store.addToParty(id: player.id)
    await store.addToParty(id: player.id)
    #expect(store.party.playerIDs.count == 1)
  }

  @Test func removeFromPartyKeepsPlayerInStore() async {
    let store = makeStore()
    let player = makePlayer()
    await store.addPlayer(player)
    await store.addToParty(id: player.id)
    await store.removeFromParty(id: player.id)
    #expect(!store.party.playerIDs.contains(player.id))
    #expect(store.players.contains(player))
  }

  // MARK: - activePartyPlayers

  @Test func activePartyPlayersReturnsOnlyPartyMembers() async {
    let store = makeStore()
    let p1 = makePlayer(name: "Aric")
    let p2 = makePlayer(name: "Lira")
    await store.addPlayer(p1)
    await store.addPlayer(p2)
    await store.addToParty(id: p1.id)
    #expect(store.activePartyPlayers.count == 1)
    #expect(store.activePartyPlayers[0].id == p1.id)
  }

  @Test func activePartyPlayersPreservesPartyOrder() async {
    let store = makeStore()
    let p1 = makePlayer(name: "Zara")
    let p2 = makePlayer(name: "Aric")
    let p3 = makePlayer(name: "Mira")
    await store.addPlayer(p1)
    await store.addPlayer(p2)
    await store.addPlayer(p3)
    // Add to party in a specific order — should not be alphabet-sorted.
    await store.addToParty(id: p1.id)
    await store.addToParty(id: p2.id)
    await store.addToParty(id: p3.id)
    #expect(store.activePartyPlayers.map(\.name) == ["Zara", "Aric", "Mira"])
  }

  // MARK: - resetAll

  @Test func resetAllWipesPlayersAndParty() async {
    let store = makeStore()
    let player = makePlayer()
    await store.addPlayer(player)
    await store.addToParty(id: player.id)
    await store.resetAll()
    #expect(store.players.isEmpty)
    #expect(store.party.playerIDs.isEmpty)
  }

  // MARK: - Persistence round-trip

  @Test func persistAndReloadPlayers() async {
    let dir = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    let store1 = PlayerStore(directory: dir)
    let player = makePlayer(name: "Aric")
    await store1.addPlayer(player)

    let store2 = PlayerStore(directory: dir)
    await store2.load()
    #expect(store2.players.count == 1)
    #expect(store2.players[0].name == "Aric")
    #expect(store2.players[0].id == player.id)
  }

  @Test func persistAndReloadPlayerLevel() async throws {
    let dir = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    let store1 = PlayerStore(directory: dir)
    await store1.addPlayer(makePlayer(name: "Aric", level: 5))

    let store2 = PlayerStore(directory: dir)
    await store2.load()
    let player = try #require(store2.players.first, "Player should have persisted")
    #expect(player.level == 5)
  }

  @Test func persistAndReloadParty() async {
    let dir = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    let store1 = PlayerStore(directory: dir)
    let player = makePlayer()
    await store1.addPlayer(player)
    await store1.addToParty(id: player.id)

    let store2 = PlayerStore(directory: dir)
    await store2.load()
    #expect(store2.party.playerIDs.contains(player.id))
  }

  @Test func resetAllPersistsEmptyState() async {
    let dir = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    let store1 = PlayerStore(directory: dir)
    await store1.addPlayer(makePlayer())
    await store1.resetAll()

    let store2 = PlayerStore(directory: dir)
    await store2.load()
    #expect(store2.players.isEmpty)
    #expect(store2.party.playerIDs.isEmpty)
  }

  @Test func loadFromEmptyDirectoryStartsBlank() async {
    let store = makeStore()
    await store.load()
    #expect(store.players.isEmpty)
    #expect(store.party.playerIDs.isEmpty)
    #expect(store.loadError == nil)
  }

  // MARK: - hidePlayer / showPlayer

  @Test func hidePlayerAddsToHiddenIDs() async {
    let store = makeStore()
    let player = makePlayer()
    await store.addPlayer(player)
    await store.hidePlayer(id: player.id)
    #expect(store.hiddenPlayerIDs.contains(player.id))
  }

  @Test func showPlayerRemovesFromHiddenIDs() async {
    let store = makeStore()
    let player = makePlayer()
    await store.addPlayer(player)
    await store.hidePlayer(id: player.id)
    await store.showPlayer(id: player.id)
    #expect(!store.hiddenPlayerIDs.contains(player.id))
  }

  @Test func hideIsIdempotent() async {
    let store = makeStore()
    let player = makePlayer()
    await store.addPlayer(player)
    await store.hidePlayer(id: player.id)
    await store.hidePlayer(id: player.id)
    #expect(store.hiddenPlayerIDs.count == 1)
  }

  @Test func showVisiblePlayerIsNoOp() async {
    let store = makeStore()
    let player = makePlayer()
    await store.addPlayer(player)
    await store.showPlayer(id: player.id)
    #expect(store.hiddenPlayerIDs.isEmpty)
  }

  @Test func hiddenPlayerExcludedFromActivePartyPlayers() async {
    let store = makeStore()
    let p1 = makePlayer(name: "Aric")
    let p2 = makePlayer(name: "Lira")
    await store.addPlayer(p1)
    await store.addPlayer(p2)
    await store.addToParty(id: p1.id)
    await store.addToParty(id: p2.id)
    await store.hidePlayer(id: p1.id)
    #expect(store.activePartyPlayers.count == 1)
    #expect(store.activePartyPlayers[0].id == p2.id)
  }

  @Test func hiddenPlayerNotInPartyIsTracked() async {
    let store = makeStore()
    let player = makePlayer()
    await store.addPlayer(player)
    // Not added to party — hidden is a roster-wide flag.
    await store.hidePlayer(id: player.id)
    #expect(store.hiddenPlayerIDs.contains(player.id))
  }

  @Test func deletePlayerAlsoRemovesFromHiddenIDs() async {
    let store = makeStore()
    let player = makePlayer()
    await store.addPlayer(player)
    await store.hidePlayer(id: player.id)
    await store.deletePlayer(id: player.id)
    #expect(!store.hiddenPlayerIDs.contains(player.id))
    #expect(store.players.isEmpty)
  }

  @Test func hiddenIDsRoundTripsThroughPersistence() async throws {
    let dir = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    defer { try? FileManager.default.removeItem(atPath: dir.path) }
    let store1 = PlayerStore(directory: dir)
    let player = makePlayer()
    await store1.addPlayer(player)
    await store1.hidePlayer(id: player.id)

    let store2 = PlayerStore(directory: dir)
    await store2.load()
    #expect(store2.hiddenPlayerIDs.contains(player.id))
  }

  @Test func showAfterReloadRoundTrips() async throws {
    let dir = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    defer { try? FileManager.default.removeItem(atPath: dir.path) }
    let store1 = PlayerStore(directory: dir)
    let player = makePlayer()
    await store1.addPlayer(player)
    await store1.hidePlayer(id: player.id)
    await store1.showPlayer(id: player.id)

    let store2 = PlayerStore(directory: dir)
    await store2.load()
    #expect(!store2.hiddenPlayerIDs.contains(player.id))
  }

  @Test func resetAllClearsHiddenIDs() async {
    let store = makeStore()
    let player = makePlayer()
    await store.addPlayer(player)
    await store.hidePlayer(id: player.id)
    await store.resetAll()
    #expect(store.hiddenPlayerIDs.isEmpty)
  }

  // MARK: - relocate

  @Test func relocateClearsInMemoryState() async {
    let store = makeStore()
    await store.addPlayer(makePlayer())
    let newDir = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    store.relocate(to: newDir)
    #expect(store.players.isEmpty)
    #expect(store.party.playerIDs.isEmpty)
  }
}
