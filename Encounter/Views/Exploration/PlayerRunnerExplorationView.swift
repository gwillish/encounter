#if DEBUG
  //
  //  PlayerRunnerExplorationView.swift
  //  Encounter
  //
  //  Exploration scene showing PlayerRunnerSection (collapsed and expanded)
  //  in varied player states. Uses real components with hardcoded sample data.
  //

  import DHKit
  import DHModels
  import SwiftUI

  // MARK: - Sample sessions

  private let fullSession: EncounterSession = EncounterSession(
    name: "Four-player party",
    playerSlots: [
      PlayerState(
        name: "Aria Dawnwhisper",
        maxHP: 12, maxStress: 6,
        evasion: 14, thresholdMajor: 6, thresholdSevere: 12,
        armorSlots: 3
      ),
      PlayerState(
        name: "Theron Ashvale",
        maxHP: 10, currentHP: 4,
        maxStress: 5, currentStress: 3,
        evasion: 12, thresholdMajor: 5, thresholdSevere: 10,
        armorSlots: 2
      ),
      PlayerState(
        name: "Zira Coldbrook",
        maxHP: 8, currentHP: 2,
        maxStress: 7, currentStress: 5,
        evasion: 16, thresholdMajor: 4, thresholdSevere: 8,
        armorSlots: 0,
        conditions: [.vulnerable]
      ),
      PlayerState(
        name: "Bramwell the Unbroken",
        maxHP: 14, currentHP: 14,
        maxStress: 4, currentStress: 0,
        evasion: 11, thresholdMajor: 8, thresholdSevere: 15,
        armorSlots: 3, currentArmorSlots: 1,
        conditions: [.restrained, .hidden]
      ),
    ]
  )

  private let longNameSession: EncounterSession = EncounterSession(
    name: "Long name stress test",
    playerSlots: [
      PlayerState(
        name: "Bartholomew Nightshade-Quincey",
        maxHP: 10, maxStress: 5,
        evasion: 12, thresholdMajor: 5, thresholdSevere: 10,
        armorSlots: 2
      ),
      PlayerState(
        name: "A",
        maxHP: 6, currentHP: 1,
        maxStress: 6, currentStress: 6,
        evasion: 10, thresholdMajor: 4, thresholdSevere: 8,
        armorSlots: 0,
        conditions: [.vulnerable, .restrained]
      ),
    ]
  )

  // MARK: - View

  struct PlayerRunnerExplorationView: View {
    @State private var expandedItemID: UUID? = nil

    var body: some View {
      List {
        Section {
          PlayerRunnerSection(
            slots: fullSession.playerSlots,
            expandedItemID: $expandedItemID,
            session: fullSession
          )
        } header: {
          Text("Four players — varied states")
        }

        Section {
          PlayerRunnerSection(
            slots: longNameSession.playerSlots,
            expandedItemID: $expandedItemID,
            session: longNameSession
          )
        } header: {
          Text("Edge cases — long name · max stress")
        }
      }
    }
  }

  #Preview {
    NavigationStack {
      PlayerRunnerExplorationView()
        .navigationTitle("Player Runner")
    }
  }
#endif
