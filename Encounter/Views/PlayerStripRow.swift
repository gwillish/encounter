//
//  PlayerStripRow.swift
//  Encounter
//
//  Compact player row inside the always-visible PlayerStrip.
//  Shows name, HP pip track, stress pip track, and armor slot count.
//  Tapping opens PlayerEditPopover for HP/Stress/Armor stepper controls.
//

import SwiftUI

struct PlayerStripRow: View {
    let player: PlayerSlot
    let session: EncounterSession
    @State private var showPopover = false

    var body: some View {
        Button {
            showPopover = true
        } label: {
            HStack(spacing: 8) {
                Text(player.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(minWidth: 60, alignment: .leading)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                HStack(spacing: 4) {
                    Text("HP")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    PipTrack(current: player.currentHP, maximum: player.maxHP)
                }

                HStack(spacing: 4) {
                    Text("St")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    PipTrack(current: player.currentStress, maximum: player.maxStress)
                }

                if player.armorSlots > 0 {
                    HStack(spacing: 4) {
                        Text("Arm")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(player.currentArmorSlots)/\(player.armorSlots)")
                            .font(.caption)
                            .monospacedDigit()
                    }
                }
            }
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPopover) {
            PlayerEditPopover(player: player, session: session)
                .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview {
    let session = EncounterSession(
        name: "Test",
        playerSlots: [
            PlayerSlot(name: "Aric Stonehammer",
                       maxHP: 6, maxStress: 6, evasion: 12,
                       thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3),
            PlayerSlot(name: "Lira Dawnwhisper",
                       maxHP: 5, currentHP: 3, maxStress: 7, currentStress: 2,
                       evasion: 14, thresholdMajor: 4, thresholdSevere: 8, armorSlots: 2),
        ]
    )
    List {
        ForEach(session.playerSlots) { player in
            PlayerStripRow(player: player, session: session)
        }
    }
}
