//
//  ContentSource.swift
//  Encounter
//
//  A registered community content source (a URL pointing to a .dhpack file).
//  Persisted to Application Support so the source list survives app restarts.
//

import Foundation

/// A registered content source for community adversary and environment packs.
///
/// Sources are user-managed: added manually by entering a URL, fetched on user
/// request, and removable at any time. Fetch timing is governed by exponential
/// backoff so failed sources don't hammer their hosts (see ADR-00XX).
///
/// ## Persistence
/// The array of registered `ContentSource` values is stored in
/// `Application Support/gwillish.Encounter/sources/index.json`.
/// The pack content itself lives in
/// `Application Support/gwillish.Encounter/sources/<id>/`.
///
/// ## Date fields
/// All `Date` properties are stored as ISO8601 Zulu strings per ADR-0013.
public struct ContentSource: Codable, Identifiable, Equatable, Sendable {

    /// Stable, lowercase slug identifying this source, e.g. `"expanded-adversary-compendium"`.
    /// Used as a directory name and as the key in ``Compendium``'s sources tier.
    public let id: String

    /// Display name shown in the source management UI.
    public var name: String

    /// URL of the `.dhpack` file. Must be version-pinned (see ADR-0017).
    public var url: URL

    /// ISO8601 Zulu date of the last successful fetch.
    /// Nil if this source has never been successfully fetched.
    /// Always stored and compared in UTC per ADR-0013.
    public var lastFetched: Date?

    /// Content fingerprint from the last successful fetch.
    /// Nil until the first successful fetch.
    public var fingerprint: ContentFingerprint?

    /// Number of consecutive fetch failures since the last successful fetch.
    /// Reset to zero on success.
    public private(set) var consecutiveFailures: Int

    /// The earliest date at which the next fetch attempt is permitted.
    /// Nil means fetching is allowed immediately.
    /// Set by exponential backoff whenever a fetch fails.
    public private(set) var nextAllowedFetch: Date?

    // MARK: - Init

    public init(
        id: String,
        name: String,
        url: URL,
        lastFetched: Date? = nil,
        fingerprint: ContentFingerprint? = nil,
        consecutiveFailures: Int = 0,
        nextAllowedFetch: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.lastFetched = lastFetched
        self.fingerprint = fingerprint
        self.consecutiveFailures = consecutiveFailures
        self.nextAllowedFetch = nextAllowedFetch
    }

    // MARK: - Throttle check

    /// Returns `true` if backoff is currently active for this source.
    public func isThrottled(at date: Date = .now) -> Bool {
        guard let next = nextAllowedFetch else { return false }
        return date < next
    }

    // MARK: - Backoff mutations
    //
    // These return new values rather than mutating in place, keeping ContentSource
    // a pure value type and making the state transitions easy to test.

    /// Returns a copy with exponential backoff applied for one additional failure.
    ///
    /// Delay formula: `min(1h × 2^consecutiveFailures, 7 days)`
    /// - 1st failure  → 1 hour
    /// - 2nd failure  → 2 hours
    /// - 3rd failure  → 4 hours
    /// - …
    /// - 10th failure → capped at 7 days
    public func recordingFailure(at date: Date = .now) -> ContentSource {
        var updated = self
        let exponent = Double(consecutiveFailures)          // starts at 0 on first failure
        let hours    = pow(2.0, exponent)                   // 1, 2, 4, 8, …
        let delay    = min(hours * 3_600, 7 * 24 * 3_600)  // cap at 7 days
        updated.consecutiveFailures += 1
        updated.nextAllowedFetch = date.addingTimeInterval(delay)
        return updated
    }

    /// Returns a copy recording a successful fetch, resetting all backoff state.
    public func recordingSuccess(fingerprint: ContentFingerprint, at date: Date = .now) -> ContentSource {
        var updated = self
        updated.lastFetched = date
        updated.fingerprint = fingerprint
        updated.consecutiveFailures = 0
        updated.nextAllowedFetch = nil
        return updated
    }
}
