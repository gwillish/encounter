#if DEBUG
  //
  //  PlayerStripExplorationView.swift
  //  Encounter
  //
  //  Exploration scene showing PlayerStrip and PlayerStripRow in varied states.
  //  Uses real components with hardcoded sample data — no live stores needed.
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

  struct PlayerStripExplorationView: View {
    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: 32) {
          stripSection(
            label: "Four players — varied states",
            subtitle:
              "Full HP · Damaged · Critical + condition · Full HP + depleted armor + conditions",
            session: fullSession
          )
          stripSection(
            label: "Edge cases",
            subtitle: "Very long name · Minimum HP + max stress + multiple conditions",
            session: longNameSession
          )
        }
        .padding()
      }
    }

    private func stripSection(label: String, subtitle: String, session: EncounterSession)
      -> some View
    {
      VStack(alignment: .leading, spacing: 8) {
        VStack(alignment: .leading, spacing: 2) {
          Text(label)
            .font(.headline)
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        PlayerStrip(session: session)
          .clipShape(.rect(cornerRadius: 10))
      }
    }
  }

  #Preview {
    NavigationStack {
      PlayerStripExplorationView()
        .navigationTitle("Player Strip")
    }
  }
#endif
