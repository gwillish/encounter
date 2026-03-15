//
//  EncounterLibraryRow.swift
//  Encounter
//
//  A single row in the encounter library list.
//

import SwiftUI

struct EncounterLibraryRow: View {
    let definition: EncounterDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(definition.name)
                .font(.body)
            Text(definition.modifiedAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    EncounterLibraryRow(definition: EncounterDefinition(name: "Goblin Ambush"))
        .padding()
}
