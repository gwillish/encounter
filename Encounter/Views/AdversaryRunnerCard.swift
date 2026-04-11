//
//  AdversaryRunnerCard.swift
//  Encounter
//
//  Expanded inline adversary card in the live encounter runner.
//  Shows threshold damage buttons, stress control, condition toggles,
//  and a compact stat reference.
//
//  Damage marks per Daggerheart SRD:
//    Minor hit (below Major threshold): mark 1 HP
//    Major hit (at/above Major threshold): mark 2 HP
//    Severe hit (at/above Severe threshold): mark 3 HP
//

import DHKit
import DHModels
import SwiftUI

struct AdversaryRunnerCard: View {
  let slot: AdversaryState
  let session: EncounterSession
  let compendium: Compendium
  let onCollapse: () -> Void

  @State private var isEditingName = false
  @State private var pendingName = ""
  @State private var nameError: String? = nil

  private var displayName: String {
    let adversary = compendium.adversary(id: slot.adversaryID)
    return slot.customName ?? adversary?.name ?? "Unknown (\(slot.adversaryID))"
  }

  var body: some View {
    let adversary = compendium.adversary(id: slot.adversaryID)
    let major = adversary.map { "\($0.thresholdMajor)" } ?? "—"
    let severe = adversary.map { "\($0.thresholdSevere)" } ?? "—"

    VStack(alignment: .leading, spacing: 12) {

      // Header
      HStack {
        if isEditingName {
          TextField("Name", text: $pendingName)
            .font(.headline)
            .onSubmit { commitRename() }
            .accessibilityIdentifier("runner.adversary-card.name-field")
          Button("Done") { commitRename() }
            .buttonStyle(.borderless)
          Button("Cancel") { cancelRename() }
            .buttonStyle(.borderless)
        } else {
          Button(action: beginRename) {
            Text(displayName)
              .font(.headline)
              .foregroundStyle(.primary)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("runner.adversary-card.name")
          .accessibilityHint("Tap to rename")
          Spacer()
          Button("Collapse", systemImage: "chevron.up", action: onCollapse)
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .accessibilityIdentifier("runner.adversary-card.collapse-button")
        }
      }
      if isEditingName, let error = nameError {
        Text(error)
          .font(.caption)
          .foregroundStyle(.red)
          .accessibilityIdentifier("runner.adversary-card.name-error")
      }

      // HP pip track
      HStack(spacing: 4) {
        Text("HP")
          .font(.caption)
          .foregroundStyle(.secondary)
        PipTrack(current: slot.currentHP, maximum: slot.maxHP)
        if slot.isDefeated {
          Text("Defeated")
            .font(.caption)
            .foregroundStyle(.red)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.red.opacity(0.12))
            .clipShape(.capsule)
        }
      }

      // Damage threshold buttons
      HStack(spacing: 8) {
        ThresholdButton(
          label: "Minor", subtitle: "< \(major)", marks: 1, isDefeated: slot.isDefeated,
          session: session, slot: slot)
        ThresholdButton(
          label: "Major", subtitle: "≥ \(major)", marks: 2, isDefeated: slot.isDefeated,
          session: session, slot: slot)
        ThresholdButton(
          label: "Severe", subtitle: "≥ \(severe)", marks: 3, isDefeated: slot.isDefeated,
          session: session, slot: slot)
      }

      // Stress
      Button("+1 Stress (\(slot.currentStress)/\(slot.maxStress))") {
        session.applyStress(1, to: slot.id)
      }
      .buttonStyle(.bordered)
      .disabled(slot.currentStress >= slot.maxStress || slot.isDefeated)
      .accessibilityIdentifier("runner.adversary-card.stress-button")

      // Condition toggles
      AdversaryConditionsSection(slot: slot, session: session)

      // Stat reference
      if let adversary {
        AdversaryStatReference(adversary: adversary)
      }
    }
    .padding(.vertical, 8)
  }

  private func beginRename() {
    pendingName = displayName
    nameError = nil
    isEditingName = true
  }

  private func commitRename() {
    let trimmed = pendingName.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else {
      cancelRename()
      return
    }
    if session.renameAdversary(id: slot.id, name: trimmed) {
      isEditingName = false
      nameError = nil
    } else {
      nameError = "Name already in use"
    }
  }

  private func cancelRename() {
    isEditingName = false
    nameError = nil
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
      attackRange: .veryClose, damage: "1d4 phy",
      features: [
        EncounterFeature(name: "Sneak", text: "Can hide as a free action.", kind: .passive)
      ]
    ))
  let session = EncounterSession(name: "Test")
  if let goblin = compendium.adversary(id: "goblin") {
    session.add(adversary: goblin)
  }
  return List {
    if let slot = session.adversarySlots.first {
      AdversaryRunnerCard(
        slot: slot,
        session: session,
        compendium: compendium,
        onCollapse: {}
      )
    }
  }
  .environment(compendium)
}
