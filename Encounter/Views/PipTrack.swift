//
//  PipTrack.swift
//  Encounter
//
//  Compact pip-dot visualizer for HP and Stress values.
//  Renders filled/empty circle symbols up to a threshold of 10;
//  falls back to "N/M" text for larger values.
//
//  Color gradient (HP): neutral → orange → red as current decreases.
//  Stress uses neutral color (filling stress is not inherently dangerous).
//

import SwiftUI

struct PipTrack: View {
    let current: Int
    let maximum: Int

    private let pipThreshold = 10

    var body: some View {
        if maximum > pipThreshold {
            Text("\(current)/\(maximum)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(current == 0 ? .red : .primary)
        } else {
            HStack(spacing: 3) {
                ForEach(0 ..< max(maximum, 0), id: \.self) { i in
                    Image(systemName: i < current ? "circle.fill" : "circle")
                        .font(.system(size: 8))
                        .foregroundStyle(i < current ? pipColor : .secondary.opacity(0.4))
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel(Text("\(current) of \(maximum)"))
            .accessibilityHidden(maximum == 0)
        }
    }

    private var pipColor: Color {
        guard maximum > 0 else { return .primary }
        let ratio = Double(current) / Double(maximum)
        if ratio > 0.66 { return .primary }
        if ratio > 0.33 { return .orange }
        return .red
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        PipTrack(current: 5, maximum: 5)
        PipTrack(current: 3, maximum: 5)
        PipTrack(current: 1, maximum: 5)
        PipTrack(current: 0, maximum: 5)
        PipTrack(current: 8, maximum: 12)   // text fallback
    }
    .padding()
}
