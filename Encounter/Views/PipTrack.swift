//
//  PipTrack.swift
//  Encounter
//
//  Compact pip-symbol visualizer for HP, Stress, and Armor values.
//  Renders filled/empty symbols up to a threshold of 12;
//  falls back to "icon N/M" text for larger values.
//
//  HP (nil tint): crimson → orange → red danger gradient as current decreases.
//  Stress and Armor: fixed tint passed by caller.
//

import SwiftUI

struct PipTrack: View {
  let current: Int
  let maximum: Int
  var filledSymbol: String = "circle.fill"
  var emptySymbol: String = "circle"
  var tint: Color? = nil

  private let pipThreshold = 12

  var body: some View {
    if maximum > pipThreshold {
      HStack(spacing: 3) {
        Image(systemName: filledSymbol)
          .font(.system(size: 8))
          .foregroundStyle(pipColor)
          .accessibilityHidden(true)
        Text("\(current)/\(maximum)")
          .font(.caption)
          .monospacedDigit()
          .foregroundStyle(pipColor)
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text("\(current) of \(maximum)"))
    } else {
      HStack(spacing: 3) {
        ForEach(0..<max(maximum, 0), id: \.self) { i in
          Image(systemName: i < current ? filledSymbol : emptySymbol)
            .font(.system(size: 8))
            .foregroundStyle(i < current ? pipColor : .secondary.opacity(0.4))
            .accessibilityHidden(true)
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text("\(current) of \(maximum)"))
      .accessibilityHidden(maximum == 0)
    }
  }

  var pipColor: Color {
    if let tint { return tint }
    guard maximum > 0 else { return .primary }
    let ratio = Double(current) / Double(maximum)
    if ratio > 0.66 { return Color(red: 0.75, green: 0.22, blue: 0.17) }
    if ratio > 0.33 { return .orange }
    return .red
  }
}

#Preview("HP — gradient thresholds") {
  VStack(alignment: .leading, spacing: 6) {
    ForEach([6, 5, 4, 3, 2, 1, 0], id: \.self) { hp in
      HStack(spacing: 8) {
        Text("\(hp)/6")
          .font(.caption2)
          .monospacedDigit()
          .foregroundStyle(.tertiary)
          .frame(width: 28, alignment: .leading)
        PipTrack(current: hp, maximum: 6, filledSymbol: "heart.fill", emptySymbol: "heart")
      }
    }
  }
  .padding()
}

#Preview("All symbol variants") {
  VStack(alignment: .leading, spacing: 8) {
    HStack(spacing: 12) {
      Image(systemName: "heart.fill").font(.caption).foregroundStyle(.secondary)
      PipTrack(current: 4, maximum: 6, filledSymbol: "heart.fill", emptySymbol: "heart")
    }
    HStack(spacing: 12) {
      Image(systemName: "bolt.fill").font(.caption).foregroundStyle(.secondary)
      PipTrack(
        current: 3, maximum: 6, filledSymbol: "bolt.fill", emptySymbol: "bolt", tint: .primary)
    }
    HStack(spacing: 12) {
      Image(systemName: "shield.fill").font(.caption).foregroundStyle(.secondary)
      PipTrack(
        current: 2, maximum: 3, filledSymbol: "shield.fill", emptySymbol: "shield", tint: .secondary
      )
    }
    Divider()
    HStack(spacing: 12) {
      Image(systemName: "heart.fill").font(.caption).foregroundStyle(.secondary)
      PipTrack(current: 8, maximum: 14, filledSymbol: "heart.fill", emptySymbol: "heart")
        .frame(alignment: .leading)
      Text("text fallback").font(.caption2).foregroundStyle(.tertiary)
    }
  }
  .padding()
}
