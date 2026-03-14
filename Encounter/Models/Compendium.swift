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
///             .onAppear { compendium.load() }
///     }
/// }
/// ```
///
/// ## Loading
/// Call ``load()`` once during app startup. It decodes both JSON files
/// from the bundle and publishes the results.
///
/// ## Homebrew
/// Call ``addAdversary(_:)`` / ``addEnvironment(_:)`` to merge homebrew
/// entries at runtime. Homebrew entries with the same `id` as an SRD entry
/// replace the SRD version.
@Observable
public final class Compendium {

    // MARK: Published State

    /// All adversaries, keyed by their `id` slug for O(1) lookup.
    public private(set) var adversariesByID: [String: Adversary] = [:]

    /// All environments, keyed by their `id` slug.
    public private(set) var environmentsByID: [String: DaggerheartEnvironment] = [:]

    /// Sorted array of all adversaries (for list views).
    public var adversaries: [Adversary] {
        adversariesByID.values.sorted { $0.name < $1.name }
    }

    /// Sorted array of all environments.
    public var environments: [DaggerheartEnvironment] {
        environmentsByID.values.sorted { $0.name < $1.name }
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
    /// Safe to call multiple times; subsequent calls while already loading
    /// are ignored. After a successful load, previous entries are replaced.
    public func load() {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil

        do {
            let loadedAdversaries = try decodeArray(Adversary.self, fromResource: "adversaries")
            let loadedEnvironments = try decodeArray(DaggerheartEnvironment.self, fromResource: "environments")

            adversariesByID   = Dictionary(uniqueKeysWithValues: loadedAdversaries.map { ($0.id, $0) })
            environmentsByID  = Dictionary(uniqueKeysWithValues: loadedEnvironments.map { ($0.id, $0) })
        } catch let error as CompendiumError {
            loadError = error
        } catch {
            loadError = .decodingFailed("unknown", error)
        }

        isLoading = false
    }

    // MARK: - Lookup

    /// Look up an adversary by its slug ID.
    public func adversary(id: String) -> Adversary? {
        adversariesByID[id]
    }

    /// Look up an environment by its slug ID.
    public func environment(id: String) -> DaggerheartEnvironment? {
        environmentsByID[id]
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

    /// Merge a custom adversary into the compendium.
    /// If an entry with the same `id` already exists, it is replaced.
    public func addAdversary(_ adversary: Adversary) {
        adversariesByID[adversary.id] = adversary
    }

    /// Merge a custom environment into the compendium.
    public func addEnvironment(_ environment: DaggerheartEnvironment) {
        environmentsByID[environment.id] = environment
    }

    // MARK: - Private Helpers

    private func decodeArray<T: Decodable>(_ type: T.Type, fromResource name: String) throws -> [T] {
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
