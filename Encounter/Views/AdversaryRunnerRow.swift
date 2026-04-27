//
//  AdversaryRunnerRow.swift
//  Encounter
//
//  Collapsed adversary row shown in the live encounter runner.
//  Row 1: name, type/tier badge, active condition icons, stress pip track.
//  Row 2: HP pip track.
//  Tapping expands to AdversaryRunnerCard (managed by AdversaryRunnerSection).
//

import DHKit
import DHModels
import SwiftUI

struct AdversaryRunnerRow: View {
  let slot: AdversaryState
  let compendium: Compendium

  private var displayName: String {
    let adversary = compendium.adversary(id: slot.adversaryID)
    return slot.customName ?? adversary?.name ?? "Unknown (\(slot.adversaryID))"
  }

  private var sortedConditions: [Condition] {
    slot.conditions.sorted { $0.displayName < $1.displayName }
  }

  var body: some View {
    let adversary = compendium.adversary(id: slot.adversaryID)

    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 6) {
        Text(displayName)
          .font(.body)
          .fontWeight(.medium)
          .lineLimit(1)
          .truncationMode(.tail)

        if let adversary {
          Text("\(adversary.role.rawValue) · T\(adversary.tier)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.secondary.opacity(0.15))
            .clipShape(.capsule)
        }

        if !sortedConditions.isEmpty {
          HStack(spacing: 3) {
            ForEach(sortedConditions, id: \.self) { condition in
              Image(systemName: condition.sfSymbol)
                .font(.system(size: 8))
                .foregroundStyle(.orange)
            }
          }
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(
            "Conditions: " + sortedConditions.map(\.displayName).joined(separator: ", ")
          )
        }

        Spacer()

        PipTrack(
          current: slot.currentStress,
          maximum: slot.maxStress,
          filledSymbol: "bolt.fill",
          emptySymbol: "bolt",
          tint: .primary
        )
      }

      PipTrack(
        current: slot.currentHP,
        maximum: slot.maxHP,
        filledSymbol: "heart.fill",
        emptySymbol: "heart"
      )
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  let compendium = Compendium()
  compendium.addAdversary(
    Adversary(
      id: "goblin", name: "Goblin", tier: 1, role: .minion,
      flavorText: "Small and cunning.", difficulty: 10,
      thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
      attackModifier: "+2", attackName: "Rusty Blade",
      attackRange: .veryClose, damage: "1d4 phy"
    ))
  return List {
    AdversaryRunnerRow(
      slot: AdversaryState(adversaryID: "goblin", maxHP: 3, maxStress: 2, currentHP: 2),
      compendium: compendium
    )
    AdversaryRunnerRow(
      slot: AdversaryState(
        adversaryID: "goblin", maxHP: 3, maxStress: 2, currentHP: 0, isDefeated: true),
      compendium: compendium
    )
    .opacity(0.4)
  }
}
