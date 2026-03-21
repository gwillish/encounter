//
//  ContentFetcher.swift
//  Encounter
//
//  Responsible for fetching .dhpack content from remote URLs.
//  All methods are nonisolated and run on the cooperative thread pool.
//  No main-actor state is accessed; callers assign results back on their actor.
//

import CryptoKit
import Foundation
import OSLog

/// Fetches `.dhpack` content from a remote URL and computes a ``ContentFingerprint``.
///
/// `ContentFetcher` is a pure value type with no mutable state. It uses the
/// shared `URLSession` (`.default` configuration) with async/await, which is
/// correct for user-initiated fetches and compatible with Swift structured
/// concurrency (see ADR-0018).
///
/// ## Concurrency
/// Every method is `nonisolated`. Call from a `@MainActor` context via `await`
/// and assign results back to main-actor state after the `await` returns.
///
/// ## SHA-256
/// Hashing is performed inline on the cooperative thread pool — never on the
/// main actor — because `SHA256.hash(data:)` is synchronous and O(n) in
/// content size.
public struct ContentFetcher: Sendable {

    nonisolated private static let logger = Logger(subsystem: "gwillish.Encounter", category: "ContentFetcher")

    public init() {}

    // MARK: - Fetch outcome

    /// The result of a fetch attempt.
    public enum Outcome: Sendable {
        /// New content was downloaded. `data` is the raw bytes; `fingerprint` is ready to persist.
        case fetched(data: Data, fingerprint: ContentFingerprint)
        /// The server returned HTTP 304 Not Modified. The cached content is still current.
        case notModified
    }

    // MARK: - Public API

    /// Fetch the content pack for `source`.
    ///
    /// Sends a conditional GET using the stored ETag if available. Returns
    /// `.notModified` when the server confirms the cached copy is current.
    ///
    /// - Throws: ``ContentStoreError/networkError(sourceID:underlying:)`` on transport failure.
    nonisolated public func fetch(source: ContentSource) async throws -> Outcome {
        var request = URLRequest(url: source.url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let etag = source.fingerprint?.etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ContentStoreError.networkError(sourceID: source.id, underlying: error)
        }

        if let http = response as? HTTPURLResponse, http.statusCode == 304 {
            Self.logger.info("Source '\(source.id)' not modified (304)")
            return .notModified
        }

        let sha256 = computeSHA256(data)
        let etag   = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "ETag")
        let fingerprint = ContentFingerprint(sha256: sha256, etag: etag)

        Self.logger.info("ContentFetcher: \(data.count) bytes from '\(source.id)'")
        return .fetched(data: data, fingerprint: fingerprint)
    }

    /// Decode raw `.dhpack` bytes into adversaries and environments.
    ///
    /// - Throws: ``ContentStoreError/decodingFailed(sourceID:underlying:)`` on decode error.
    nonisolated public func decode(data: Data, sourceID: String) throws -> DHPackContent {
        do {
            return try JSONDecoder().decode(DHPackContent.self, from: data)
        } catch {
            throw ContentStoreError.decodingFailed(sourceID: sourceID, underlying: error)
        }
    }

    // MARK: - Fingerprinting

    /// Computes a SHA-256 hex string for the given data.
    ///
    /// Intentionally `nonisolated` — must only be called off the main actor.
    nonisolated public func computeSHA256(_ data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
