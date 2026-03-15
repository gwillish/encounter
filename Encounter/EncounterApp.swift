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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(compendium)
                .task { try? await compendium.load() }
        }
    }
}
