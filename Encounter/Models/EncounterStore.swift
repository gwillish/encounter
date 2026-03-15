//
//  EncounterStore.swift
//  Encounter
//
//  Persistence layer for EncounterDefinition documents.
//  Each definition is stored as a JSON file named <UUID>.encounter.json
//  in a single flat directory.
//
//  Storage location (resolved once at app launch via defaultDirectory()):
//    iCloud available:  <ubiquityContainer>/Documents/Encounters/
//    iCloud unavailable: <applicationSupport>/Encounters/
//
//  iCloud Drive syncs the ubiquity container automatically with no
//  CloudKit record API required. Requires the iCloud Documents capability
//  and an NSUbiquitousContainers entry in Info.plist.
//

import Foundation
import Observation

// MARK: - EncounterStoreError

/// Errors thrown by ``EncounterStore`` operations.
public enum EncounterStoreError: Error, LocalizedError {
    case notFound(UUID)
    case saveFailed(UUID, Error)
    case deleteFailed(UUID, Error)

    public var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "No encounter definition found with ID \(id)."
        case .saveFailed(let id, let underlying):
            return "Failed to save encounter \(id): \(underlying.localizedDescription)"
        case .deleteFailed(let id, let underlying):
            return "Failed to delete encounter \(id): \(underlying.localizedDescription)"
        }
    }
}

// MARK: - EncounterStore

/// Persistence layer for ``EncounterDefinition`` documents.
///
/// Each definition is stored as a single JSON file (`<UUID>.encounter.json`)
/// in a flat directory. iCloud Drive syncs the directory automatically when
/// the app is configured with the iCloud Documents capability.
///
/// Inject into the SwiftUI environment at app launch:
///
/// ```swift
/// @State private var store = EncounterStore(directory: EncounterStore.localDirectory)
///
/// var body: some Scene {
///     WindowGroup {
///         ContentView()
///             .environment(store)
///             .task {
///                 let dir = await EncounterStore.defaultDirectory()
///                 await store.relocate(to: dir)
///                 await store.load()
///             }
///     }
/// }
/// ```
@Observable
public final class EncounterStore {

    // MARK: Public State

    /// All loaded encounter definitions, sorted by `modifiedAt` descending.
    public private(set) var definitions: [EncounterDefinition] = []

    /// The directory where `.encounter.json` files are stored.
    public private(set) var directory: URL

    // MARK: - Init

    public init(directory: URL) {
        self.directory = directory
    }

    // MARK: - Directory Resolution

    /// Returns the preferred storage directory, using iCloud when available.
    ///
    /// `url(forUbiquityContainerIdentifier:)` may perform file-system operations,
    /// so this method is `async` and runs on a background task.
    public static func defaultDirectory() async -> URL {
        await Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            if let ubiquity = fm.url(forUbiquityContainerIdentifier: nil) {
                let dir = ubiquity
                    .appendingPathComponent("Documents")
                    .appendingPathComponent("Encounters")
                try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
                return dir
            }
            return Self.localDirectory
        }.value
    }

    /// Local Application Support directory. Safe to access synchronously.
    nonisolated public static var localDirectory: URL {
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("Encounters")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Switches to a new storage directory without reloading.
    /// Call `load()` afterwards to populate `definitions` from the new location.
    public func relocate(to newDirectory: URL) async {
        directory = newDirectory
    }

    // MARK: - Load

    /// Reads all `.encounter.json` files from `directory`.
    ///
    /// Corrupt or unreadable files are skipped silently.
    /// Valid definitions are published via ``definitions``, sorted by
    /// `modifiedAt` descending.
    public func load() async {
        let dir = directory
        let loaded = await Task.detached(priority: .userInitiated) {
            var result: [EncounterDefinition] = []
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil
            ) else { return result }

            let decoder = JSONDecoder()
            for url in contents where url.lastPathComponent.hasSuffix(".encounter.json") {
                guard let data = try? Data(contentsOf: url),
                      let def = try? decoder.decode(EncounterDefinition.self, from: data)
                else { continue }
                result.append(def)
            }
            return result
        }.value

        definitions = loaded.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    // MARK: - Create

    /// Creates a new ``EncounterDefinition``, persists it, and inserts it
    /// into ``definitions``.
    public func create(name: String) async throws {
        let def = EncounterDefinition(name: name)
        try await persist(def)
        insertSorted(def)
    }

    // MARK: - Save

    /// Persists an updated definition to disk and refreshes ``definitions``.
    ///
    /// - Throws: ``EncounterStoreError/notFound(_:)`` if the ID is not in
    ///   the current ``definitions``.
    public func save(_ definition: EncounterDefinition) async throws {
        guard definitions.contains(where: { $0.id == definition.id }) else {
            throw EncounterStoreError.notFound(definition.id)
        }
        try await persist(definition)
        updateInPlace(definition)
    }

    // MARK: - Delete

    /// Removes a definition from memory and deletes its backing file.
    ///
    /// - Throws: ``EncounterStoreError/notFound(_:)`` if the ID is unknown.
    public func delete(id: UUID) async throws {
        guard definitions.contains(where: { $0.id == id }) else {
            throw EncounterStoreError.notFound(id)
        }
        let url = fileURL(for: id)
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw EncounterStoreError.deleteFailed(id, error)
        }
        definitions.removeAll { $0.id == id }
    }

    // MARK: - Duplicate

    /// Creates an independent copy of an existing definition with a new UUID
    /// and `createdAt`, persists it, and adds it to ``definitions``.
    ///
    /// - Throws: ``EncounterStoreError/notFound(_:)`` if the source ID is unknown.
    public func duplicate(id: UUID) async throws {
        guard let original = definitions.first(where: { $0.id == id }) else {
            throw EncounterStoreError.notFound(id)
        }
        let copy = EncounterDefinition(
            name: original.name,
            adversaryIDs: original.adversaryIDs,
            environmentIDs: original.environmentIDs,
            playerConfigs: original.playerConfigs,
            gmNotes: original.gmNotes
        )
        try await persist(copy)
        insertSorted(copy)
    }

    // MARK: - Private Helpers

    private func fileURL(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).encounter.json")
    }

    private func persist(_ definition: EncounterDefinition) async throws {
        let url = fileURL(for: definition.id)
        do {
            let data = try JSONEncoder().encode(definition)
            try data.write(to: url, options: .atomic)
        } catch {
            throw EncounterStoreError.saveFailed(definition.id, error)
        }
    }

    private func insertSorted(_ definition: EncounterDefinition) {
        definitions.append(definition)
        definitions.sort { $0.modifiedAt > $1.modifiedAt }
    }

    private func updateInPlace(_ definition: EncounterDefinition) {
        if let idx = definitions.firstIndex(where: { $0.id == definition.id }) {
            definitions[idx] = definition
        } else {
            definitions.append(definition)
        }
        definitions.sort { $0.modifiedAt > $1.modifiedAt }
    }
}
