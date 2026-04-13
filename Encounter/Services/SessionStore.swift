//
//  SessionStore.swift
//  Encounter
//
//  Persists live EncounterSession objects across app launches.
//  Each session is stored as <UUID>.session.json in a flat directory
//  that lives alongside the Encounters, Content, and Players directories.
//

import DHKit
import Foundation
import Observation

/// Persistence layer for live ``EncounterSession`` objects.
///
/// Sessions survive app backgrounding and relaunch. On startup call
/// ``load(into:)`` to restore sessions into the ``SessionRegistry``.
/// Save via ``save(_:)`` or ``saveAll(from:)``; remove on explicit
/// reset via ``delete(sessionID:)``.
///
/// Inject into the SwiftUI environment at app launch:
/// ```swift
/// @State private var sessionStore = SessionStore(directory: SessionStore.localDirectory)
///
/// ContentView()
///     .environment(sessionStore)
///     .task {
///         let dir = await EncounterStore.defaultDirectory()
///         let sessionsDir = dir.deletingLastPathComponent()
///             .appending(path: "Sessions", directoryHint: .isDirectory)
///         sessionStore.relocate(to: sessionsDir)
///         await sessionStore.load(into: sessionRegistry)
///     }
/// ```
@Observable @MainActor
final class SessionStore {

  // MARK: - State

  /// `true` after ``load(into:)`` completes.
  /// Views observe this to trigger resume-prompt detection.
  private(set) var isLoaded = false

  /// The directory where `.session.json` files are stored.
  private(set) var directory: URL

  // MARK: - Init

  init(directory: URL) {
    self.directory = directory
  }

  // MARK: - Directory

  /// Local Application Support fallback. Pure URL — no file I/O performed.
  nonisolated static var localDirectory: URL {
    let base =
      FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? FileManager.default.temporaryDirectory
    return base.appending(path: "Sessions")
  }

  /// Switches the storage directory. Call ``load(into:)`` afterwards to populate.
  func relocate(to newDirectory: URL) {
    directory = newDirectory
  }

  // MARK: - Load

  /// Decode all persisted sessions from disk and insert them into `registry`.
  /// Existing sessions in the registry are not overwritten.
  /// Sets ``isLoaded`` to `true` when complete.
  func load(into registry: SessionRegistry) async {
    let rawData = await Self.readAllSessionData(from: directory)
    let decoder = JSONDecoder()
    for data in rawData {
      if let session = try? decoder.decode(EncounterSession.self, from: data) {
        registry.insert(session)
      }
    }
    isLoaded = true
  }

  @concurrent
  nonisolated private static func readAllSessionData(from dir: URL) async -> [Data] {
    let fm = FileManager.default
    try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
    guard let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [])
    else { return [] }
    return
      contents
      .filter { $0.lastPathComponent.hasSuffix(".session.json") }
      .compactMap { try? Data(contentsOf: $0) }
  }

  // MARK: - Save

  /// Persist a single session to disk.
  /// The write is performed off the main actor via a `@concurrent` helper.
  func save(_ session: EncounterSession) async {
    guard let data = try? JSONEncoder().encode(session) else { return }
    let url = directory.appending(path: "\(session.id).session.json")
    let dir = directory
    await Self.writeSessionData(data, to: url, in: dir)
  }

  @concurrent
  nonisolated private static func writeSessionData(_ data: Data, to url: URL, in dir: URL) async {
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    try? data.write(to: url, options: .atomic)
  }

  /// Persist all sessions currently held in `registry`.
  ///
  /// Child tasks hop back to `@MainActor` to call `save`, so the
  /// individual writes are serialized through the main actor even though
  /// `TaskGroup` is used. The actual file I/O inside each `save` is
  /// off-actor via `@concurrent`, so disk writes still overlap.
  func saveAll(from registry: SessionRegistry) async {
    await withTaskGroup(of: Void.self) { group in
      for session in registry.sessions.values {
        group.addTask { await self.save(session) }
      }
    }
  }

  // MARK: - Delete

  /// Remove the persisted file for the given session ID (e.g. after an explicit reset).
  func delete(sessionID: UUID) async {
    let url = directory.appending(path: "\(sessionID).session.json")
    await Self.removeSessionData(at: url)
  }

  @concurrent
  nonisolated private static func removeSessionData(at url: URL) async {
    try? FileManager.default.removeItem(at: url)
  }
}
