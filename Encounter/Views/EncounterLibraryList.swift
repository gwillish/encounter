//
//  EncounterLibraryList.swift
//  Encounter
//
//  The populated list of encounter definitions with swipe and context menu actions.
//

import DHKit
import DHModels
import SwiftUI

struct EncounterLibraryList: View {
  let definitions: [EncounterDefinition]
  @Binding var selection: EncounterDefinition.ID?
  let onRename: (EncounterDefinition) -> Void
  let onDelete: (EncounterDefinition) -> Void

  @Environment(PlayerStore.self) private var playerStore

  private var partyCount: Int? {
    let count = playerStore.activePartyPlayers.count
    return count > 0 ? count : nil
  }

  var body: some View {
    List(definitions, selection: $selection) { definition in
      #if os(macOS)
        EncounterLibraryRow(definition: definition, playerCount: partyCount)
          .accessibilityIdentifier("library.row")
          .accessibilityValue(definition.name)
          .contextMenu {
            Button {
              onRename(definition)
            } label: {
              Label("Rename", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
              onDelete(definition)
            } label: {
              Label("Delete", systemImage: "trash")
            }
          }
      #else
        NavigationLink(value: definition) {
          EncounterLibraryRow(definition: definition, playerCount: partyCount)
        }
        .accessibilityIdentifier("library.row")
        .accessibilityValue(definition.name)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
          Button(role: .destructive) {
            onDelete(definition)
          } label: {
            Label("Delete", systemImage: "trash")
          }
          Button {
            onRename(definition)
          } label: {
            Label("Rename", systemImage: "pencil")
          }
          .tint(.orange)
        }
        .contextMenu {
          Button {
            onRename(definition)
          } label: {
            Label("Rename", systemImage: "pencil")
          }
          Divider()
          Button(role: .destructive) {
            onDelete(definition)
          } label: {
            Label("Delete", systemImage: "trash")
          }
        }
      #endif
    }
    #if !os(macOS)
      .navigationDestination(for: EncounterDefinition.self) { definition in
        EncounterBuilderView(definition: definition)
      }
    #endif
    .accessibilityIdentifier("library.list")
  }
}

#Preview {
  @Previewable @State var selection: EncounterDefinition.ID? = nil
  NavigationStack {
    EncounterLibraryList(
      definitions: [
        EncounterDefinition(name: "Goblin Ambush"),
        EncounterDefinition(name: "Dragon's Lair"),
      ],
      selection: $selection,
      onRename: { _ in },
      onDelete: { _ in }
    )
  }
  .environment(Compendium())
  .environment(PlayerStore(directory: .temporaryDirectory))
}
