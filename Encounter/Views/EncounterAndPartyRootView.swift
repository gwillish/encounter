//
//  EncounterAndPartyRootView.swift
//  Encounter
//
//  iOS root screen: encounter list + party roster + toolbar mode toggle.
//  Intended to be the root of a NavigationStack in ContentView.
//

#if !os(macOS)

  import DHKit
  import DHModels
  import SwiftUI

  struct EncounterAndPartyRootView: View {
    let store: EncounterStore
    let playerStore: PlayerStore
    let compendium: Compendium
    let contentStore: ContentStore
    let sessionRegistry: SessionRegistry
    let sessionStore: SessionStore

    @State private var rootMode: iOSRootMode
    @State private var isCreating = false
    @State private var newName = ""
    @State private var isRenaming = false
    @State private var renameTarget: EncounterDefinition?
    @State private var renameText = ""
    @State private var isConfirmingDeleteEncounter = false
    @State private var deleteEncounterTarget: EncounterDefinition?
    @State private var actionError: String?
    @State private var isShowingActionError = false
    @State private var isAddingPlayer = false
    @State private var editPlayerTarget: Player?
    @State private var deletePlayerTarget: Player?
    @State private var isConfirmingDeletePlayer = false

    init(
      store: EncounterStore,
      playerStore: PlayerStore,
      compendium: Compendium,
      contentStore: ContentStore,
      sessionRegistry: SessionRegistry,
      sessionStore: SessionStore,
      initialMode: iOSRootMode = .encounters
    ) {
      self.store = store
      self.playerStore = playerStore
      self.compendium = compendium
      self.contentStore = contentStore
      self.sessionRegistry = sessionRegistry
      self.sessionStore = sessionStore
      self._rootMode = State(initialValue: initialMode)
    }

    // MARK: - Derived state

    private var pausedDefinitionIDs: Set<UUID> {
      Set(
        sessionRegistry.sessions.values
          .filter { $0.phase == .paused }
          .compactMap { $0.definitionID }
      )
    }

    private var partyCount: Int? {
      let count = playerStore.activePartyPlayers.count
      return count > 0 ? count : nil
    }

    private var partyPlayers: [Player] {
      playerStore.party.playerIDs.compactMap { id in
        playerStore.players.first { $0.id == id }
      }
    }

    // MARK: - Body

    var body: some View {
      Group {
        switch rootMode {
        case .encounters:
          encountersContent
        case .compendium:
          CompendiumRootView(compendium: compendium, contentStore: contentStore)
        }
      }
      .navigationTitle(rootMode == .encounters ? "Encounters" : "Compendium")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(for: Adversary.self) { adversary in
        AdversaryDetailView(adversary: adversary)
      }
      .toolbar { toolbarContent }
      .alert("New Encounter", isPresented: $isCreating) {
        TextField("Encounter name", text: $newName)
          .accessibilityIdentifier("library.new-name-field")
        Button("Create") { createEncounter() }
        Button("Cancel", role: .cancel) { newName = "" }
      }
      .alert("Rename Encounter", isPresented: $isRenaming, presenting: renameTarget) { _ in
        TextField("Name", text: $renameText)
          .accessibilityIdentifier("library.rename-field")
        Button("Rename") { commitRenameEncounter() }
        Button("Cancel", role: .cancel) {}
      }
      .confirmationDialog(
        "Delete Encounter?",
        isPresented: $isConfirmingDeleteEncounter,
        presenting: deleteEncounterTarget
      ) { target in
        Button("Delete \"\(target.name)\"", role: .destructive) { commitDeleteEncounter() }
        Button("Cancel", role: .cancel) {}
      } message: { _ in
        Text("This action cannot be undone.")
      }
      .confirmationDialog(
        "Remove Player?",
        isPresented: $isConfirmingDeletePlayer,
        presenting: deletePlayerTarget
      ) { target in
        Button("Remove \"\(target.name)\"", role: .destructive) { commitDeletePlayer() }
        Button("Cancel", role: .cancel) {}
      } message: { _ in
        Text("This action cannot be undone.")
      }
      .sheet(isPresented: $isAddingPlayer) {
        PlayerForm(mode: .add) { player in
          Task {
            await playerStore.addPlayer(player)
            await playerStore.addToParty(id: player.id)
          }
        }
      }
      .sheet(item: $editPlayerTarget) { player in
        PlayerForm(mode: .edit(player)) { updated in
          Task { await playerStore.updatePlayer(updated) }
        }
      }
      .alert("Action Failed", isPresented: $isShowingActionError) {
        Button("OK", role: .cancel) { actionError = nil }
      } message: {
        Text(actionError ?? "")
      }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
      ToolbarItem(placement: .principal) {
        Picker("Mode", selection: $rootMode) {
          ForEach(iOSRootMode.allCases, id: \.self) { mode in
            Text(mode.rawValue).tag(mode)
          }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 240)
        .accessibilityLabel("View mode")
        .accessibilityIdentifier("root.mode-toggle")
      }
      if rootMode == .encounters {
        ToolbarItem(placement: .primaryAction) {
          Button("New Encounter", systemImage: "plus") { beginCreateEncounter() }
            .accessibilityIdentifier("library.create-button")
        }
        ToolbarItem(placement: .secondaryAction) {
          Button("Add Player", systemImage: "person.badge.plus") { isAddingPlayer = true }
            .accessibilityIdentifier("party.add-button")
        }
      }
    }

    // MARK: - Encounters content

    private var encountersContent: some View {
      List {
        Section("Encounters") {
          if store.isLoading {
            ProgressView()
          } else if store.definitions.isEmpty {
            Text("No encounters yet")
              .foregroundStyle(.secondary)
          } else {
            ForEach(store.definitions) { definition in
              NavigationLink(value: definition) {
                EncounterLibraryRow(
                  definition: definition,
                  playerCount: partyCount,
                  compendium: compendium,
                  isPaused: pausedDefinitionIDs.contains(definition.id)
                )
              }
              .accessibilityIdentifier("root.encounter-row.\(definition.id)")
              .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                  beginDeleteEncounter(definition)
                } label: {
                  Label("Delete", systemImage: "trash")
                }
                Button {
                  beginRenameEncounter(definition)
                } label: {
                  Label("Rename", systemImage: "pencil")
                }
                .tint(.orange)
              }
            }
          }
        }

        Section("Party") {
          if partyPlayers.isEmpty {
            Text("No party members")
              .foregroundStyle(.secondary)
          } else {
            ForEach(partyPlayers) { player in
              partyRow(for: player)
            }
          }
        }
      }
      .navigationDestination(for: EncounterDefinition.self) { definition in
        EncounterEditorView(
          definition: definition,
          store: store,
          compendium: compendium,
          sessionRegistry: sessionRegistry,
          sessionStore: sessionStore,
          playerStore: playerStore
        )
      }
    }

    // MARK: - Party row

    @ViewBuilder
    private func partyRow(for player: Player) -> some View {
      let hidden = playerStore.hiddenPlayerIDs.contains(player.id)
      HStack(spacing: 10) {
        if hidden {
          Image(systemName: "eye.slash")
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }
        VStack(alignment: .leading, spacing: 2) {
          HStack {
            Text(player.name)
              .font(.body)
            Spacer()
            LevelTierBadge(level: player.level)
          }
        }
      }
      .opacity(hidden ? 0.5 : 1.0)
      .accessibilityIdentifier("root.party-row.\(player.id)")
      .accessibilityLabel(hidden ? "\(player.name), hidden" : player.name)
      .swipeActions(edge: .trailing, allowsFullSwipe: false) {
        Button(role: .destructive) {
          deletePlayerTarget = player
          isConfirmingDeletePlayer = true
        } label: {
          Label("Remove", systemImage: "trash")
        }
        Button {
          editPlayerTarget = player
        } label: {
          Label("Edit", systemImage: "pencil")
        }
        .tint(.orange)
      }
      .swipeActions(edge: .leading) {
        if hidden {
          Button {
            Task { await playerStore.revealPlayer(id: player.id) }
          } label: {
            Label("Unhide", systemImage: "eye")
          }
          .tint(.green)
          .accessibilityIdentifier("party.unhide-button")
        } else {
          Button {
            Task { await playerStore.hidePlayer(id: player.id) }
          } label: {
            Label("Hide", systemImage: "eye.slash")
          }
          .tint(.gray)
          .accessibilityIdentifier("party.hide-button")
        }
      }
    }

    // MARK: - Encounter actions

    private func beginCreateEncounter() {
      newName = ""
      isCreating = true
    }

    private func createEncounter() {
      let trimmed = newName.trimmingCharacters(in: .whitespaces)
      let finalName = trimmed.isEmpty ? "New Encounter" : trimmed
      newName = ""
      Task {
        do {
          try await store.create(name: finalName)
        } catch {
          actionError = error.localizedDescription
          isShowingActionError = true
        }
      }
    }

    private func beginRenameEncounter(_ definition: EncounterDefinition) {
      renameText = definition.name
      renameTarget = definition
      isRenaming = true
    }

    private func commitRenameEncounter() {
      guard var target = renameTarget else { return }
      let trimmed = renameText.trimmingCharacters(in: .whitespaces)
      target.name = trimmed.isEmpty ? target.name : trimmed
      renameTarget = nil
      Task {
        do {
          try await store.save(target)
        } catch {
          actionError = error.localizedDescription
          isShowingActionError = true
        }
      }
    }

    private func beginDeleteEncounter(_ definition: EncounterDefinition) {
      deleteEncounterTarget = definition
      isConfirmingDeleteEncounter = true
    }

    private func commitDeleteEncounter() {
      guard let target = deleteEncounterTarget else { return }
      deleteEncounterTarget = nil
      Task {
        do {
          try await store.delete(id: target.id)
        } catch {
          actionError = error.localizedDescription
          isShowingActionError = true
        }
      }
    }

    // MARK: - Player actions

    private func commitDeletePlayer() {
      guard let target = deletePlayerTarget else { return }
      deletePlayerTarget = nil
      Task { await playerStore.deletePlayer(id: target.id) }
    }
  }

  // MARK: - Preview

  #Preview("Empty state") {
    NavigationStack {
      EncounterAndPartyRootView(
        store: PreviewData.encounterStore(),
        playerStore: PreviewData.playerStore(),
        compendium: PreviewData.compendium(),
        contentStore: PreviewData.contentStore(),
        sessionRegistry: PreviewData.sessionRegistry(),
        sessionStore: PreviewData.sessionStore()
      )
    }
  }

  #Preview("Compendium mode") {
    NavigationStack {
      EncounterAndPartyRootView(
        store: PreviewData.encounterStore(),
        playerStore: PreviewData.playerStore(),
        compendium: PreviewData.compendium(),
        contentStore: PreviewData.contentStore(),
        sessionRegistry: PreviewData.sessionRegistry(),
        sessionStore: PreviewData.sessionStore(),
        initialMode: .compendium
      )
    }
  }

#endif
