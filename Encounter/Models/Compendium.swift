//
//  Compendium.swift
//  Encounter
//
//  Observable data store that loads Daggerheart catalog JSON from the
//  app bundle and provides lookup APIs for adversaries and environments.
//
//  Data sources (bundled JSON files in Encounter/Resources/):
//    adversaries.json  — from seansbox/daggerheart-srd .build/json/
//    environments.json — from seansbox/daggerheart-srd .build/json/
//
//  Both files contain a top-level JSON array of objects.
//  See docs/data-schema.md for the complete field reference.
//

import Foundation
import Observation

// MARK: - CompendiumError

/// Errors that can occur while loading compendium data.
nonisolated public enum CompendiumError: Error, LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String, Error)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "Compendium resource '\(name)' not found in app bundle."
        case .decodingFailed(let name, let underlying):
            return "Failed to decode '\(name)': \(underlying.localizedDescription)"
        }
    }
}

// MARK: - Compendium

/// The central catalog of Daggerheart adversaries and environments.
///
/// `Compendium` is an `@Observable` class intended to be injected into
/// the SwiftUI environment once at app launch and shared across all views.
///
/// ```swift
/// // In EncounterApp.swift:
/// @State private var compendium = Compendium()
///
/// var body: some Scene {
///     WindowGroup {
///         ContentView()
///             .environment(compendium)
///             .task { try? await compendium.load() }
///     }
/// }
/// ```
///
/// ## Loading
/// Call ``load()`` once during app startup. It decodes both JSON files
/// from the bundle on a background task and publishes the results.
///
/// ## Homebrew
/// Call ``addAdversary(_:)`` / ``addEnvironment(_:)`` to merge homebrew
/// entries at runtime. Homebrew entries with the same `id` as an SRD entry
/// replace the SRD version.
@Observable
public final class Compendium {

    // MARK: Published State

    /// SRD adversaries loaded from the bundle, keyed by slug.
    private var srdAdversariesByID: [String: Adversary] = [:]

    /// Homebrew adversaries added at runtime, keyed by slug.
    /// Homebrew entries with the same `id` as an SRD entry shadow the SRD version.
    private var homebrewAdversariesByID: [String: Adversary] = [:]

    /// SRD environments loaded from the bundle, keyed by slug.
    private var srdEnvironmentsByID: [String: DaggerheartEnvironment] = [:]

    /// Homebrew environments added at runtime, keyed by slug.
    private var homebrewEnvironmentsByID: [String: DaggerheartEnvironment] = [:]

    /// All adversaries (SRD + homebrew merged), keyed by slug.
    /// Homebrew entries override SRD entries with the same `id`.
    public var adversariesByID: [String: Adversary] {
        srdAdversariesByID.merging(homebrewAdversariesByID) { _, homebrew in homebrew }
    }

    /// All environments (SRD + homebrew merged), keyed by slug.
    public var environmentsByID: [String: DaggerheartEnvironment] {
        srdEnvironmentsByID.merging(homebrewEnvironmentsByID) { _, homebrew in homebrew }
    }

    /// Sorted array of all adversaries (for list views).
    public var adversaries: [Adversary] {
        adversariesByID.values.sorted { $0.name < $1.name }
    }

    /// Sorted array of all environments.
    public var environments: [DaggerheartEnvironment] {
        environmentsByID.values.sorted { $0.name < $1.name }
    }

    /// Sorted array of homebrew-only adversaries.
    public var homebrewAdversaries: [Adversary] {
        homebrewAdversariesByID.values.sorted { $0.name < $1.name }
    }

    /// Sorted array of homebrew-only environments.
    public var homebrewEnvironments: [DaggerheartEnvironment] {
        homebrewEnvironmentsByID.values.sorted { $0.name < $1.name }
    }

    /// `true` while JSON loading is in progress.
    public private(set) var isLoading: Bool = false

    /// Non-nil if the last load attempt failed.
    public private(set) var loadError: CompendiumError?

    // MARK: - Init

    public init() {}

    // MARK: - Loading

    /// Load the SRD data from bundle resources.
    ///
    /// JSON decoding is performed on a background task; results are published
    /// back on the main actor. Safe to call multiple times — concurrent calls
    /// while a load is already in progress are ignored.
    ///
    /// Throws a ``CompendiumError`` if a resource is missing or malformed.
    /// The error is also stored in ``loadError`` for SwiftUI observation.
    public func load() async throws {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil

        defer { isLoading = false }

        do {
            let (loadedAdversaries, loadedEnvironments) = try await Task.detached(priority: .userInitiated) { [self] in
                let a = try self.decodeArray(Adversary.self, fromResource: "adversaries")
                let e = try self.decodeArray(DaggerheartEnvironment.self, fromResource: "environments")
                return (a, e)
            }.value

            srdAdversariesByID  = Dictionary(uniqueKeysWithValues: loadedAdversaries.map  { ($0.id, $0) })
            srdEnvironmentsByID = Dictionary(uniqueKeysWithValues: loadedEnvironments.map { ($0.id, $0) })
        } catch let error as CompendiumError {
            loadError = error
            throw error
        } catch {
            let wrapped = CompendiumError.decodingFailed("unknown", error)
            loadError = wrapped
            throw wrapped
        }
    }

    // MARK: - Lookup

    /// Look up an adversary by its slug ID. Homebrew shadows SRD for the same ID.
    public func adversary(id: String) -> Adversary? {
        homebrewAdversariesByID[id] ?? srdAdversariesByID[id]
    }

    /// Look up an environment by its slug ID. Homebrew shadows SRD for the same ID.
    public func environment(id: String) -> DaggerheartEnvironment? {
        homebrewEnvironmentsByID[id] ?? srdEnvironmentsByID[id]
    }

    /// Return all adversaries for a given tier.
    public func adversaries(tier: Int) -> [Adversary] {
        adversaries.filter { $0.tier == tier }
    }

    /// Return all adversaries of a given type.
    public func adversaries(type: AdversaryType) -> [Adversary] {
        adversaries.filter { $0.type == type }
    }

    /// Full-text search across adversary names and descriptions.
    public func searchAdversaries(query: String) -> [Adversary] {
        guard !query.isEmpty else { return adversaries }
        let lower = query.lowercased()
        return adversaries.filter {
            $0.name.lowercased().contains(lower) ||
            $0.description.lowercased().contains(lower)
        }
    }

    // MARK: - Homebrew

    /// Add or replace a homebrew adversary.
    /// Homebrew entries shadow SRD entries with the same `id`.
    public func addAdversary(_ adversary: Adversary) {
        homebrewAdversariesByID[adversary.id] = adversary
    }

    /// Remove a homebrew adversary by slug. No-op if not present.
    public func removeHomebrewAdversary(id: String) {
        homebrewAdversariesByID.removeValue(forKey: id)
    }

    /// Add or replace a homebrew environment.
    public func addEnvironment(_ environment: DaggerheartEnvironment) {
        homebrewEnvironmentsByID[environment.id] = environment
    }

    /// Remove a homebrew environment by slug. No-op if not present.
    public func removeHomebrewEnvironment(id: String) {
        homebrewEnvironmentsByID.removeValue(forKey: id)
    }

    // MARK: - Private Helpers

    nonisolated private func decodeArray<T: Decodable>(_ type: T.Type, fromResource name: String) throws -> [T] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw CompendiumError.fileNotFound("\(name).json")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([T].self, from: data)
        } catch let error as CompendiumError {
            throw error
        } catch {
            throw CompendiumError.decodingFailed("\(name).json", error)
        }
    }
}
