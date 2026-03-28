//
//  ContentView.swift
//  Encounter
//
//

import DHKit
import DHModels
import SwiftUI

struct ContentView: View {
  @Environment(EncounterStore.self) private var store
  @State private var selection: EncounterDefinition.ID?

  var body: some View {
    #if os(macOS)
      NavigationSplitView {
        EncounterLibraryView(selection: $selection)
      } detail: {
        NavigationStack {
          if let id = selection,
            let definition = store.definitions.first(where: { $0.id == id })
          {
            EncounterBuilderView(definition: definition)
              .id(id)
          } else {
            Text("Select an encounter")
              .foregroundStyle(.secondary)
          }
        }
      }
    #else
      NavigationStack {
        EncounterLibraryView(selection: $selection)
      }
    #endif
  }
}

#Preview {
  ContentView()
    .environment(EncounterStore(directory: .temporaryDirectory))
    .environment(Compendium())
    .environment(SessionRegistry())
}
