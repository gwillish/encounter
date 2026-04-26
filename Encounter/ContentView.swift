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
  /// Set when the user taps Resume; drives .fullScreenCover to present the runner.
  @State private var activeResumedTarget: ResumeTarget?
  /// Holds the resume target chosen inside the sheet while the sheet is still
  /// animating out. Transferred to activeResumedTarget in onDismiss so the
  /// fullScreenCover presentation starts after the sheet is fully gone,
  /// avoiding back-to-back iOS 26 presentation-transition collisions.
  @State private var pendingResumeTarget: ResumeTarget?

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
    .sheet(
      item: $resumeSheetPayload,
      onDismiss: {
        resumeDismissed = true
        // Transfer any pending resume target now that the sheet is fully
        // dismissed, so fullScreenCover doesn't fight an in-flight
        // sheet-dismissal animation on iOS 26.
        if let t = pendingResumeTarget {
          activeResumedTarget = t
          pendingResumeTarget = nil
        }
      }
    ) { payload in
      ResumePromptView(targets: payload.targets) { target in
        // Store the target and clear the sheet; onDismiss will pick it up.
        pendingResumeTarget = target
        resumeSheetPayload = nil
      }
    }
    #if os(macOS)
      .sheet(item: $activeResumedTarget) { target in
        NavigationStack {
          EncounterRunnerView(session: target.session, definition: target.definition)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Done") { activeResumedTarget = nil }
              .accessibilityIdentifier("runner.done-button")
            }
          }
        }
      }
    #else
      .fullScreenCover(item: $activeResumedTarget) { target in
        NavigationStack {
          EncounterRunnerView(session: target.session, definition: target.definition)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Done") { activeResumedTarget = nil }
              .accessibilityIdentifier("runner.done-button")
            }
          }
        }
      }
    #endif
  }

  // MARK: - Resume helpers

  private func snapshotAndShowResume() {
    // The guard prevents double-presentation: both onChange(sessionStore.isLoaded)
    // and onChange(store.isLoading) can fire on the same run-loop turn when both
    // conditions become true simultaneously. The second call is safely no-op'd
    // because resumeSheetPayload is already non-nil from the first.
    guard !resumeDismissed && resumeSheetPayload == nil else { return }
    // Snapshot launch-time candidate IDs exactly once; allow target
    // resolution to retry on subsequent triggers if definitions weren't
    // available on the first pass.
    if resumeCandidateSessionIDs.isEmpty {
      resumeCandidateSessionIDs = Set(sessionRegistry.sessions.values.map { $0.id })
    }
    let targets = resumeTargets
    if !targets.isEmpty {
      resumeSheetPayload = ResumeSheetPayload(targets: targets)
    }
  }

  // MARK: - macOS

  #if os(macOS)
    @State private var sidebarItem: SidebarItem? = .encounters

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
          EncounterLibraryView(selection: $encounterSelection)
        case .party:
          PartyOverviewView()
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
        Tab("Encounters", systemImage: "list.bullet.clipboard") {
          NavigationStack {
            EncounterLibraryView(selection: $encounterSelection)
          }
        }
        .accessibilityIdentifier("tab.encounters")

        Tab("Party", systemImage: "person.2") {
          NavigationStack {
            PartyOverviewView()
          }
        }
        .accessibilityIdentifier("tab.party")
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
