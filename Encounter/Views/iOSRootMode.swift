//
//  iOSRootMode.swift
//  Encounter
//

#if !os(macOS)

  /// Top-level mode for the iOS root navigation screen.
  ///
  /// Controlled by the centered segmented picker in `EncounterAndPartyRootView`.
  enum iOSRootMode: String, CaseIterable {
    case encounters = "Encounters"
    case compendium = "Compendium"
  }

#endif
