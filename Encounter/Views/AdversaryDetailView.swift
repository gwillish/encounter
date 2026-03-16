//
//  AdversaryDetailView.swift
//  Encounter
//
//  Full stat card for a single adversary.
//  When onSelect is provided (e.g. called from EncounterBuilderView),
//  an "Add to Encounter" toolbar button is shown.
//

import SwiftUI

struct AdversaryDetailView: View {
    let adversary: Adversary
    let onSelect: ((Adversary) -> Void)?

    @Environment(\.dismiss) private var dismiss

    init(adversary: Adversary, onSelect: ((Adversary) -> Void)? = nil) {
        self.adversary = adversary
        self.onSelect = onSelect
    }

    var body: some View {
        List {
            // Identity
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        typeBadge
                        Text("Tier \(adversary.tier)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if adversary.source != "SRD" {
                            Text(adversary.source)
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(.blue)
                                .clipShape(.capsule)
                        }
                    }
                    Text(adversary.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // Combat Stats
            Section("Combat Stats") {
                LabeledContent("Difficulty", value: adversary.difficulty, format: .number)
                LabeledContent("Hit Points", value: adversary.hp, format: .number)
                LabeledContent("Stress", value: adversary.stress, format: .number)
                LabeledContent("Major Threshold", value: adversary.thresholdMajor, format: .number)
                LabeledContent("Severe Threshold", value: adversary.thresholdSevere, format: .number)
            }

            // Standard Attack
            Section("Standard Attack") {
                LabeledContent("Attack") {
                    Text("\(adversary.attackName) \(adversary.attackModifier)")
                }
                LabeledContent("Range", value: adversary.attackRange.rawValue)
                LabeledContent("Damage", value: adversary.damage)
            }

            // Experience
            if let experience = adversary.experience {
                Section("Experience") {
                    Text(experience)
                        .font(.subheadline)
                }
            }

            // Features grouped: passives → actions → reactions
            featureSections(adversary.features)

            // Motives & Tactics
            if let motives = adversary.motivesAndTactics {
                Section("Motives & Tactics") {
                    Text(motives)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle(adversary.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            if let onSelect {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add to Encounter") {
                        onSelect(adversary)
                        dismiss()
                    }
                }
            }
        }
    }

    private var typeBadge: some View {
        Text(adversary.type.rawValue)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.secondary.opacity(0.15))
            .clipShape(.capsule)
    }

    @ViewBuilder
    private func featureSections(_ features: [AdversaryFeature]) -> some View {
        let passives  = features.filter { $0.featType == .passive }
        let actions   = features.filter { $0.featType == .action }
        let reactions = features.filter { $0.featType == .reaction }

        if !passives.isEmpty {
            Section("Passives") {
                ForEach(passives) { AdversaryFeatureRow(feature: $0) }
            }
        }
        if !actions.isEmpty {
            Section("Actions") {
                ForEach(actions) { AdversaryFeatureRow(feature: $0) }
            }
        }
        if !reactions.isEmpty {
            Section("Reactions") {
                ForEach(reactions) { AdversaryFeatureRow(feature: $0) }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AdversaryDetailView(adversary: Adversary(
            id: "goblin",
            name: "Goblin",
            tier: 1,
            type: .minion,
            description: "Small, cunning, and cowardly alone but dangerous in numbers.",
            motivesAndTactics: "Goblins mob weak targets and flee from strong ones.",
            difficulty: 10,
            thresholdMajor: 5,
            thresholdSevere: 10,
            hp: 3,
            stress: 2,
            attackModifier: "+2",
            attackName: "Rusty Blade",
            attackRange: .veryClose,
            damage: "1d4 phy",
            features: [
                AdversaryFeature(name: "Pack Tactics", text: "Deal +1 damage for each ally adjacent to the target.", featType: .passive),
                AdversaryFeature(name: "Sneak Attack", text: "Once per round, deal +1d6 damage when hidden.", featType: .action),
            ]
        ))
    }
}
