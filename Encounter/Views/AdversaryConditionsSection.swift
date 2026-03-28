//
//  AdversaryConditionsSection.swift
//  Encounter
//
//  Condition toggle strip for an adversary slot in the live encounter runner.
//

import DHKit
import DHModels
import SwiftUI

/// Displays toggleable condition buttons for an adversary slot.
///
/// Active conditions are highlighted in orange. Tapping a condition applies
/// or removes it from the slot via the session.
struct AdversaryConditionsSection: View {
  let slot: AdversarySlot
  let session: EncounterSession

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Conditions")
        .font(.caption)
        .foregroundStyle(.secondary)
      HStack(spacing: 6) {
        ForEach(Condition.standardConditions, id: \.self) { condition in
          let active = slot.conditions.contains(condition)
          Button(condition.displayName) {
            if active {
              session.removeCondition(condition, from: slot)
            } else {
              session.applyCondition(condition, to: slot)
            }
          }
          .font(.caption)
          .buttonStyle(.bordered)
          .tint(active ? .orange : nil)
          .accessibilityIdentifier(
            "runner.adversary-card.condition.\(condition.displayName.lowercased())"
          )
        }
      }
    }
  }
}
