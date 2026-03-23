//
//  ContentStore.swift
//  Encounter
//
//  Coordinator for content loading, source management, and Compendium reload.
//  Heavy work (fetching, decoding, writing) is delegated to ContentFetcher
//  (nonisolated) and ContentWriter (nonisolated); results are published back
//  on the main actor.
//

import Foundation
import OSLog
import Observation

// MARK: - ContentStore

/// Coordinates content loading, remote source fetching, and `.dhpack` imports.
///
/// `ContentStore` is `@MainActor @Observable` and injected into the SwiftUI
/// environment at app launch alongside ``Compendium``.
///
/// ## Responsibilities
/// - Seed the writable SRD content directory from the bundle on first launch.
/// - Load the registered source index and hydrate ``Compendium`` on startup.
/// - Fetch remote source packs on user request, with exponential backoff.
/// - Import locally opened `.dhpack` files.
///
/// Heavy work is delegated to ``ContentFetcher`` and ``ContentWriter``, both
/// of which are `nonisolated` and run on the cooperative thread pool.
@MainActor
@Observable
public final class ContentStore {

  private let logger = Logger(subsystem: "gwillish.Encounter", category: "ContentStore")

  // MARK: - Dependencies

  // fetcher is an immutable Sendable value type; nonisolated so awaiting its
  // methods from a @MainActor context runs them on the cooperative thread pool.
  nonisolated private let fetcher: ContentFetcher

  // writer is a var so relocate(to:) can swap it when the real content
  // directory is known. Callers capture the current writer value via await,
  // so in-flight tasks are unaffected by a reassignment.
  private var writer: ContentWriter

  private var compendium: Compendium

  /// The current content root directory. Read-only outside this type.
  public private(set) var contentDirectory: URL

  // MARK: - Published state

  /// Registered remote content sources, keyed by source ID.
  public private(set) var sources: [String: ContentSource] = [:]

  /// Source IDs currently being fetched.
  public private(set) var fetchingSourceIDs: Set<String> = []

  /// `true` while startup seeding/loading is in progress.
  public private(set) var isLoading: Bool = false

  /// Non-nil if the most recent operation produced an error.
  public private(set) var lastError: ContentStoreError?

  // MARK: - Init / directory resolution

  /// Placeholder content directory used until `relocate(to:)` is called.
  /// Always local Application Support — no file I/O performed.
  nonisolated public static var localContentDirectory: URL {
    URL.applicationSupportDirectory
      .appending(path: "gwillish.Encounter", directoryHint: .isDirectory)
      .appending(path: "Content", directoryHint: .isDirectory)
  }

  public init(contentDirectory: URL, compendium: Compendium) {
    self.contentDirectory = contentDirectory
    self.fetcher = ContentFetcher()
    self.writer = ContentWriter(contentDirectory: contentDirectory)
    self.compendium = compendium
  }

  /// Wire in the real ``Compendium`` instance after construction.
  ///
  /// Call this in `EncounterApp.task` before ``loadOnStartup()`` to replace
  /// the placeholder `Compendium` passed to `init`. This avoids recreating
  /// the entire `ContentStore` just to swap the compendium reference.
  public func configure(compendium: Compendium) {
    self.compendium = compendium
  }

  /// Switches to a new content directory with safety checks.
  ///
  /// Call this once in `EncounterApp.task` before ``loadOnStartup()``,
  /// passing the resolved real directory (which may differ from the
  /// placeholder when iCloud or a custom path is in use).
  ///
  /// Safety rules (all comparisons use standardized paths):
  /// 1. **Same path** — no-op; logs and returns immediately.
  /// 2. **New path already has content** — switches without touching existing
  ///    files; logs a warning so the situation is visible.
  /// 3. **Old path has content, new path is empty** — migrates subdirectories
  ///    one at a time. Never overwrites a subdirectory that already exists at
  ///    the destination. Falls back to a switch-only if migration fails.
  /// 4. **Old path is empty** — switches silently.
  public func relocate(to newDirectory: URL) async {
    let oldStd = contentDirectory.standardized
    let newStd = newDirectory.standardized
    guard oldStd != newStd else {
      logger.debug("ContentStore.relocate: already at target '\(newStd.path)' — no-op")
      return
    }

    let oldHasContent = await ContentWriter.checkSubdirectoryExists(oldStd)
    let newHasContent = await ContentWriter.checkSubdirectoryExists(newStd)

    if newHasContent {
      // The target already has data — switch without touching anything.
      if oldHasContent {
        logger.warning(
          "ContentStore.relocate: both '\(oldStd.path)' and '\(newStd.path)' have content. Switching to new path; old content left in place."
        )
      } else {
        logger.info("ContentStore.relocate: switching to existing content at '\(newStd.path)'")
      }
    } else if oldHasContent {
      // Old has data, new is empty — attempt migration.
      logger.info(
        "ContentStore.relocate: migrating content from '\(oldStd.path)' to '\(newStd.path)'"
      )
      await ContentWriter.migrateSubdirectories(
        from: oldStd,
        to: newStd,
        names: ["srd", "sources", "homebrew"],
        logger: logger
      )
      logger.info("ContentStore.relocate: migration complete")
    }

    contentDirectory = newDirectory
    writer = ContentWriter(contentDirectory: newDirectory)
    logger.info(
      "ContentStore.relocate: active directory is now '\(newDirectory.standardized.path)'")
  }

  // MARK: - Startup

  /// Seed SRD content and load the source index. Call once at app launch.
  ///
  /// 1. Seeds writable SRD from bundle (no-op if already seeded for this version).
  /// 2. Loads the source index from disk.
  /// 3. Hydrates ``Compendium`` with any previously fetched source packs.
  public func loadOnStartup() async {
    guard !isLoading else { return }
    isLoading = true
    defer { isLoading = false }

    let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    do {
      // Seed SRD — nonisolated, runs on cooperative thread pool when awaited
      let seeded = try await writer.seedSRDIfNeeded(bundleVersion: bundleVersion)
      if seeded { logger.info("ContentStore: SRD seeded from bundle") }

      // Load source index
      let savedSources = try await writer.readSourceIndex()
      sources = Dictionary(uniqueKeysWithValues: savedSources.map { ($0.id, $0) })

      // Hydrate Compendium with previously fetched source packs (all in parallel)
      await withTaskGroup(of: Void.self) { group in
        for (sourceID, _) in sources {
          group.addTask { await self.loadSourcePackIntoCompendium(sourceID: sourceID) }
        }
      }
      logger.info("ContentStore: startup complete, \(self.sources.count) sources loaded")
    } catch {
      lastError =
        error as? ContentStoreError
        ?? ContentStoreError.readFailed(sourceID: "startup", underlying: error)
      logger.error("ContentStore: startup failed: \(error)")
    }
  }

  // MARK: - Source management

  /// Register a new content source. Does not fetch immediately.
  public func addSource(_ source: ContentSource) async {
    sources[source.id] = source
    await persistSourceIndex()
  }

  /// Remove a source and its content from the Compendium and disk.
  public func removeSource(id: String) async {
    sources.removeValue(forKey: id)
    compendium.removeSourceContent(sourceID: id)
    do {
      try await writer.removeSourcePack(sourceID: id)
    } catch {
      logger.error("ContentStore: failed to remove pack '\(id)' from disk: \(error)")
    }
    await persistSourceIndex()
    logger.info("ContentStore: source '\(id)' removed")
  }

  // MARK: - Remote fetch

  /// Fetch and install a remote source pack. User-initiated only.
  ///
  /// Respects exponential backoff. No-ops if already fetching this source
  /// or if the source is currently throttled.
  public func fetchSource(id: String) async {
    guard var source = sources[id] else { return }
    guard !source.isLocalImport else {
      logger.debug("ContentStore: source '\(id)' is a local import — no URL to fetch")
      return
    }
    guard !source.isThrottled() else {
      logger.info("ContentStore: source '\(id)' throttled, skipping")
      return
    }
    guard !fetchingSourceIDs.contains(id) else { return }

    fetchingSourceIDs.insert(id)
    defer { fetchingSourceIDs.remove(id) }

    do {
      // fetcher.fetch is nonisolated — suspends the main actor and runs on
      // the cooperative thread pool. Resumes on the main actor with the outcome.
      let outcome = try await fetcher.fetch(source: source)

      switch outcome {
      case .notModified:
        // HTTP 304: server confirmed cached content is current. This is a
        // success — update lastFetched and clear any prior error state.
        // The Compendium already has this source's content from loadOnStartup.
        guard sources[id] != nil else {
          logger.info(
            "ContentStore: source '\(id)' removed mid-fetch — discarding notModified result")
          return
        }
        let existing = source.fingerprint ?? ContentFingerprint(sha256: "", etag: nil)
        source = source.recordingSuccess(fingerprint: existing)
        sources[id] = source
        await persistSourceIndex()
        logger.info("ContentStore: source '\(id)' not modified — still current")

      case .fetched(let data, let fingerprint):
        // Decode and write — @concurrent, runs on cooperative thread pool when awaited.
        let pack = try await fetcher.decode(data: data, sourceID: id)

        try await writer.writeSourcePack(
          adversaries: pack.adversaries,
          environments: pack.environments,
          sourceID: id
        )

        // Back on main actor: update state and Compendium.
        // Guard against source being removed while the fetch was in-flight.
        guard sources[id] != nil else {
          logger.info("ContentStore: source '\(id)' removed mid-fetch — discarding fetched result")
          return
        }
        source = source.recordingSuccess(fingerprint: fingerprint)
        sources[id] = source
        compendium.replaceSourceContent(
          sourceID: id,
          adversaries: pack.adversaries,
          environments: pack.environments
        )
        await persistSourceIndex()
        logger.info("ContentStore: source '\(id)' fetched: \(pack.adversaries.count) adversaries")
      }
    } catch let error as ContentStoreError {
      guard sources[id] != nil else { return }
      source = source.recordingFailure()
      sources[id] = source
      lastError = error
      await persistSourceIndex()
      logger.error("ContentStore: source '\(id)' fetch failed: \(error.localizedDescription)")
    } catch {
      guard sources[id] != nil else { return }
      source = source.recordingFailure()
      sources[id] = source
      lastError = ContentStoreError.networkError(sourceID: id, underlying: error)
      await persistSourceIndex()
      logger.error("ContentStore: source '\(id)' fetch failed (unexpected): \(error)")
    }
  }

  // MARK: - .dhpack import

  /// Import a locally opened `.dhpack` file and persist it across launches.
  ///
  /// The pack is decoded, written to the writable content directory, registered
  /// as a local `ContentSource` (no URL), and loaded into `Compendium`. It will
  /// reload automatically on every subsequent launch via `loadOnStartup`.
  ///
  /// If a source with the same derived ID already exists, it is replaced.
  ///
  /// Removal requires explicit user action via ``removeSource(id:)``.
  /// A UI for this is tracked separately.
  ///
  /// The file at `url` is a security-scoped resource; the caller must start
  /// access before calling this method and stop it after it returns.
  public func importPack(from url: URL) async {
    let displayName = url.deletingPathExtension().lastPathComponent
    let sourceID =
      displayName
      .lowercased()
      .components(separatedBy: CharacterSet.alphanumerics.inverted)
      .filter { !$0.isEmpty }
      .joined(separator: "-")

    do {
      // Read, decode, and write — nonisolated, runs on cooperative thread pool when awaited.
      let data = try await ContentFetcher.readData(from: url)
      let pack = try await fetcher.decode(data: data, sourceID: sourceID)

      try await writer.writeSourcePack(
        adversaries: pack.adversaries,
        environments: pack.environments,
        sourceID: sourceID
      )

      // Register as a local ContentSource and update Compendium on the main actor.
      let source = ContentSource(id: sourceID, name: displayName, importedAt: .now)
      sources[sourceID] = source
      compendium.replaceSourceContent(
        sourceID: sourceID,
        adversaries: pack.adversaries,
        environments: pack.environments
      )
      await persistSourceIndex()
      logger.info(
        "ContentStore: imported '\(sourceID)': \(pack.adversaries.count) adversaries, persisted")
    } catch {
      lastError =
        error as? ContentStoreError
        ?? ContentStoreError.decodingFailed(sourceID: sourceID, underlying: error)
      logger.error("ContentStore: pack import failed for '\(sourceID)': \(error)")
    }
  }

  // MARK: - Private helpers

  private func loadSourcePackIntoCompendium(sourceID: String) async {
    do {
      let adversaries = try await writer.readAdversaries(sourceID: sourceID)
      let environments = try await writer.readEnvironments(sourceID: sourceID)
      guard !adversaries.isEmpty || !environments.isEmpty else { return }
      compendium.replaceSourceContent(
        sourceID: sourceID,
        adversaries: adversaries,
        environments: environments
      )
    } catch {
      logger.warning("ContentStore: could not load cached pack '\(sourceID)': \(error)")
    }
  }

  private func persistSourceIndex() async {
    let snapshot = Array(sources.values)
    do {
      try await writer.writeSourceIndex(snapshot)
    } catch {
      lastError = ContentStoreError.writeFailed(sourceID: "source-index", underlying: error)
      logger.error("ContentStore: failed to persist source index: \(error)")
    }
  }
}
