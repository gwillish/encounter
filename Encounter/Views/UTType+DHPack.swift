//
//  UTType+DHPack.swift
//  Encounter
//
//  Shared UTType extension for .dhpack files. Declared once here so the
//  identifier string "gwillish.Encounter.dhpack" lives in a single place.
//

import UniformTypeIdentifiers

extension UTType {
  // Force-unwrap is intentional: type is declared in this app's Info.plist.
  // A nil result means the identifier was mistyped — crash loudly at dev time.
  static let dhpack = UTType("gwillish.Encounter.dhpack")!
}
