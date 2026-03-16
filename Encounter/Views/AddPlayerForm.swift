//
//  AddPlayerForm.swift
//  Encounter
//
//  Sheet presenting a full PlayerConfig entry form.
//  All 7 fields are required; the Add button stays disabled until
//  all fields pass validation.
//

import SwiftUI

struct AddPlayerForm: View {
    let onAdd: (PlayerConfig) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var maxHP = ""
    @State private var maxStress = ""
    @State private var evasion = ""
    @State private var thresholdMajor = ""
    @State private var thresholdSevere = ""
    @State private var armorSlots = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(maxHP).map { $0 > 0 } ?? false &&
        Int(maxStress).map { $0 > 0 } ?? false &&
        Int(evasion).map { $0 > 0 } ?? false &&
        Int(thresholdMajor).map { $0 > 0 } ?? false &&
        Int(thresholdSevere).map { $0 > 0 } ?? false &&
        Int(armorSlots).map { $0 >= 0 } ?? false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Character") {
                    TextField("Name", text: $name)
                }
                Section("Stats") {
                    TextField("Max HP", text: $maxHP)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    TextField("Max Stress", text: $maxStress)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    TextField("Evasion", text: $evasion)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                Section("Damage Thresholds") {
                    TextField("Major Threshold", text: $thresholdMajor)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    TextField("Severe Threshold", text: $thresholdSevere)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                Section("Armor") {
                    TextField("Armor Slots", text: $armorSlots)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
            }
            .navigationTitle("Add Player")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { commitAdd() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func commitAdd() {
        guard isValid,
              let hp    = Int(maxHP),
              let str   = Int(maxStress),
              let ev    = Int(evasion),
              let tmaj  = Int(thresholdMajor),
              let tsev  = Int(thresholdSevere),
              let armor = Int(armorSlots)
        else { return }
        onAdd(PlayerConfig(
            name: name.trimmingCharacters(in: .whitespaces),
            maxHP: hp, maxStress: str, evasion: ev,
            thresholdMajor: tmaj, thresholdSevere: tsev,
            armorSlots: armor
        ))
        dismiss()
    }
}

#Preview {
    AddPlayerForm { config in
        print("Added: \(config.name)")
    }
}
