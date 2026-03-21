//
//  DifficultyAssessorView.swift
//  Encounter
//
//  Always-visible difficulty budget panel pinned via .safeAreaInset(edge: .bottom).
//
//  Color thresholds (remaining = budget − totalCost):
//    ≥  4  teal    "Too Easy"
//    1–3   green   "Well Matched"
//    0     green   "On Budget"
//   -1–-3  amber   "Challenging"
//   -4–-6  red     "Dangerous"
//    ≤ -7  pulsing red  "Likely TPK"
//
//  Auto-detected adjustments (multipleSolos, noBigThreats) are shown
//  as read-only labels. GM-discretionary adjustments are Toggle rows.
//

import SwiftUI

struct DifficultyAssessorView: View {
    let rating: DifficultyBudget.Rating
    let autoAdjustments: Set<DifficultyBudget.Adjustment>
    @Binding var manualAdjustments: Set<DifficultyBudget.Adjustment>

    // Only these four adjustments can be toggled manually.
    // multipleSolos and noBigThreats are auto-detected from the roster.
    private static let manualCases: [DifficultyBudget.Adjustment] = [
        .easierFight, .harderFight, .boostedDamage, .lowerTierAdversary
    ]

    private var difficultyLabel: String {
        switch rating.remaining {
        case 4...:      return "Too Easy"
        case 1...3:     return "Well Matched"
        case 0:         return "On Budget"
        case -3 ... -1: return "Challenging"
        case -6 ... -4: return "Dangerous"
        default:        return "Likely TPK"
        }
    }

    private var difficultyColor: Color {
        switch rating.remaining {
        case 4...:      return .teal
        case 1...:      return .green
        case 0:         return .green
        case -3 ... -1: return .orange
        case -6 ... -4: return .red
        default:        return .red
        }
    }

    private var isPulsing: Bool { rating.remaining <= -7 }

    private func toggleBinding(for adj: DifficultyBudget.Adjustment) -> Binding<Bool> {
        Binding(
            get: { manualAdjustments.contains(adj) },
            set: { on in
                if on { manualAdjustments.insert(adj) }
                else  { manualAdjustments.remove(adj) }
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
                    Text(difficultyLabel)
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
                    Text("\(rating.totalCost) / \(rating.budget) BP")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                // Auto-detected adjustments (informational, non-interactive)
                if !autoAdjustments.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(autoAdjustments), id: \.self) { adj in
                            Label(adj.label, systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Manual GM-discretionary toggles
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Self.manualCases, id: \.self) { adj in
                        Toggle(adj.label, isOn: toggleBinding(for: adj))
                            .font(.caption)
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
    let rating = DifficultyBudget.Rating(budget: 14, totalCost: 14, remaining: 0)
    return DifficultyAssessorView(rating: rating, autoAdjustments: [], manualAdjustments: $manual)
        .padding()
}

#Preview("Dangerous — over budget") {
    @Previewable @State var manual: Set<DifficultyBudget.Adjustment> = []
    let rating = DifficultyBudget.Rating(budget: 14, totalCost: 19, remaining: -5)
    return DifficultyAssessorView(
        rating: rating,
        autoAdjustments: [.multipleSolos],
        manualAdjustments: $manual
    )
    .padding()
}
