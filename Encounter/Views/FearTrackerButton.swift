//
//  FearTrackerButton.swift
//  Encounter
//
//  Toolbar button showing the current Fear pool (flame icon + count).
//  Tapping opens a compact popover with +1 / −1 / −2 / −3 controls.
//

import SwiftUI

struct FearTrackerButton: View {
    let session: EncounterSession
    @State private var showPopover = false

    var body: some View {
        Button {
            showPopover.toggle()
        } label: {
            Label("\(session.fearPool)", systemImage: "flame.fill")
                .monospacedDigit()
        }
        .tint(.orange)
        .popover(isPresented: $showPopover) {
            VStack(spacing: 12) {
                Text("Fear")
                    .font(.headline)
                Text("\(session.fearPool)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(.orange)
                HStack(spacing: 8) {
                    Button("+1") { session.incrementFear(by: 1) }
                        .buttonStyle(.bordered)
                    Button("−1") { session.spendFear(1) }
                        .buttonStyle(.bordered)
                        .disabled(session.fearPool < 1)
                    Button("−2") { session.spendFear(2) }
                        .buttonStyle(.bordered)
                        .disabled(session.fearPool < 2)
                    Button("−3") { session.spendFear(3) }
                        .buttonStyle(.bordered)
                        .disabled(session.fearPool < 3)
                }
            }
            .padding()
            .frame(minWidth: 180)
            .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview {
    let compendium = Compendium()
    let session = EncounterSession(name: "Test", fearPool: 3)
    return NavigationStack {
        Text("Runner")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    FearTrackerButton(session: session)
                }
            }
    }
    .environment(compendium)
}
