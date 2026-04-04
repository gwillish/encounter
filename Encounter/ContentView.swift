//
//  ContentView.swift
//  Encounter
//
//  Root navigation container.
//
//  iOS / visionOS: TabView — Party tab first, Encounters tab second.
//  macOS: three-column NavigationSplitView — sidebar selects Party or
//  Encounters, content column shows the corresponding list/overview,
//  detail column shows the encounter builder when an encounter is selected.
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
  @Environment(EncounterStore.self) private var store

  @State private var encounterSelection: EncounterDefinition.ID?

  var body: some View {
    #if os(macOS)
      macOSLayout
    #else
      iOSLayout
    #endif
  }

  // MARK: - macOS

  #if os(macOS)
    @State private var sidebarItem: SidebarItem? = .party

    private var macOSLayout: some View {
      NavigationSplitView {
        List(selection: $sidebarItem) {
          Label("Party", systemImage: "person.2")
            .tag(SidebarItem.party)
            .accessibilityIdentifier("sidebar.party")
          Label("Encounters", systemImage: "list.bullet.clipboard")
            .tag(SidebarItem.encounters)
            .accessibilityIdentifier("sidebar.encounters")
        }
        .navigationTitle("Encounter")
      } content: {
        switch sidebarItem {
        case .party, nil:
          PartyOverviewView()
        case .encounters:
          EncounterLibraryView(selection: $encounterSelection)
        }
      } detail: {
        NavigationStack {
          if case .encounters = sidebarItem,
            let id = encounterSelection,
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
    }
  #endif

  // MARK: - iOS / visionOS

  #if !os(macOS)
    private var iOSLayout: some View {
      TabView {
        Tab("Party", systemImage: "person.2") {
          NavigationStack {
            PartyOverviewView()
          }
        }
        .accessibilityIdentifier("tab.party")

        Tab("Encounters", systemImage: "list.bullet.clipboard") {
          NavigationStack {
            EncounterLibraryView(selection: $encounterSelection)
          }
        }
        .accessibilityIdentifier("tab.encounters")
      }
    }
  #endif
}

#Preview {
  ContentView()
    .environment(EncounterStore(directory: .temporaryDirectory))
    .environment(Compendium())
    .environment(SessionRegistry())
    .environment(PlayerStore(directory: .temporaryDirectory))
}
