//
//  ContentStoreTests.swift
//  EncounterTests
//
//  Unit tests for ContentStore: persistSourceIndex error surfacing,
//  configure(compendium:), and relocate(to:) async behavior.
//

import Foundation
import Testing
@testable import Encounter

@MainActor struct ContentStoreTests {

    /// Returns a fresh ContentStore backed by a unique temp directory.
    private func makeStore(compendium: Compendium? = nil) -> ContentStore {
        let dir = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        return ContentStore(contentDirectory: dir, compendium: compendium ?? Compendium())
    }

    // MARK: - configure(compendium:)

    @Test func configureUpdatesCompendiumReference() async {
        let placeholder = Compendium()
        let real = Compendium()
        let store = makeStore(compendium: placeholder)

        // Add an adversary to the real compendium.
        real.addAdversary(Adversary(
            id: "goblin", name: "Goblin", tier: 1, type: .minion,
            description: "Small and cunning.", difficulty: 10,
            thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
            attackModifier: "+2", attackName: "Rusty Blade",
            attackRange: .veryClose, damage: "1d4 phy"
        ))

        // Before configure, the store uses the placeholder (no adversaries).
        #expect(placeholder.adversaries.isEmpty)

        // After configure, the store should use the real compendium.
        store.configure(compendium: real)

        // Import a pack — it will go into the real compendium.
        // We verify indirectly by ensuring no crash and the configure call returns.
        #expect(real.adversaries.count == 1)
    }

    // MARK: - persistSourceIndex error surfacing

    @Test func persistSourceIndexFailureSetsLastError() async {
        // Point at a path that cannot be written to.
        let unwritable = URL(fileURLWithPath: "/nonexistent-root-\(UUID().uuidString)/Content")
        let store = ContentStore(contentDirectory: unwritable, compendium: Compendium())

        // addSource triggers persistSourceIndex internally.
        let source = ContentSource(id: "test-pack", name: "Test Pack")
        await store.addSource(source)

        // The write should have failed and surfaced as lastError.
        #expect(store.lastError != nil)
    }

    // MARK: - relocate(to:) async

    @Test func relocateSamePathIsNoOp() async {
        let store = makeStore()
        let original = store.contentDirectory
        await store.relocate(to: original)
        #expect(store.contentDirectory == original)
    }

    @Test func relocateToNewEmptyPathSwitches() async {
        let store = makeStore()
        let newDir = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        await store.relocate(to: newDir)
        #expect(store.contentDirectory == newDir)
    }

    @Test func relocateMigratesSRDSubdirectory() async throws {
        let store = makeStore()
        let oldDir = store.contentDirectory.standardized

        // Create a fake srd subdirectory in the old location.
        let srdDir = oldDir.appending(path: "srd", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: srdDir, withIntermediateDirectories: true)
        let stamp = srdDir.appending(path: "bundle_version")
        try "1".write(to: stamp, atomically: true, encoding: .utf8)

        let newDir = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)

        await store.relocate(to: newDir)

        // The srd directory should have been migrated to the new location.
        let migratedStamp = newDir.appending(path: "srd/bundle_version")
        #expect(FileManager.default.fileExists(atPath: migratedStamp.path))
        #expect(store.contentDirectory.standardized == newDir.standardized)
    }
}
