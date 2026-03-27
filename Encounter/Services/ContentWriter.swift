//
//  ContentWriter.swift
//  Encounter
//
//  Responsible for reading and writing content pack files in the writable
//  Application Support directory.
//
//  All methods are nonisolated and run on the cooperative thread pool.
//  No main-actor state is accessed; callers assign results back on their actor.
//

import DaggerheartModels
import Foundation
import OSLog

/// Reads and writes `.dhpack` content in the app's writable content directory.
///
/// ## Directory layout
///
/// ```
/// Application Support/gwillish.Encounter/
/// ├── srd/
/// │   ├── adversaries.json
/// │   └── environments.json
/// ├── sources/
/// │   ├── index.json          ← [ContentSource] metadata
/// │   └── <sourceID>/
/// │       ├── adversaries.json
/// │       └── environments.json
/// └── homebrew/
///     ├── adversaries.json
///     └── environments.json
/// ```
///
/// ## Atomic writes
/// All writes use a temp-file-then-`replaceItem` pattern to prevent partial
/// writes from corrupting the content directory if the app is killed mid-write.
///
/// ## Seeding
/// On first launch (or after a bundle update), ``seedSRDIfNeeded(bundleVersion:)``
/// copies the bundled `adversaries.json` / `environments.json` into the `srd/`
/// subdirectory. A `bundle_version` stamp file records which bundle was seeded,
/// so re-seeding only happens when the bundle ships new data.
///
/// ## Concurrency
/// All methods are `nonisolated`. Call from a `@MainActor` context via `await`.
public struct ContentWriter: Sendable {

  nonisolated private static let logger = Logger(
    subsystem: "gwillish.Encounter", category: "ContentWriter")

  /// Root of the writable content directory
  /// (e.g. `Application Support/gwillish.Encounter/`).
  public let contentDirectory: URL

  public init(contentDirectory: URL) {
    self.contentDirectory = contentDirectory
  }

  // MARK: - SRD seeding

  /// Seeds the writable `srd/` directory from bundle resources if the bundle
  /// has changed since the last seed.
  ///
  /// Uses a `srd/bundle_version` stamp file to detect whether seeding is needed.
  /// The stamp contains the bundle's `CFBundleVersion` string.
  ///
  /// - Parameter bundleVersion: Current `CFBundleVersion` from `Bundle.main`.
  /// - Returns: `true` if seeding was performed.
  @concurrent
  nonisolated public func seedSRDIfNeeded(bundleVersion: String) async throws -> Bool {
    let srdDir = contentDirectory.appending(path: "srd", directoryHint: .isDirectory)
    let stampURL = srdDir.appending(path: "bundle_version")

    let existingStamp = try? String(contentsOf: stampURL, encoding: .utf8)
    guard existingStamp != bundleVersion else {
      return false  // Already seeded this bundle version
    }

    guard let advURL = Bundle.main.url(forResource: "adversaries", withExtension: "json"),
      let envURL = Bundle.main.url(forResource: "environments", withExtension: "json")
    else {
      Self.logger.warning("ContentWriter: bundle resources missing — skipping SRD seed")
      return false
    }

    try FileManager.default.createDirectory(at: srdDir, withIntermediateDirectories: true)
    let advData = try Data(contentsOf: advURL)
    let envData = try Data(contentsOf: envURL)

    try atomicWrite(data: advData, to: srdDir.appending(path: "adversaries.json"), sourceID: "srd")
    try atomicWrite(data: envData, to: srdDir.appending(path: "environments.json"), sourceID: "srd")
    try atomicWrite(data: Data(bundleVersion.utf8), to: stampURL, sourceID: "srd")

    Self.logger.info("ContentWriter: SRD seeded from bundle (version \(bundleVersion))")
    return true
  }

  // MARK: - Source pack read/write

  /// Write a source pack's adversaries and environments to disk.
  ///
  /// Creates `sources/<sourceID>/` if it doesn't exist.
  @concurrent
  nonisolated public func writeSourcePack(
    adversaries: [Adversary],
    environments: [DaggerheartEnvironment],
    sourceID: String
  ) async throws {
    let dir = sourcesDirectory.appending(path: sourceID, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    try atomicWrite(
      data: try encoder.encode(adversaries), to: dir.appending(path: "adversaries.json"),
      sourceID: sourceID)
    try atomicWrite(
      data: try encoder.encode(environments), to: dir.appending(path: "environments.json"),
      sourceID: sourceID)

    Self.logger.info(
      "ContentWriter: wrote source '\(sourceID)': \(adversaries.count) adversaries, \(environments.count) environments"
    )
  }

  /// Read adversaries for a source pack from disk. Returns `[]` if not yet written.
  @concurrent
  nonisolated public func readAdversaries(sourceID: String) async throws -> [Adversary] {
    let url = sourcesDirectory.appending(path: "\(sourceID)/adversaries.json")
    guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return [] }
    do {
      return try JSONDecoder().decode([Adversary].self, from: Data(contentsOf: url))
    } catch {
      throw ContentStoreError.readFailed(sourceID: sourceID, underlying: error)
    }
  }

  /// Read environments for a source pack from disk. Returns `[]` if not yet written.
  @concurrent
  nonisolated public func readEnvironments(sourceID: String) async throws
    -> [DaggerheartEnvironment]
  {
    let url = sourcesDirectory.appending(path: "\(sourceID)/environments.json")
    guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return [] }
    do {
      return try JSONDecoder().decode([DaggerheartEnvironment].self, from: Data(contentsOf: url))
    } catch {
      throw ContentStoreError.readFailed(sourceID: sourceID, underlying: error)
    }
  }

  /// Remove a source pack's directory from disk. No-op if not present.
  @concurrent
  nonisolated public func removeSourcePack(sourceID: String) async throws {
    let dir = sourcesDirectory.appending(path: sourceID, directoryHint: .isDirectory)
    guard FileManager.default.fileExists(atPath: dir.path(percentEncoded: false)) else { return }
    try FileManager.default.removeItem(at: dir)
    Self.logger.info("ContentWriter: removed source pack '\(sourceID)'")
  }

  // MARK: - Source index (ContentSource metadata)

  /// Persist the source index to `sources/index.json`.
  @concurrent
  nonisolated public func writeSourceIndex(_ sources: [ContentSource]) async throws {
    try FileManager.default.createDirectory(at: sourcesDirectory, withIntermediateDirectories: true)
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(sources)
    try atomicWrite(
      data: data, to: sourcesDirectory.appending(path: "index.json"), sourceID: "index")
  }

  /// Load the source index from `sources/index.json`. Returns `[]` if not present.
  @concurrent
  nonisolated public func readSourceIndex() async throws -> [ContentSource] {
    let url = sourcesDirectory.appending(path: "index.json")
    guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return [] }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    do {
      return try decoder.decode([ContentSource].self, from: Data(contentsOf: url))
    } catch {
      throw ContentStoreError.readFailed(sourceID: "index", underlying: error)
    }
  }

  // MARK: - Static helpers for relocate

  /// Returns `true` if a subdirectory named `srd` exists under `url`.
  /// Used by `ContentStore.relocate(to:)` to check whether a directory has content.
  @concurrent
  nonisolated public static func checkSubdirectoryExists(_ url: URL) async -> Bool {
    FileManager.default.fileExists(atPath: url.appending(path: "srd").path(percentEncoded: false))
  }

  /// Moves `names` subdirectories from `source` to `destination`, skipping any
  /// that already exist at the destination. Never overwrites.
  @concurrent
  nonisolated public static func migrateSubdirectories(
    from source: URL,
    to destination: URL,
    names: [String],
    logger: Logger
  ) async {
    let fm = FileManager.default
    do {
      try fm.createDirectory(at: destination, withIntermediateDirectories: true)
    } catch {
      logger.error(
        "ContentWriter.migrateSubdirectories: could not create destination '\(destination.path(percentEncoded: false))': \(error)"
      )
      return
    }
    for name in names {
      let src = source.appending(path: name)
      let dst = destination.appending(path: name)
      guard fm.fileExists(atPath: src.path(percentEncoded: false)) else { continue }
      guard !fm.fileExists(atPath: dst.path(percentEncoded: false)) else {
        logger.warning(
          "ContentWriter.migrateSubdirectories: '\(name)' already exists at destination — skipped")
        continue
      }
      do {
        try fm.moveItem(at: src, to: dst)
      } catch {
        logger.error("ContentWriter.migrateSubdirectories: failed to move '\(name)': \(error)")
      }
    }
  }

  // MARK: - Private helpers

  nonisolated private var sourcesDirectory: URL {
    contentDirectory.appending(path: "sources", directoryHint: .isDirectory)
  }

  nonisolated private func atomicWrite(data: Data, to destination: URL, sourceID: String) throws {
    let temp = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString)
    do {
      try data.write(to: temp, options: .atomic)
      if FileManager.default.fileExists(atPath: destination.path(percentEncoded: false)) {
        _ = try FileManager.default.replaceItemAt(destination, withItemAt: temp)
      } else {
        try FileManager.default.moveItem(at: temp, to: destination)
      }
    } catch {
      try? FileManager.default.removeItem(at: temp)
      throw ContentStoreError.writeFailed(sourceID: sourceID, underlying: error)
    }
  }
}
