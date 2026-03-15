//
//  EncounterApp.swift
//  Encounter
//
//  Created by Joe Heck on 3/14/26.
//

import SwiftUI

@main
struct EncounterApp: App {
    @State private var compendium = Compendium()
    @State private var store = EncounterStore(directory: EncounterStore.localDirectory)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(compendium)
                .environment(store)
                .task {
                    let dir = await EncounterStore.defaultDirectory()
                    store.relocate(to: dir)
                    // Both loads are independent — run concurrently.
                    // Errors surface via compendium.loadError / store.loadError
                    // for views to observe; the thrown error from compendium.load()
                    // is intentionally not propagated here.
                    async let compendiumLoad: Void = compendium.load()
                    async let storeLoad: Void = store.load()
                    do { try await compendiumLoad } catch {}
                    await storeLoad
                }
        }
    }
}
