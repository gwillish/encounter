//
//  ResumeTarget.swift
//  Encounter
//
//  A resolved pairing of an in-flight session and its source definition,
//  used to drive navigation directly into EncounterRunnerView.
//

import DHKit
import DHModels
import Foundation

/// A resolved pairing of an in-flight session and its source definition,
/// used to drive navigation directly into EncounterRunnerView.
///
/// `session` is an `@Observable` reference type stored by reference inside
/// this struct. If the session mutates between the resume prompt appearing and
/// the user tapping Resume, the target reflects the live state — this is
/// intentional. Do not change `session` to a value copy.
struct ResumeTarget: Identifiable, Hashable {
  let id: UUID  // session.id
  let session: EncounterSession
  let definition: EncounterDefinition

  static func == (lhs: ResumeTarget, rhs: ResumeTarget) -> Bool { lhs.id == rhs.id }
  func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
