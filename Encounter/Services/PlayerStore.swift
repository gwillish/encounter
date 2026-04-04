//
//  PlayerStore.swift
//  Encounter
//
//  Persistence layer for Player and Party records.
//  Players are stored as players.json and the active party as party.json
//  in a single flat directory, using the same iCloud ubiquity container
//  root as EncounterStore.
//

import DHModels
import Foundation
import Observation

// MARK: - PlayerStore

/// Persistence layer for ``Player`` and ``Party`` records.
///
/// `PlayerStore` maintains the roster of all known players and the single
/// active party. Both are persisted as JSON files in a flat directory that
/// lives alongside the Encounters and Content directories.
///
/// Inject into the SwiftUI environment at app launch:
///
/// ```swift
/// @State private var playerStore = PlayerStore(directory: PlayerStore.localDirectory)
///
/// ContentView()
///     .environment(playerStore)
///     .task {
///         let dir = await EncounterStore.defaultDirectory()
///         let playersDir = dir.deletingLastPathComponent()
///             .appending(path: "Players", directoryHint: .isDirectory)
///         playerStore.relocate(to: playersDir)
///         await playerStore.load()
///     }
/// ```
@MainActor
@Observable
public final class PlayerStore {

  // MARK: - Public State

  /// All known players, sorted by name (case-insensitive).
  public private(set) var players: [Player] = []

  /// The single active party.
  public private(set) var party: Party = Party(name: "Active Party")

  /// Non-nil if the last `load()` or a persist operation failed.
  public private(set) var loadError: (any Error)?

  // MARK: - Storage

  private var directory: URL

  private var playersURL: URL { directory.appending(path: "players.json") }
  private var partyURL: URL { directory.appending(path: "party.json") }

  // MARK: - Init

  public init(directory: URL) {
    self.directory = directory
  }

  // MARK: - Directory

  /// Local Application Support directory. A pure URL — no file I/O performed.
  nonisolated public static var localDirectory: URL {
    let base =
      FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? FileManager.default.temporaryDirectory
    return base.appending(path: "Players")
  }

  /// Switches the storage directory and resets in-memory state.
  /// Call `load()` afterwards to populate from the new location.
  public func relocate(to newDirectory: URL) {
    directory = newDirectory
    players = []
    party = Party(name: "Active Party")
  }

  // MARK: - Computed

  /// Active party members resolved in party order.
  public var activePartyPlayers: [Player] {
    party.playerIDs.compactMap { id in players.first { $0.id == id } }
  }

  // MARK: - Player Operations

  /// Adds a new player to the roster and persists.
  public func addPlayer(_ player: Player) async {
    players.append(player)
    sortPlayers()
    await persist()
  }

  /// Replaces the stored record for `player.id` and persists.
  /// No-op if the ID is not found.
  public func updatePlayer(_ player: Player) async {
    guard let idx = players.firstIndex(where: { $0.id == player.id }) else { return }
    players[idx] = player
    sortPlayers()
    await persist()
  }

  /// Removes the player from the roster and from the party, then persists.
  /// No-op if the ID is not found.
  public func deletePlayer(id: UUID) async {
    players.removeAll { $0.id == id }
    party.playerIDs.removeAll { $0 == id }
    await persist()
  }

  // MARK: - Party Operations

  /// Adds a player ID to the active party. No-op if already present.
  public func addToParty(id: UUID) async {
    guard !party.playerIDs.contains(id) else { return }
    party.playerIDs.append(id)
    await persist()
  }

  /// Removes a player ID from the active party without deleting the player.
  public func removeFromParty(id: UUID) async {
    party.playerIDs.removeAll { $0 == id }
    await persist()
  }

  /// Wipes all players and resets the party to empty. Requires confirmation in UI.
  public func resetAll() async {
    players = []
    party = Party(name: "Active Party")
    await persist()
  }

  // MARK: - Load

  /// Reads `players.json` and `party.json` from `directory`.
  ///
  /// Missing files are treated as empty state (first launch). Corrupt files
  /// are skipped and `loadError` is set.
  public func load() async {
    loadError = nil
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      let decoder = JSONDecoder()
      if let data = try? Data(contentsOf: playersURL),
        let decoded = try? decoder.decode([Player].self, from: data)
      {
        players = decoded
        sortPlayers()
      }
      if let data = try? Data(contentsOf: partyURL),
        let decoded = try? decoder.decode(Party.self, from: data)
      {
        party = decoded
      }
    } catch {
      loadError = error
    }
  }

  // MARK: - Private

  private func sortPlayers() {
    players.sort {
      $0.name.localizedStandardCompare($1.name) == .orderedAscending
    }
  }

  private func persist() async {
    let playersCopy = players
    let partyCopy = party
    do {
      try await Self.writeJSON(playersCopy, to: playersURL)
      try await Self.writeJSON(partyCopy, to: partyURL)
    } catch {
      loadError = error
    }
  }

  @concurrent
  nonisolated private static func writeJSON<T: Encodable & Sendable>(
    _ value: T, to url: URL
  ) async throws {
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    let data = try JSONEncoder().encode(value)
    try data.write(to: url, options: .atomic)
  }
}
