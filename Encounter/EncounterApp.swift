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
                    async let compendiumLoad: Void = compendium.load()
                    let dir = await EncounterStore.defaultDirectory()
                    store.relocate(to: dir)
                    try? await compendiumLoad
                    await store.load()
                }
        }
    }
}
