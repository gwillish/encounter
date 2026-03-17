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

import SwiftUI

struct AdversaryRunnerCard: View {
    let slot: AdversarySlot
    let session: EncounterSession
    let compendium: Compendium
    let onCollapse: () -> Void

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
                Text(displayName)
                    .font(.headline)
                Spacer()
                Button("Collapse", systemImage: "chevron.up", action: onCollapse)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
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
                thresholdButton("Minor",  subtitle: "< \(major)",  marks: 1)
                thresholdButton("Major",  subtitle: "≥ \(major)",  marks: 2)
                thresholdButton("Severe", subtitle: "≥ \(severe)", marks: 3)
            }

            // Stress
            Button("+1 Stress (\(slot.currentStress)/\(slot.maxStress))") {
                session.applyStress(1, to: slot.id)
            }
            .buttonStyle(.bordered)
            .disabled(slot.currentStress >= slot.maxStress || slot.isDefeated)

            // Condition toggles
            conditionsSection

            // Stat reference
            if let adversary {
                statReferenceSection(adversary)
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func thresholdButton(_ label: String, subtitle: String, marks: Int) -> some View {
        Button {
            session.applyDamage(marks, to: slot.id)
        } label: {
            VStack(spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(slot.isDefeated)
    }

    @ViewBuilder
    private var conditionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Conditions")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(Condition.standardConditions, id: \.displayName) { condition in
                    let active = slot.conditions.contains(condition)
                    Button(condition.displayName) {
                        if active {
                            session.removeCondition(condition, from: slot.id)
                        } else {
                            session.applyCondition(condition, to: slot.id)
                        }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .tint(active ? .orange : nil)
                }
            }
        }
    }

    @ViewBuilder
    private func statReferenceSection(_ adversary: Adversary) -> some View {
        Divider()
        VStack(alignment: .leading, spacing: 4) {
            LabeledContent("Difficulty", value: "\(adversary.difficulty)")
                .font(.caption)
            LabeledContent("Thresholds") {
                Text("\(adversary.thresholdMajor) / \(adversary.thresholdSevere)")
            }
            .font(.caption)
            LabeledContent("Attack") {
                Text("\(adversary.attackName) \(adversary.attackModifier) · \(adversary.attackRange.rawValue)")
            }
            .font(.caption)
            LabeledContent("Damage", value: adversary.damage)
                .font(.caption)
        }
        if !adversary.features.isEmpty {
            Divider()
            ForEach(adversary.features) { feature in
                AdversaryFeatureRow(feature: feature)
            }
        }
    }
}

#Preview {
    let compendium = Compendium()
    compendium.addAdversary(Adversary(
        id: "goblin", name: "Goblin", tier: 1, type: .minion,
        description: "Small and cunning.", difficulty: 10,
        thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
        attackModifier: "+2", attackName: "Rusty Blade",
        attackRange: .veryClose, damage: "1d4 phy",
        features: [AdversaryFeature(name: "Sneak", text: "Can hide as a free action.", featType: .passive)]
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
