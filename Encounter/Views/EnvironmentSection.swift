//
//  EnvironmentSection.swift
//  Encounter
//
//  Form section for the encounter environment.
//  Convention is 0 or 1 environment; the section shows a placeholder
//  when empty and a replace button when one is set.
//

import SwiftUI

struct EnvironmentSection: View {
    let environmentIDs: [String]
    let compendium: Compendium
    let onBrowse: () -> Void
    let onRemove: (IndexSet) -> Void

    var body: some View {
        Section {
            if environmentIDs.isEmpty {
                Button {
                    onBrowse()
                } label: {
                    Label("Add Environment", systemImage: "plus")
                }
            } else {
                ForEach(environmentIDs.indices, id: \.self) { index in
                    let environment = compendium.environment(id: environmentIDs[index])
                    VStack(alignment: .leading, spacing: 2) {
                        Text(environment?.name ?? "Unknown Environment")
                            .font(.body)
                        if let desc = environment?.description {
                            Text(desc)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        } else {
                            Text("ID: \(environmentIDs[index])")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onDelete(perform: onRemove)
            }
        } header: {
            HStack {
                Text("Environment")
                Spacer()
                if !environmentIDs.isEmpty {
                    Button("Replace", systemImage: "arrow.triangle.2.circlepath", action: onBrowse)
                        .buttonStyle(.borderless)
                        .font(.caption)
                        .labelStyle(.iconOnly)
                }
            }
        }
    }
}

#Preview("Empty") {
    Form {
        EnvironmentSection(
            environmentIDs: [],
            compendium: Compendium(),
            onBrowse: {},
            onRemove: { _ in }
        )
    }
}

#Preview("With environment") {
    let compendium = Compendium()
    compendium.addEnvironment(DaggerheartEnvironment(
        id: "collapsing-cavern", name: "Collapsing Cavern",
        description: "The ceiling threatens to fall with every heavy blow."
    ))
    return Form {
        EnvironmentSection(
            environmentIDs: ["collapsing-cavern"],
            compendium: compendium,
            onBrowse: {},
            onRemove: { _ in }
        )
    }
}
