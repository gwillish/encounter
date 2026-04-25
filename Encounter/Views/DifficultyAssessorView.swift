//
//  DifficultyAssessorView.swift
//  Encounter
//
//  Always-visible difficulty budget panel pinned via .safeAreaInset(edge: .bottom).
//
//  Auto-detected adjustments (multipleSolos, noBigThreats) are shown
//  as read-only labels. GM-discretionary adjustments are Toggle rows.
//

import DHKit
import DHModels
import SwiftUI

struct DifficultyAssessorView: View {
  let rating: DifficultyBudget.Rating?
  let autoAdjustments: Set<DifficultyBudget.Adjustment>
  @Binding var manualAdjustments: Set<DifficultyBudget.Adjustment>

  // Only these four adjustments can be toggled manually.
  // multipleSolos and noBigThreats are auto-detected from the roster.
  private static let manualCases: [DifficultyBudget.Adjustment] = [
    .easierFight, .harderFight, .boostedDamage, .lowerTierAdversary,
  ]

  private var difficultyColor: Color {
    switch rating?.category {
    case .tooEasy: return .teal
    case .wellMatched, .onBudget: return .green
    case .challenging: return .orange
    case .dangerous, .likelyTPK: return .red
    case nil: return .secondary
    }
  }

  private var isPulsing: Bool { rating?.category == .likelyTPK }

  private func toggleBinding(for adj: DifficultyBudget.Adjustment) -> Binding<Bool> {
    Binding(
      get: { manualAdjustments.contains(adj) },
      set: { on in
        if on { manualAdjustments.insert(adj) } else { manualAdjustments.remove(adj) }
      }
    )
  }

  @State private var animating = false

  var body: some View {
    VStack(spacing: 0) {
      Divider()
      VStack(alignment: .leading, spacing: 8) {
        // BP summary row
        HStack {
          Text(rating?.displayName ?? "No players configured")
            .font(.headline)
            .foregroundStyle(difficultyColor)
            .opacity(animating ? 0.35 : 1.0)
            .animation(
              animating
                ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                : .easeInOut(duration: 0.3),
              value: animating
            )
          Spacer()
          if let rating {
            Text("\(rating.cost) / \(rating.budget) BP")
              .font(.subheadline)
              .monospacedDigit()
              .foregroundStyle(.secondary)
          }
        }

        // Auto-detected adjustments (informational, non-interactive)
        if !autoAdjustments.isEmpty {
          VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(autoAdjustments), id: \.self) { adj in
              Label(adj.displayName, systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }

        // Manual GM-discretionary toggles
        VStack(alignment: .leading, spacing: 4) {
          ForEach(Self.manualCases, id: \.self) { adj in
            let isOn = manualAdjustments.contains(adj)
            HStack(spacing: 6) {
              Image(systemName: isOn ? "checkmark.square.fill" : "square")
                .font(.caption)
                .foregroundStyle(isOn ? difficultyColor : .secondary)
              Text(adj.displayName)
                .font(.caption)
            }
            .contentShape(Rectangle())
            .onTapGesture {
              if isOn { manualAdjustments.remove(adj) } else { manualAdjustments.insert(adj) }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(adj.displayName)
            .accessibilityValue(isOn ? "on" : "off")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("builder.difficulty.toggle.\(String(describing: adj))")
          }
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 8)
      .background(.regularMaterial)
    }
    .onAppear { animating = isPulsing }
    .onChange(of: isPulsing) { _, nowPulsing in
      animating = nowPulsing
    }
  }
}

#Preview("On Budget — 4 players, 14 BP spent") {
  @Previewable @State var manual: Set<DifficultyBudget.Adjustment> = []
  let rating = DifficultyBudget.Rating(budget: 14, cost: 14, remaining: 0)
  DifficultyAssessorView(rating: rating, autoAdjustments: [], manualAdjustments: $manual)
    .padding()
}

#Preview("Dangerous — over budget") {
  @Previewable @State var manual: Set<DifficultyBudget.Adjustment> = []
  let rating = DifficultyBudget.Rating(budget: 14, cost: 19, remaining: -5)
  DifficultyAssessorView(
    rating: rating,
    autoAdjustments: [.multipleSolos],
    manualAdjustments: $manual
  )
  .padding()
}

#Preview("No players configured") {
  @Previewable @State var manual: Set<DifficultyBudget.Adjustment> = []
  DifficultyAssessorView(rating: nil, autoAdjustments: [], manualAdjustments: $manual)
    .padding()
}
