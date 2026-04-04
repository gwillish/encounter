//
//  PartyOverviewView.swift
//  Encounter
//
//  Front-page party and player management screen.
//  Shows the active party roster and all players not yet in the party.
//
//  Actions:
//   - Add player (form sheet)
//   - Edit player (form sheet, tap or context menu)
//   - Remove from party / Add to party (swipe or context menu)
//   - Delete player (swipe or context menu, confirmation required)
//   - Reset all (toolbar, confirmation required)
//

import DHModels
import SwiftUI

struct PartyOverviewView: View {
  @Environment(PlayerStore.self) private var playerStore

  @State private var showAddPlayer = false
  @State private var editingPlayer: Player?
  @State private var deleteTarget: Player?
  @State private var isConfirmingDelete = false
  @State private var isConfirmingReset = false

  private var nonPartyPlayers: [Player] {
    playerStore.players.filter { !playerStore.party.playerIDs.contains($0.id) }
  }

  var body: some View {
    List {
      activePartySection
      if !nonPartyPlayers.isEmpty {
        rosterSection
      }
    }
    .accessibilityIdentifier("party.list")
    .navigationTitle("Party")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.large)
    #endif
    .toolbar { toolbarContent }
    .overlay {
      if playerStore.players.isEmpty {
        emptyState
      }
    }
    .sheet(isPresented: $showAddPlayer) {
      PlayerForm(mode: .add) { player in
        Task {
          await playerStore.addPlayer(player)
          await playerStore.addToParty(id: player.id)
        }
      }
    }
    .sheet(item: $editingPlayer) { player in
      PlayerForm(mode: .edit(player)) { updated in
        Task { await playerStore.updatePlayer(updated) }
      }
    }
    .confirmationDialog(
      "Delete Player?",
      isPresented: $isConfirmingDelete,
      presenting: deleteTarget
    ) { target in
      Button("Delete \"\(target.name)\"", role: .destructive) {
        Task { await playerStore.deletePlayer(id: target.id) }
      }
      Button("Cancel", role: .cancel) {}
    } message: { _ in
      Text("This action cannot be undone.")
    }
    .confirmationDialog(
      "Reset All Players?",
      isPresented: $isConfirmingReset
    ) {
      Button("Reset All", role: .destructive) {
        Task { await playerStore.resetAll() }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This removes all players and clears the party. This action cannot be undone.")
    }
  }

  // MARK: - Sections

  @ViewBuilder
  private var activePartySection: some View {
    Section {
      if playerStore.activePartyPlayers.isEmpty {
        Text("No players in party.")
          .foregroundStyle(.secondary)
          .accessibilityIdentifier("party.empty-party-label")
      } else {
        ForEach(playerStore.activePartyPlayers) { player in
          PlayerPartyRow(player: player)
            .accessibilityIdentifier("party.active-row")
            .contentShape(Rectangle())
            .onTapGesture { editingPlayer = player }
            .swipeActions(edge: .leading) {
              Button("Edit") { editingPlayer = player }
                .tint(.blue)
            }
            .swipeActions(edge: .trailing) {
              Button("Remove") {
                Task { await playerStore.removeFromParty(id: player.id) }
              }
              .tint(.orange)
            }
            .contextMenu {
              Button("Edit") { editingPlayer = player }
              Button("Remove from Party") {
                Task { await playerStore.removeFromParty(id: player.id) }
              }
              Divider()
              Button("Delete \"\(player.name)\"", role: .destructive) {
                deleteTarget = player
                isConfirmingDelete = true
              }
            }
        }
      }
    } header: {
      Text("Active Party")
    }
  }

  @ViewBuilder
  private var rosterSection: some View {
    Section {
      ForEach(nonPartyPlayers) { player in
        PlayerPartyRow(player: player)
          .accessibilityIdentifier("party.roster-row")
          .contentShape(Rectangle())
          .onTapGesture { editingPlayer = player }
          .swipeActions(edge: .leading) {
            Button("Add to Party") {
              Task { await playerStore.addToParty(id: player.id) }
            }
            .tint(.green)
          }
          .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive) {
              deleteTarget = player
              isConfirmingDelete = true
            }
          }
          .contextMenu {
            Button("Add to Party") {
              Task { await playerStore.addToParty(id: player.id) }
            }
            Button("Edit") { editingPlayer = player }
            Divider()
            Button("Delete \"\(player.name)\"", role: .destructive) {
              deleteTarget = player
              isConfirmingDelete = true
            }
          }
      }
    } header: {
      Text("Roster")
    }
  }

  // MARK: - Toolbar

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Button("Add Player", systemImage: "person.badge.plus") {
        showAddPlayer = true
      }
      .accessibilityIdentifier("party.add-player-button")
    }
    ToolbarItem(placement: .secondaryAction) {
      Button("Reset All", role: .destructive) {
        isConfirmingReset = true
      }
      .disabled(playerStore.players.isEmpty)
      .accessibilityIdentifier("party.reset-all-button")
    }
  }

  // MARK: - Empty State

  private var emptyState: some View {
    ContentUnavailableView {
      Label("No Players", systemImage: "person.2")
    } description: {
      Text("Add your party members to track them across encounters.")
    } actions: {
      Button("Add Player") { showAddPlayer = true }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("party.empty-add-button")
    }
  }
}

#Preview {
  let store = PlayerStore(directory: .temporaryDirectory)
  return NavigationStack {
    PartyOverviewView()
  }
  .environment(store)
}

#Preview("With players") {
  let store = PlayerStore(directory: .temporaryDirectory)
  let aric = Player(
    name: "Aric Stonehammer",
    maxHP: 6, maxStress: 6, evasion: 12,
    thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3
  )
  let lira = Player(
    name: "Lira Dawnwhisper",
    maxHP: 5, maxStress: 7, evasion: 14,
    thresholdMajor: 4, thresholdSevere: 8, armorSlots: 2
  )
  let bench = Player(
    name: "Thornwick",
    maxHP: 7, maxStress: 5, evasion: 11,
    thresholdMajor: 6, thresholdSevere: 12, armorSlots: 2
  )
  Task { @MainActor in
    await store.addPlayer(aric)
    await store.addPlayer(lira)
    await store.addPlayer(bench)
    await store.addToParty(id: aric.id)
    await store.addToParty(id: lira.id)
  }
  return NavigationStack {
    PartyOverviewView()
  }
  .environment(store)
}
