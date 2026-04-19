#if DEBUG
  //
  //  RunnerRowExplorationView.swift
  //  Encounter
  //
  //  Exploration scene showing AdversaryRunnerRow in all slot states.
  //  Uses the real component with hardcoded sample data — no live stores needed.
  //

  import DHKit
  import DHModels
  import SwiftUI

  // MARK: - Sample data

  private let sampleCompendium: Compendium = {
    let c = Compendium()
    c.addAdversary(
      Adversary(
        id: "goblin-brute",
        name: "Goblin Brute",
        tier: 1,
        role: .minion,
        flavorText: "Tough and mean.",
        difficulty: 8,
        thresholdMajor: 5,
        thresholdSevere: 10,
        hp: 10,
        stress: 5,
        attackModifier: "+2",
        attackName: "Club",
        attackRange: .melee,
        damage: "1d8 phy"
      ))
    c.addAdversary(
      Adversary(
        id: "shadow-stalker",
        name: "Shadow Stalker",
        tier: 2,
        role: .solo,
        flavorText: "Moves unseen.",
        difficulty: 14,
        thresholdMajor: 8,
        thresholdSevere: 15,
        hp: 18,
        stress: 8,
        attackModifier: "+5",
        attackName: "Shadow Claw",
        attackRange: .veryClose,
        damage: "2d6+3 phy"
      ))
    return c
  }()

  private struct RowState {
    let label: String
    let slot: AdversaryState
  }

  private let rowStates: [RowState] = [
    RowState(
      label: "Normal — full HP, no stress",
      slot: AdversaryState(
        adversaryID: "goblin-brute",
        maxHP: 10, maxStress: 5
      )
    ),
    RowState(
      label: "Damaged — ~50% HP",
      slot: AdversaryState(
        adversaryID: "goblin-brute",
        maxHP: 10, maxStress: 5,
        currentHP: 5
      )
    ),
    RowState(
      label: "High stress",
      slot: AdversaryState(
        adversaryID: "goblin-brute",
        maxHP: 10, maxStress: 5,
        currentHP: 8, currentStress: 4
      )
    ),
    RowState(
      label: "Single condition — Vulnerable",
      slot: AdversaryState(
        adversaryID: "goblin-brute",
        maxHP: 10, maxStress: 5,
        currentHP: 7,
        conditions: [.vulnerable]
      )
    ),
    RowState(
      label: "Multiple conditions",
      slot: AdversaryState(
        adversaryID: "goblin-brute",
        maxHP: 10, maxStress: 5,
        currentHP: 6, currentStress: 2,
        conditions: [.restrained, .vulnerable]
      )
    ),
    RowState(
      label: "Solo adversary — full HP",
      slot: AdversaryState(
        adversaryID: "shadow-stalker",
        maxHP: 18, maxStress: 8
      )
    ),
    RowState(
      label: "Solo adversary — low HP, stressed, conditioned",
      slot: AdversaryState(
        adversaryID: "shadow-stalker",
        maxHP: 18, maxStress: 8,
        currentHP: 4, currentStress: 6,
        conditions: [.hidden, .vulnerable]
      )
    ),
    RowState(
      label: "Defeated",
      slot: AdversaryState(
        adversaryID: "goblin-brute",
        maxHP: 10, maxStress: 5,
        currentHP: 0, isDefeated: true
      )
    ),
    RowState(
      label: "Unknown adversary (not in compendium)",
      slot: AdversaryState(
        adversaryID: "unknown-beast",
        maxHP: 8, maxStress: 3,
        currentHP: 5
      )
    ),
  ]

  // MARK: - View

  struct RunnerRowExplorationView: View {
    var body: some View {
      List {
        ForEach(rowStates, id: \.label) { state in
          Section {
            if state.slot.isDefeated {
              AdversaryRunnerRow(slot: state.slot, compendium: sampleCompendium)
                .opacity(0.4)
            } else {
              AdversaryRunnerRow(slot: state.slot, compendium: sampleCompendium)
            }
          } header: {
            Text(state.label)
          }
        }
      }
      .environment(sampleCompendium)
    }
  }

  #Preview {
    NavigationStack {
      RunnerRowExplorationView()
        .navigationTitle("Adversary Runner Row")
    }
  }
#endif
