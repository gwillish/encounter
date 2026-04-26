#if DEBUG
  //
  //  PipTrackExplorationView.swift
  //  Encounter
  //
  //  Interactive exploration of PipTrack symbol variants and the HP color gradient.
  //  Sliders let you scrub HP, stress, and armor live to verify how filled/empty
  //  symbols and gradient thresholds look at every value.
  //

  import SwiftUI

  struct PipTrackExplorationView: View {
    // HP — interactive, shows crimson → orange → red gradient
    @State private var currentHP: Double = 10
    @State private var maxHP: Double = 10

    // Stress — interactive, neutral tint
    @State private var currentStress: Double = 0
    @State private var maxStress: Double = 6

    // Armor — interactive, secondary tint
    @State private var currentArmor: Double = 3
    @State private var maxArmor: Double = 3

    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: 32) {
          interactiveSection
          Divider()
          gradientGallery
          Divider()
          textFallbackSection
        }
        .padding()
      }
    }

    // MARK: - Interactive sliders

    private var interactiveSection: some View {
      VStack(alignment: .leading, spacing: 20) {
        sectionHeader(
          "Interactive",
          subtitle: "Scrub current values to explore symbol states and gradient thresholds"
        )

        pipControl(
          label: "HP",
          symbol: "heart.fill",
          track: PipTrack(
            current: Int(currentHP),
            maximum: Int(maxHP),
            filledSymbol: "heart.fill",
            emptySymbol: "heart"
          ),
          current: $currentHP,
          maximum: $maxHP,
          maxRange: 1...15
        )

        pipControl(
          label: "Stress",
          symbol: "bolt.fill",
          track: PipTrack(
            current: Int(currentStress),
            maximum: Int(maxStress),
            filledSymbol: "bolt.fill",
            emptySymbol: "bolt",
            tint: .primary
          ),
          current: $currentStress,
          maximum: $maxStress,
          maxRange: 1...12
        )

        pipControl(
          label: "Armor",
          symbol: "shield.fill",
          track: PipTrack(
            current: Int(currentArmor),
            maximum: Int(maxArmor),
            filledSymbol: "shield.fill",
            emptySymbol: "shield",
            tint: .secondary
          ),
          current: $currentArmor,
          maximum: $maxArmor,
          maxRange: 1...6
        )
      }
    }

    private func pipControl<T: View>(
      label: String,
      symbol: String,
      track: T,
      current: Binding<Double>,
      maximum: Binding<Double>,
      maxRange: ClosedRange<Double>
    ) -> some View {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 8) {
          Image(systemName: symbol)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(width: 16)
          Text(label)
            .font(.subheadline)
            .fontWeight(.medium)
          track
        }
        sliderRow(
          label: "Current",
          value: current,
          in: 0...max(maximum.wrappedValue, 1),
          format: "\(Int(current.wrappedValue)) / \(Int(maximum.wrappedValue))"
        )
        sliderRow(
          label: "Maximum",
          value: maximum,
          in: maxRange,
          format: "\(Int(maximum.wrappedValue))"
        )
        .onChange(of: maximum.wrappedValue) { _, newMax in
          if current.wrappedValue > newMax { current.wrappedValue = newMax }
        }
      }
      .padding(10)
      .background(.secondary.opacity(0.08))
      .clipShape(.rect(cornerRadius: 8))
    }

    private func sliderRow(
      label: String,
      value: Binding<Double>,
      in range: ClosedRange<Double>,
      format: String
    ) -> some View {
      HStack(spacing: 8) {
        Text(label)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .frame(width: 50, alignment: .leading)
        Slider(value: value, in: range, step: 1)
        Text(format)
          .font(.caption2)
          .monospacedDigit()
          .foregroundStyle(.secondary)
          .frame(width: 40, alignment: .trailing)
      }
    }

    // MARK: - HP gradient gallery

    private var gradientGallery: some View {
      VStack(alignment: .leading, spacing: 12) {
        sectionHeader(
          "HP Gradient — fixed gallery",
          subtitle: "Crimson above 66% · Orange 33–66% · Red below 33% · Thresholds at 4/6, 2/6, 0/6"
        )
        VStack(alignment: .leading, spacing: 8) {
          ForEach(
            [(6, "6/6 — full", "Healthy"),
             (5, "5/6 — 83%", ""),
             (4, "4/6 — 67%", "Threshold ↓ orange"),
             (3, "3/6 — 50%", ""),
             (2, "2/6 — 33%", "Threshold ↓ red"),
             (1, "1/6 — 17%", ""),
             (0, "0/6 — empty", "")],
            id: \.0
          ) { hp, label, note in
            HStack(spacing: 12) {
              PipTrack(
                current: hp,
                maximum: 6,
                filledSymbol: "heart.fill",
                emptySymbol: "heart"
              )
              .frame(minWidth: 80, alignment: .leading)
              Text(label)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
              if !note.isEmpty {
                Text(note)
                  .font(.caption2)
                  .foregroundStyle(.tertiary)
              }
            }
          }
        }
      }
    }

    // MARK: - Text fallback (max > 12)

    private var textFallbackSection: some View {
      VStack(alignment: .leading, spacing: 12) {
        sectionHeader(
          "Text fallback (maximum > 12)",
          subtitle: "Pip track collapses to icon + N/M when rendering would overflow"
        )
        VStack(alignment: .leading, spacing: 8) {
          ForEach(
            [(14, 7, "HP — ~50%"),
             (14, 14, "HP — full"),
             (14, 0, "HP — empty"),
             (15, 10, "Stress — neutral"),
             (14, 5, "Armor — secondary")],
            id: \.2
          ) { max, current, label in
            HStack(spacing: 12) {
              Group {
                switch label {
                case let l where l.starts(with: "Stress"):
                  PipTrack(
                    current: current,
                    maximum: max,
                    filledSymbol: "bolt.fill",
                    emptySymbol: "bolt",
                    tint: .primary
                  )
                case let l where l.starts(with: "Armor"):
                  PipTrack(
                    current: current,
                    maximum: max,
                    filledSymbol: "shield.fill",
                    emptySymbol: "shield",
                    tint: .secondary
                  )
                default:
                  PipTrack(
                    current: current,
                    maximum: max,
                    filledSymbol: "heart.fill",
                    emptySymbol: "heart"
                  )
                }
              }
              .frame(minWidth: 60, alignment: .leading)
              Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
      VStack(alignment: .leading, spacing: 2) {
        Text(title).font(.headline)
        Text(subtitle).font(.caption).foregroundStyle(.secondary)
      }
    }
  }

  #Preview {
    NavigationStack {
      PipTrackExplorationView()
        .navigationTitle("Pip Track")
    }
  }
#endif
