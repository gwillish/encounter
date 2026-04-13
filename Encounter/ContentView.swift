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

// MARK: - ResumeSheetPayload

/// Value passed to .sheet(item:) so the closure receives the snapshot directly
/// rather than reading @State at render time (avoids iOS 26 rendering-race).
private struct ResumeSheetPayload: Identifiable {
  let id = UUID()
  let targets: [ResumeTarget]
}

// MARK: - ContentView

struct ContentView: View {
  @Environment(EncounterStore.self) private var store
  @Environment(SessionRegistry.self) private var sessionRegistry
  @Environment(SessionStore.self) private var sessionStore

  @State private var encounterSelection: EncounterDefinition.ID?

  // MARK: - Resume state

  /// Session IDs present in the registry at load time.
  /// Only these sessions are candidates for the resume prompt; sessions
  /// created later this launch (new runs, resets) are excluded.
  @State private var resumeCandidateSessionIDs: Set<UUID> = []
  @State private var resumeDismissed = false
  /// Sheet payload set once when resume targets are confirmed; nil when no sheet.
  /// Using .sheet(item:) rather than .sheet(isPresented:) so SwiftUI passes
  /// the payload directly to the closure instead of reading @State at render time.
  @State private var resumeSheetPayload: ResumeSheetPayload?

  /// In-flight sessions that were loaded from disk and still have active adversaries.
  private var resumeTargets: [ResumeTarget] {
    sessionRegistry.sessions.values.compactMap { session -> ResumeTarget? in
      guard resumeCandidateSessionIDs.contains(session.id),
        let defID = session.definitionID,
        !session.isOver,
        let def = store.definitions.first(where: { $0.id == defID })
      else { return nil }
      return ResumeTarget(id: session.id, session: session, definition: def)
    }
  }

  var body: some View {
    Group {
      #if os(macOS)
        macOSLayout
      #else
        iOSLayout
      #endif
    }
    // Resume detection: fires once when sessions load, then watches for
    // the store to finish loading so definitions are available to resolve.
    .task {
      if sessionStore.isLoaded && !store.isLoading && !resumeDismissed {
        snapshotAndShowResume()
      }
    }
    .onChange(of: sessionStore.isLoaded) { _, loaded in
      guard loaded && !store.isLoading && !resumeDismissed else { return }
      snapshotAndShowResume()
    }
    .onChange(of: store.isLoading) { _, loading in
      guard !loading && sessionStore.isLoaded && !resumeDismissed else { return }
      snapshotAndShowResume()
    }
    .sheet(item: $resumeSheetPayload, onDismiss: { resumeDismissed = true }) { payload in
      ResumePromptView(targets: payload.targets)
    }
  }

  // MARK: - Resume helpers

  private func snapshotAndShowResume() {
    guard resumeCandidateSessionIDs.isEmpty else { return }
    resumeCandidateSessionIDs = Set(sessionRegistry.sessions.values.map { $0.id })
    let targets = resumeTargets
    if !targets.isEmpty {
      resumeSheetPayload = ResumeSheetPayload(targets: targets)
    }
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
    .environment(SessionStore(directory: .temporaryDirectory))
    .environment(PlayerStore(directory: .temporaryDirectory))
}
