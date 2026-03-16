//
//  EncounterBuilderView.swift
//  Encounter
//
//  Stub destination shown when a library row is tapped.
//  Full builder (adversary/environment/player configuration) is Step 3.
//

import SwiftUI

struct EncounterBuilderView: View {
    let definition: EncounterDefinition

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
        }
    }
}

#Preview {
    NavigationStack {
        EncounterBuilderView(
            definition: EncounterDefinition(name: "Goblin Ambush")
        )
    }
}
