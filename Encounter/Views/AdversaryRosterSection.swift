//
//  AdversaryRosterSection.swift
//  Encounter
//
//  Form section listing adversaries added to the encounter.
//  Uses id: \.self on the String IDs; onDelete receives a position-based IndexSet.
//

import SwiftUI

struct AdversaryRosterSection: View {
    let adversaryIDs: [String]
    let compendium: Compendium
    let onBrowse: () -> Void
    let onRemove: (IndexSet) -> Void

    var body: some View {
        Section {
            if adversaryIDs.isEmpty {
                Text("No adversaries added yet.")
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                ForEach(adversaryIDs, id: \.self) { id in
                    AdversaryRosterRow(adversaryID: id, compendium: compendium)
                }
                .onDelete(perform: onRemove)
            }
        } header: {
            HStack {
                Text("Adversaries")
                Spacer()
                Button("Add", systemImage: "plus", action: onBrowse)
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .labelStyle(.iconOnly)
            }
        }
    }
}

#Preview {
    let compendium = Compendium()
    compendium.addAdversary(Adversary(
        id: "goblin", name: "Goblin", tier: 1, type: .minion,
        description: "Small and cunning.", difficulty: 10,
        thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
        attackModifier: "+2", attackName: "Rusty Blade",
        attackRange: .veryClose, damage: "1d4 phy"
    ))
    return Form {
        AdversaryRosterSection(
            adversaryIDs: ["goblin", "goblin"],
            compendium: compendium,
            onBrowse: {},
            onRemove: { _ in }
        )
    }
}
