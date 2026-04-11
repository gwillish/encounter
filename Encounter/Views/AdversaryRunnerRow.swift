//
//  AdversaryRunnerRow.swift
//  Encounter
//
//  Collapsed adversary row shown in the live encounter runner.
//  Displays name, type/tier badge, HP pip track, and stress pip track.
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

  var body: some View {
    let adversary = compendium.adversary(id: slot.adversaryID)

    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 6) {
        Text(displayName)
          .font(.body)
          .fontWeight(.medium)
        Spacer()
        if let adversary {
          Text("\(adversary.role.rawValue) · T\(adversary.tier)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.secondary.opacity(0.15))
            .clipShape(.capsule)
        }
      }
      HStack(spacing: 16) {
        HStack(spacing: 4) {
          Text("HP")
            .font(.caption)
            .foregroundStyle(.secondary)
          PipTrack(current: slot.currentHP, maximum: slot.maxHP)
        }
        HStack(spacing: 4) {
          Text("St")
            .font(.caption)
            .foregroundStyle(.secondary)
          PipTrack(current: slot.currentStress, maximum: slot.maxStress)
        }
      }
      if !slot.conditions.isEmpty {
        HStack(spacing: 6) {
          ForEach(
            slot.conditions.sorted { $0.displayName < $1.displayName }, id: \.self
          ) { condition in
            Text(condition.displayName)
              .font(.caption)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(.orange.opacity(0.15))
              .foregroundStyle(.orange)
              .clipShape(.capsule)
          }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
          "Conditions: "
            + slot.conditions.map(\.displayName).sorted().joined(separator: ", ")
        )
      }
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
