//
//  EncounterBuilderView.swift
//  Encounter
//
//  Full encounter preparation screen.
//  Manages a local draft copy of the EncounterDefinition and auto-saves
//  after every mutation via EncounterStore.
//
//  Run Encounter snapshots the active party from PlayerStore into the
//  session at start time; the builder player roster is read-only.
//

import DHKit
import DHModels
import SwiftUI

struct EncounterBuilderView: View {
  let definition: EncounterDefinition
  let store: EncounterStore
  let compendium: Compendium
  let sessionRegistry: SessionRegistry
  let sessionStore: SessionStore
  let playerStore: PlayerStore

  @State private var draft: EncounterDefinition
  @State private var showCompendium = false
  @State private var notesExpanded = false
  @State private var manualAdjustments: Set<DifficultyBudget.Adjustment> = []
  @State private var saveError: String?
  @State private var runSession: EncounterSession?
  @State private var saveTask: Task<Void, Never>?
  @State private var showResetConfirmation = false

  init(
    definition: EncounterDefinition,
    store: EncounterStore,
    compendium: Compendium,
    sessionRegistry: SessionRegistry,
    sessionStore: SessionStore,
    playerStore: PlayerStore
  ) {
    self.definition = definition
    self.store = store
    self.compendium = compendium
    self.sessionRegistry = sessionRegistry
    self.sessionStore = sessionStore
    self.playerStore = playerStore
    _draft = State(initialValue: definition)
  }

  // MARK: - Session state

  private var hasActiveSession: Bool {
    sessionRegistry.sessions[draft.id] != nil
  }

  // MARK: - Computed difficulty

  private var adversaryTypes: [AdversaryType] {
    draft.adversaryIDs.compactMap { compendium.adversary(id: $0)?.role }
  }

  private var autoAdjustments: Set<DifficultyBudget.Adjustment> {
    DifficultyBudget.suggestedAdjustments(adversaryTypes: adversaryTypes)
  }

  private var budgetAdjustment: Int {
    autoAdjustments.union(manualAdjustments).reduce(0) { $0 + $1.pointValue }
  }

  private var difficultyRating: DifficultyBudget.Rating? {
    DifficultyBudget.rating(
      adversaryTypes: adversaryTypes,
      playerCount: playerStore.activePartyPlayers.count,
      budgetAdjustment: budgetAdjustment
    )
  }

  // MARK: - Body

  var body: some View {
    Form {
      AdversaryRosterSection(
        adversaryIDs: draft.adversaryIDs,
        compendium: compendium,
        onBrowse: { showCompendium = true },
        onRemove: removeAdversary(at:)
      )
      EnvironmentSection(
        environmentIDs: draft.environmentIDs,
        compendium: compendium,
        onBrowse: { showCompendium = true },
        onRemove: removeEnvironment(at:)
      )
      PlayerRosterSection(players: playerStore.activePartyPlayers)
      BuilderNotesSection(
        notes: $draft.gmNotes,
        isExpanded: $notesExpanded,
        onChange: saveDebounced
      )
      Section {
        DifficultyAssessorView(
          rating: difficultyRating,
          autoAdjustments: autoAdjustments,
          manualAdjustments: $manualAdjustments
        )
        .listRowInsets(EdgeInsets())
      }
    }
    .navigationTitle($draft.name)
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      .toolbarRole(.editor)
    #endif
    .toolbar { toolbarContent }
    .safeAreaInset(edge: .top) {
      if let error = saveError {
        EncounterErrorBanner(message: error, onDismiss: { saveError = nil })
      }
    }
    .sheet(isPresented: $showCompendium) {
      NavigationStack {
        CompendiumBrowserView(
          compendium: compendium,
          onSelect: { adversary in
            addAdversary(adversary)
            showCompendium = false
          },
          onSelectEnvironment: { environment in
            setEnvironment(environment)
            showCompendium = false
          }
        )
      }
      #if os(macOS)
        .frame(minWidth: 540, minHeight: 480)
      #endif
    }
    #if os(macOS)
      .sheet(item: $runSession) { session in
        EncounterRunnerContainer(
          session: session, definition: draft,
          compendium: compendium, sessionRegistry: sessionRegistry, sessionStore: sessionStore
        )
      }
    #else
      .fullScreenCover(item: $runSession) { session in
        EncounterRunnerContainer(
          session: session, definition: draft,
          compendium: compendium, sessionRegistry: sessionRegistry, sessionStore: sessionStore
        )
      }
    #endif
    .confirmationDialog(
      "Reset Session?",
      isPresented: $showResetConfirmation,
      titleVisibility: .visible
    ) {
      Button("Reset Session", role: .destructive) {
        let sessionID = sessionRegistry.sessions[draft.id]?.id
        sessionRegistry.clearSession(for: draft.id)
        if let sessionID {
          Task { await sessionStore.delete(sessionID: sessionID) }
        }
      }
      .accessibilityIdentifier("builder.reset-confirm-button")
    } message: {
      Text("The current session will be cleared. The encounter definition is not changed.")
    }
    .onChange(of: definition) { _, newDefinition in
      if newDefinition.modifiedAt > draft.modifiedAt {
        draft = newDefinition
      }
    }
    .onChange(of: draft.name) { _, _ in
      saveDebounced()
    }
  }

  // MARK: - Toolbar

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Button("Run Encounter") {
        // Snapshot the active party into the definition at run time.
        // EncounterDefinition.playerConfigs is not persisted from the builder;
        // it is populated here as a point-in-time copy for session creation only.
        var defWithParty = draft
        defWithParty.playerConfigs = playerStore.activePartyPlayers.map { $0.asConfig() }
        runSession = sessionRegistry.session(for: defWithParty, compendium: compendium)
      }
      .disabled(draft.adversaryIDs.isEmpty || playerStore.party.playerIDs.isEmpty)
      .accessibilityIdentifier("builder.run-button")
    }
    ToolbarItem(placement: .primaryAction) {
      Button("Browse Compendium", systemImage: "books.vertical") {
        showCompendium = true
      }
      .accessibilityIdentifier("builder.browse-compendium-button")
    }
    ToolbarItem(placement: .secondaryAction) {
      if hasActiveSession {
        Button("Reset Session") {
          showResetConfirmation = true
        }
        .accessibilityIdentifier("builder.reset-button")
      }
    }
  }

  // MARK: - Mutations

  private func addAdversary(_ adversary: Adversary) {
    draft.adversaryIDs.append(adversary.id)
    save()
  }

  private func removeAdversary(at offsets: IndexSet) {
    draft.adversaryIDs.remove(atOffsets: offsets)
    save()
  }

  private func setEnvironment(_ environment: DaggerheartEnvironment) {
    draft.environmentIDs = [environment.id]
    save()
  }

  private func removeEnvironment(at offsets: IndexSet) {
    draft.environmentIDs.remove(atOffsets: offsets)
    save()
  }

  private func save() {
    Task {
      do {
        try await store.save(draft)
      } catch {
        saveError = error.localizedDescription
      }
    }
  }

  /// Debounced save for notes changes — coalesces rapid keystrokes into one write.
  private func saveDebounced() {
    saveTask?.cancel()
    saveTask = Task {
      try? await Task.sleep(for: .milliseconds(400))
      guard !Task.isCancelled else { return }
      do {
        try await store.save(draft)
      } catch is CancellationError {
        // Normal — view dismissed or a newer keystroke cancelled this save.
      } catch {
        saveError = error.localizedDescription
      }
    }
  }
}

#Preview {
  let store = EncounterStore(directory: URL.temporaryDirectory.appending(path: "preview-builder"))
  let compendium = Compendium()
  compendium.addAdversary(
    Adversary(
      id: "goblin", name: "Goblin", tier: 1, role: .minion,
      flavorText: "Small and cunning.", difficulty: 10,
      thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
      attackModifier: "+2", attackName: "Rusty Blade",
      attackRange: .veryClose, damage: "1d4 phy"
    ))
  compendium.addAdversary(
    Adversary(
      id: "orc", name: "Orc Bruiser", tier: 2, role: .bruiser,
      flavorText: "Massive and relentless.", difficulty: 14,
      thresholdMajor: 10, thresholdSevere: 20, hp: 8, stress: 4,
      attackModifier: "+5", attackName: "Great Axe",
      attackRange: .veryClose, damage: "2d10+4 phy"
    ))
  let playerStore = PreviewData.playerStore()
  let sessionRegistry = PreviewData.sessionRegistry()
  let sessionStore = PreviewData.sessionStore()
  return NavigationStack {
    EncounterBuilderPreviewWrapper(
      store: store, compendium: compendium,
      sessionRegistry: sessionRegistry, sessionStore: sessionStore,
      playerStore: playerStore
    )
  }
}

/// Preview wrapper that creates a definition in the store before showing the builder.
private struct EncounterBuilderPreviewWrapper: View {
  let store: EncounterStore
  let compendium: Compendium
  let sessionRegistry: SessionRegistry
  let sessionStore: SessionStore
  let playerStore: PlayerStore
  @State private var definition: EncounterDefinition?

  var body: some View {
    Group {
      if let definition {
        EncounterBuilderView(
          definition: definition, store: store, compendium: compendium,
          sessionRegistry: sessionRegistry, sessionStore: sessionStore,
          playerStore: playerStore
        )
      } else {
        ProgressView()
          .task {
            try? await store.create(name: "Goblin Ambush")
            definition = store.definitions.first
          }
      }
    }
  }
}
