//
//  ContentView.swift
//  Encounter
//
//  Root navigation container.
//

import DHKit
import DHModels
import SwiftUI

// MARK: - SidebarItem (macOS)

private enum SidebarItem: Hashable {
  case party
  case encounters
}

// MARK: - ContentView

struct ContentView: View {
  let store: EncounterStore
  let sessionRegistry: SessionRegistry
  let sessionStore: SessionStore
  let compendium: Compendium
  let playerStore: PlayerStore
  let contentStore: ContentStore

  var body: some View {
    #if os(macOS)
      macOSLayout
    #else
      iOSLayout
    #endif
  }

  // MARK: - macOS

  #if os(macOS)
    @State private var sidebarItem: SidebarItem? = .encounters
    @State private var encounterSelection: EncounterDefinition.ID?

    private var macOSLayout: some View {
      NavigationSplitView {
        List(selection: $sidebarItem) {
          Label("Encounters", systemImage: "list.bullet.clipboard")
            .tag(SidebarItem.encounters)
            .accessibilityIdentifier("sidebar.encounters")
          Label("Party", systemImage: "person.2")
            .tag(SidebarItem.party)
            .accessibilityIdentifier("sidebar.party")
        }
        .navigationTitle("Encounter")
      } content: {
        switch sidebarItem {
        case .encounters, nil:  // nil (sidebar deselected) falls through to Encounters
          EncounterLibraryView(
            store: store, playerStore: playerStore, compendium: compendium,
            contentStore: contentStore, sessionRegistry: sessionRegistry,
            sessionStore: sessionStore, selection: $encounterSelection
          )
        case .party:
          PartyOverviewView(playerStore: playerStore)
        }
      } detail: {
        if case .encounters = sidebarItem,
          let id = encounterSelection,
          let definition = store.definitions.first(where: { $0.id == id })
        {
          EncounterEditorView(
            definition: definition, store: store, compendium: compendium,
            sessionRegistry: sessionRegistry, sessionStore: sessionStore,
            playerStore: playerStore
          )
          .id(id)
        } else {
          Text("Select an encounter")
            .foregroundStyle(.secondary)
        }
      }
    }
  #endif

  // MARK: - iOS / visionOS

  #if !os(macOS)
    private var iOSLayout: some View {
      NavigationStack {
        EncounterAndPartyRootView(
          store: store,
          playerStore: playerStore,
          compendium: compendium,
          contentStore: contentStore,
          sessionRegistry: sessionRegistry,
          sessionStore: sessionStore
        )
      }
      .accessibilityIdentifier("root.navigation-stack")
    }
  #endif
}

#Preview {
  ContentView(
    store: PreviewData.encounterStore(),
    sessionRegistry: PreviewData.sessionRegistry(),
    sessionStore: PreviewData.sessionStore(),
    compendium: PreviewData.compendium(),
    playerStore: PreviewData.playerStore(),
    contentStore: PreviewData.contentStore()
  )
}
