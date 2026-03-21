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
import Observation
import OSLog
import UniformTypeIdentifiers

// MARK: - UTType

extension UTType {
    /// The `.dhpack` file type: a JSON content pack for Encounter.
    /// Declared in Info.plist as `gwillish.Encounter.dhpack`, conforming to `public.json`.
    public static let dhpack: UTType = UTType(exportedAs: "gwillish.Encounter.dhpack")
}

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

    private let fetcher: ContentFetcher
    private let writer: ContentWriter
    private let compendium: Compendium

    // MARK: - Published state

    /// Registered remote content sources, keyed by source ID.
    public private(set) var sources: [String: ContentSource] = [:]

    /// Source IDs currently being fetched.
    public private(set) var fetchingSourceIDs: Set<String> = []

    /// `true` while startup seeding/loading is in progress.
    public private(set) var isLoading: Bool = false

    /// Non-nil if the most recent operation produced an error.
    public private(set) var lastError: ContentStoreError?

    // MARK: - Init

    public init(contentDirectory: URL, compendium: Compendium) {
        self.fetcher   = ContentFetcher()
        self.writer    = ContentWriter(contentDirectory: contentDirectory)
        self.compendium = compendium
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
            // Seed SRD — nonisolated, runs on cooperative thread pool
            let seeded = try await Task.detached(priority: .userInitiated) { [writer] in
                try writer.seedSRDIfNeeded(bundleVersion: bundleVersion)
            }.value
            if seeded { logger.info("ContentStore: SRD seeded from bundle") }

            // Load source index
            let savedSources = try await Task.detached(priority: .userInitiated) { [writer] in
                try writer.readSourceIndex()
            }.value
            sources = Dictionary(uniqueKeysWithValues: savedSources.map { ($0.id, $0) })

            // Hydrate Compendium with previously fetched source packs
            for (sourceID, _) in sources {
                await loadSourcePackIntoCompendium(sourceID: sourceID)
            }
            logger.info("ContentStore: startup complete, \(self.sources.count) sources loaded")
        } catch {
            lastError = error as? ContentStoreError
                ?? ContentStoreError.readFailed(sourceID: "startup", underlying: error)
            logger.error("ContentStore: startup failed: \(error)")
        }
    }

    // MARK: - Source management

    /// Register a new content source. Does not fetch immediately.
    public func addSource(_ source: ContentSource) {
        sources[source.id] = source
        persistSourceIndex()
    }

    /// Remove a source and its content from the Compendium and disk.
    public func removeSource(id: String) {
        sources.removeValue(forKey: id)
        compendium.removeSourceContent(sourceID: id)
        Task.detached(priority: .utility) { [writer] in
            try? writer.removeSourcePack(sourceID: id)
        }
        persistSourceIndex()
        logger.info("ContentStore: source '\(id)' removed")
    }

    // MARK: - Remote fetch

    /// Fetch and install a remote source pack. User-initiated only.
    ///
    /// Respects exponential backoff. No-ops if already fetching this source
    /// or if the source is currently throttled.
    public func fetchSource(id: String) async {
        guard var source = sources[id] else { return }
        guard !source.isThrottled() else {
            logger.info("ContentStore: source '\(id)' throttled, skipping")
            return
        }
        guard !fetchingSourceIDs.contains(id) else { return }

        fetchingSourceIDs.insert(id)
        defer { fetchingSourceIDs.remove(id) }

        do {
            // Fetch + decode — both nonisolated, run off the main actor
            let (pack, fingerprint) = try await fetchAndDecode(source: source)

            // Write to disk — nonisolated
            try await Task.detached(priority: .userInitiated) { [writer] in
                try writer.writeSourcePack(
                    adversaries: pack.adversaries,
                    environments: pack.environments,
                    sourceID: id
                )
            }.value

            // Back on main actor: update state and Compendium
            source = source.recordingSuccess(fingerprint: fingerprint)
            sources[id] = source
            compendium.replaceSourceContent(
                sourceID: id,
                adversaries: pack.adversaries,
                environments: pack.environments
            )
            persistSourceIndex()
            logger.info("ContentStore: source '\(id)' fetched: \(pack.adversaries.count) adversaries")
        } catch let error as ContentStoreError {
            source = source.recordingFailure()
            sources[id] = source
            lastError = error
            persistSourceIndex()
            logger.error("ContentStore: source '\(id)' fetch failed: \(error.localizedDescription)")
        } catch {
            source = source.recordingFailure()
            sources[id] = source
            lastError = ContentStoreError.networkError(sourceID: id, underlying: error)
            persistSourceIndex()
            logger.error("ContentStore: source '\(id)' fetch failed (unexpected): \(error)")
        }
    }

    // MARK: - .dhpack import

    /// Import a locally opened `.dhpack` file.
    ///
    /// Call this from the `onOpenURL` handler on the `Scene` level in `EncounterApp`.
    /// The file at `url` is a security-scoped resource; access must be started before
    /// calling this method and stopped after it returns.
    public func importPack(from url: URL) async {
        let sourceID = url.deletingPathExtension().lastPathComponent
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        do {
            let localFetcher = fetcher
            let pack: DHPackContent = try await Task.detached(priority: .userInitiated) {
                let data = try Data(contentsOf: url)
                return try localFetcher.decode(data: data, sourceID: sourceID)
            }.value

            compendium.replaceSourceContent(
                sourceID: sourceID,
                adversaries: pack.adversaries,
                environments: pack.environments
            )
            logger.info("ContentStore: imported pack '\(sourceID)': \(pack.adversaries.count) adversaries")
        } catch {
            lastError = error as? ContentStoreError
                ?? ContentStoreError.decodingFailed(sourceID: sourceID, underlying: error)
            logger.error("ContentStore: pack import failed for '\(sourceID)': \(error)")
        }
    }

    // MARK: - Private helpers

    nonisolated private func fetchAndDecode(
        source: ContentSource
    ) async throws -> (DHPackContent, ContentFingerprint) {
        switch try await fetcher.fetch(source: source) {
        case .notModified:
            // Cached content on disk is still valid — load it
            throw ContentStoreError.networkError(
                sourceID: source.id,
                underlying: URLError(.resourceUnavailable)
            )
        case .fetched(let data, let fingerprint):
            let pack = try fetcher.decode(data: data, sourceID: source.id)
            return (pack, fingerprint)
        }
    }

    private func loadSourcePackIntoCompendium(sourceID: String) async {
        do {
            let (adversaries, environments) = try await Task.detached(priority: .userInitiated) { [writer] in
                let a = try writer.readAdversaries(sourceID: sourceID)
                let e = try writer.readEnvironments(sourceID: sourceID)
                return (a, e)
            }.value
            guard !adversaries.isEmpty else { return }
            compendium.replaceSourceContent(
                sourceID: sourceID,
                adversaries: adversaries,
                environments: environments
            )
        } catch {
            logger.warning("ContentStore: could not load cached pack '\(sourceID)': \(error)")
        }
    }

    private func persistSourceIndex() {
        let snapshot = Array(sources.values)
        Task.detached(priority: .utility) { [writer] in
            try? writer.writeSourceIndex(snapshot)
        }
    }
}
