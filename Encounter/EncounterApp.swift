//
//  EncounterApp.swift
//  Encounter
//
//  Created by Joe Heck on 3/14/26.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct EncounterApp: App {
    @State private var compendium     = Compendium()
    @State private var store          = EncounterStore(directory: EncounterStore.localDirectory)
    @State private var sessionRegistry = SessionRegistry()
    @State private var contentStore: ContentStore?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(compendium)
                .environment(store)
                .environment(sessionRegistry)
                .task {
                    let dir = await EncounterStore.defaultDirectory()
                    store.relocate(to: dir)

                    // Set up ContentStore once the writable directory is known.
                    let contentDir = dir.deletingLastPathComponent()
                        .appendingPathComponent("Content", isDirectory: true)
                    let cs = ContentStore(contentDirectory: contentDir, compendium: compendium)
                    contentStore = cs

                    // All three loads are independent — run concurrently.
                    async let compendiumLoad: Void = compendium.load()
                    async let storeLoad: Void      = store.load()
                    async let contentLoad: Void    = cs.loadOnStartup()
                    do { try await compendiumLoad } catch {}
                    await storeLoad
                    await contentLoad
                }
                // onOpenURL on the root view (as close to the scene root as possible)
                // handles .dhpack file opens on both iOS and macOS.
                .onOpenURL { url in
                    guard url.pathExtension.lowercased() == "dhpack" else { return }
                    guard url.startAccessingSecurityScopedResource() else { return }
                    Task { @MainActor in
                        defer { url.stopAccessingSecurityScopedResource() }
                        await contentStore?.importPack(from: url)
                    }
                }
        }
    }
}
