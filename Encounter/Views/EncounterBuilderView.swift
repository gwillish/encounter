//
//  EncounterBuilderView.swift
//  Encounter
//
//  Stub destination shown when a library row is tapped.
//  Full builder (adversary/environment/player configuration) is Step 3.
//
//  The compendium browser sheet is wired now (Step 2 seam).
//  onSelect and onSelectEnvironment closures will be filled in during Step 3.
//

import SwiftUI

struct EncounterBuilderView: View {
    let definition: EncounterDefinition

    @Environment(Compendium.self) private var compendium
    @State private var showCompendium = false

    var body: some View {
        ContentUnavailableView {
            Label("Encounter Builder", systemImage: "hammer")
        } description: {
            Text("Coming soon — adversary and player setup will appear here.")
        }
        .navigationTitle(definition.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Run Encounter") {}
                    .disabled(true)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Browse Compendium", systemImage: "books.vertical") {
                    showCompendium = true
                }
            }
        }
        .sheet(isPresented: $showCompendium) {
            NavigationStack {
                CompendiumBrowserView(
                    onSelect: { adversary in
                        // Step 3: add adversary.id to definition and save via store
                        _ = adversary
                        showCompendium = false
                    },
                    onSelectEnvironment: { environment in
                        // Step 3: add environment.id to definition and save via store
                        _ = environment
                        showCompendium = false
                    }
                )
            }
            .environment(compendium)
        }
    }
}

#Preview {
    NavigationStack {
        EncounterBuilderView(
            definition: EncounterDefinition(name: "Goblin Ambush")
        )
    }
    .environment(Compendium())
}
