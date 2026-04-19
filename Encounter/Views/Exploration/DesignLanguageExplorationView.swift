#if DEBUG
//
//  DesignLanguageExplorationView.swift
//  Encounter
//
//  Renders all four icon/color proposals from ADR-0039 side-by-side so the
//  team can screenshot, compare, and confirm or revise the chosen set.
//
//  Proposal 1 "The Duality" is the adopted standard; the others are shown
//  for comparison. See docs/decisions/0039-icon-color-design-language.md.
//

import SwiftUI

// MARK: - Data model

private struct SymbolSpec {
  let symbol: String
  let color: Color
}

private struct IconProposal: Identifiable {
  let id: Int
  let name: String
  let tagline: String
  let hp: SymbolSpec
  let armor: SymbolSpec
  let stress: SymbolSpec
  let fear: SymbolSpec
  let hope: SymbolSpec
  let isAdopted: Bool
}

// MARK: - Proposals

private let proposals: [IconProposal] = [
  IconProposal(
    id: 1,
    name: "1 — The Duality",
    tagline: "Adopted · Direct expression of hope/fear resource economy",
    hp: SymbolSpec(symbol: "heart.fill", color: Color(red: 0.75, green: 0.22, blue: 0.17)),
    armor: SymbolSpec(symbol: "shield.fill", color: .secondary),
    stress: SymbolSpec(symbol: "bolt.fill", color: Color(red: 0.90, green: 0.49, blue: 0.13)),
    fear: SymbolSpec(symbol: "flame.fill", color: .orange),
    hope: SymbolSpec(symbol: "bolt.heart.fill", color: Color(red: 0.94, green: 0.75, blue: 0.25)),
    isAdopted: true
  ),
  IconProposal(
    id: 2,
    name: "2 — Blade & Spirit",
    tagline: "System colors · Classic RPG vocabulary",
    hp: SymbolSpec(symbol: "heart.fill", color: .red),
    armor: SymbolSpec(symbol: "shield.fill", color: .blue),
    stress: SymbolSpec(symbol: "waveform.path.ecg", color: .purple),
    fear: SymbolSpec(symbol: "flame.fill", color: .orange),
    hope: SymbolSpec(symbol: "star.fill", color: .yellow),
    isAdopted: false
  ),
  IconProposal(
    id: 3,
    name: "3 — Beacon & Storm",
    tagline: "Atmospheric · Palette rendering · Hopepunk contrast",
    hp: SymbolSpec(symbol: "heart.fill", color: Color(red: 0.91, green: 0.31, blue: 0.42)),
    armor: SymbolSpec(
      symbol: "shield.lefthalf.filled",
      color: Color(red: 0.63, green: 0.48, blue: 0.31)),
    stress: SymbolSpec(symbol: "waveform", color: Color(red: 0.87, green: 0.63, blue: 0.18)),
    fear: SymbolSpec(
      symbol: "cloud.bolt.fill", color: Color(red: 0.35, green: 0.40, blue: 0.45)),
    hope: SymbolSpec(symbol: "rays", color: Color(red: 0.94, green: 0.75, blue: 0.25)),
    isAdopted: false
  ),
  IconProposal(
    id: 4,
    name: "4 — Signal Board",
    tagline: "Two-color system · Maximum runner legibility",
    hp: SymbolSpec(symbol: "heart.fill", color: Color(red: 0.17, green: 0.69, blue: 0.63)),
    armor: SymbolSpec(symbol: "shield.fill", color: Color(red: 0.17, green: 0.69, blue: 0.63)),
    stress: SymbolSpec(symbol: "bolt.circle.fill", color: Color(red: 0.88, green: 0.56, blue: 0.13)),
    fear: SymbolSpec(symbol: "flame.fill", color: .orange),
    hope: SymbolSpec(symbol: "sparkles", color: Color(red: 0.17, green: 0.69, blue: 0.63)),
    isAdopted: false
  ),
]

// MARK: - Sample data for mock rows

private struct MockAdversary {
  let name: String
  let currentHP: Int
  let maxHP: Int
  let currentStress: Int
  let maxStress: Int
}

private struct MockPlayer {
  let name: String
  let currentHP: Int
  let maxHP: Int
  let currentStress: Int
  let maxStress: Int
  let currentArmor: Int
  let maxArmor: Int
}

private let sampleAdversary = MockAdversary(
  name: "Goblin Brute", currentHP: 6, maxHP: 10, currentStress: 2, maxStress: 5)
private let samplePlayers = [
  MockPlayer(name: "Aria", currentHP: 8, maxHP: 12, currentStress: 1, maxStress: 6, currentArmor: 2, maxArmor: 3),
  MockPlayer(name: "Theron", currentHP: 4, maxHP: 10, currentStress: 3, maxStress: 5, currentArmor: 0, maxArmor: 2),
]

// MARK: - View

struct DesignLanguageExplorationView: View {
  private let sizes: [(label: String, pt: CGFloat)] = [
    ("20pt", 20), ("28pt", 28), ("44pt", 44),
  ]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 32) {
        conditionSection
        ForEach(proposals) { proposal in
          proposalSection(proposal)
          if proposal.id < proposals.count {
            Divider()
          }
        }
      }
      .padding()
    }
  }

  // MARK: - Condition icons

  private var conditionSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionHeader("Condition Icons", subtitle: "Shared across all proposals")
      HStack(spacing: 24) {
        conditionIcon(symbol: "eye.slash.fill", label: "Hidden")
        conditionIcon(symbol: "tag.fill", label: "Restrained")
        conditionIcon(symbol: "shield.slash.fill", label: "Vulnerable")
      }
    }
  }

  private func conditionIcon(symbol: String, label: String) -> some View {
    VStack(spacing: 4) {
      HStack(spacing: 8) {
        Image(systemName: symbol)
          .font(.system(size: 20))
          .foregroundStyle(.orange)
        Image(systemName: symbol)
          .font(.system(size: 20))
          .foregroundStyle(.secondary)
      }
      Text(label)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }

  // MARK: - Proposal section

  private func proposalSection(_ proposal: IconProposal) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 8) {
          Text(proposal.name)
            .font(.headline)
          if proposal.isAdopted {
            Text("ADOPTED")
              .font(.caption2)
              .fontWeight(.semibold)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(.teal.opacity(0.2))
              .foregroundStyle(.teal)
              .clipShape(.capsule)
          }
        }
        Text(proposal.tagline)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      // Icon grid at each size
      VStack(alignment: .leading, spacing: 12) {
        ForEach(sizes, id: \.label) { size in
          iconRow(proposal: proposal, size: size)
        }
      }

      // Mock adversary runner row
      VStack(alignment: .leading, spacing: 6) {
        Text("Adversary row")
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .textCase(.uppercase)
        mockAdversaryRow(proposal: proposal, adversary: sampleAdversary)
      }

      // Mock player strip rows
      VStack(alignment: .leading, spacing: 6) {
        Text("Player strip")
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .textCase(.uppercase)
        VStack(spacing: 0) {
          ForEach(samplePlayers, id: \.name) { player in
            mockPlayerRow(proposal: proposal, player: player)
            if player.name != samplePlayers.last?.name {
              Divider()
                .padding(.leading, 8)
            }
          }
        }
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 8))
      }
    }
  }

  // MARK: - Icon row

  private func iconRow(proposal: IconProposal, size: (label: String, pt: CGFloat)) -> some View {
    HStack(spacing: 0) {
      Text(size.label)
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .frame(width: 36, alignment: .leading)
      HStack(spacing: 20) {
        iconCell(spec: proposal.hp, label: "HP", size: size.pt)
        iconCell(spec: proposal.armor, label: "Armor", size: size.pt)
        iconCell(spec: proposal.stress, label: "Stress", size: size.pt)
        iconCell(spec: proposal.fear, label: "Fear", size: size.pt)
        iconCell(spec: proposal.hope, label: "Hope", size: size.pt)
      }
    }
  }

  private func iconCell(spec: SymbolSpec, label: String, size: CGFloat) -> some View {
    VStack(spacing: 3) {
      Image(systemName: spec.symbol)
        .font(.system(size: size))
        .foregroundStyle(spec.color)
        .frame(width: size + 4, height: size + 4)
      if size == 20 {
        Text(label)
          .font(.system(size: 9))
          .foregroundStyle(.tertiary)
      }
    }
  }

  // MARK: - Mock adversary row

  private func mockAdversaryRow(proposal: IconProposal, adversary: MockAdversary) -> some View {
    HStack(spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text(adversary.name)
          .font(.subheadline)
        HStack(spacing: 6) {
          Image(systemName: proposal.hp.symbol)
            .foregroundStyle(proposal.hp.color)
          Text("\(adversary.currentHP)/\(adversary.maxHP)")
          Image(systemName: proposal.stress.symbol)
            .foregroundStyle(proposal.stress.color)
          Text("\(adversary.currentStress)/\(adversary.maxStress)")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      Spacer()
      Text("Minion · T1")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(.secondary.opacity(0.12))
        .clipShape(.capsule)
    }
    .padding(10)
    .background(.background.secondary)
    .clipShape(.rect(cornerRadius: 8))
  }

  // MARK: - Mock player strip row

  private func mockPlayerRow(proposal: IconProposal, player: MockPlayer) -> some View {
    HStack(spacing: 8) {
      Text(player.name)
        .font(.caption)
        .fontWeight(.medium)
        .lineLimit(1)
        .frame(width: 60, alignment: .leading)
      Spacer()
      HStack(spacing: 12) {
        HStack(spacing: 3) {
          Image(systemName: proposal.hp.symbol)
            .foregroundStyle(proposal.hp.color)
          Text("\(player.currentHP)/\(player.maxHP)")
        }
        HStack(spacing: 3) {
          Image(systemName: proposal.stress.symbol)
            .foregroundStyle(proposal.stress.color)
          Text("\(player.currentStress)/\(player.maxStress)")
        }
        if player.maxArmor > 0 {
          HStack(spacing: 3) {
            Image(systemName: proposal.armor.symbol)
              .foregroundStyle(proposal.armor.color)
            Text("\(player.currentArmor)/\(player.maxArmor)")
          }
        }
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
  }

  // MARK: - Helpers

  private func sectionHeader(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.headline)
      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  NavigationStack {
    DesignLanguageExplorationView()
      .navigationTitle("Icon Design Language")
  }
}
#endif
