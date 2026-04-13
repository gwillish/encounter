//
//  ResumePromptView.swift
//  Encounter
//
//  Sheet presented on launch when one or more in-flight sessions were
//  found in the SessionRegistry. Offers a fast path back into the runner.
//

import DHKit
import DHModels
import SwiftUI

// MARK: - ResumeTarget

/// A resolved pairing of an in-flight session and its source definition,
/// used to drive navigation directly into EncounterRunnerView.
struct ResumeTarget: Identifiable, Hashable {
  let id: UUID  // session.id
  let session: EncounterSession
  let definition: EncounterDefinition

  static func == (lhs: ResumeTarget, rhs: ResumeTarget) -> Bool { lhs.id == rhs.id }
  func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - ResumePromptView

/// Shown in a sheet when at least one in-flight session is detected on launch.
///
/// A single session displays a focused "Resume" card. Multiple sessions
/// display a list. Swiping the sheet down (or tapping "Not Now") dismisses
/// it without resuming; the session remains persisted until explicitly ended.
struct ResumePromptView: View {
  let targets: [ResumeTarget]

  @State private var resumeTarget: ResumeTarget?
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Group {
        if targets.count == 1, let target = targets.first {
          singleResumeView(target)
        } else {
          multiResumeList
        }
      }
      .navigationTitle("In Progress")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Not Now") { dismiss() }
            .accessibilityIdentifier("resume.dismiss-button")
        }
      }
      .navigationDestination(item: $resumeTarget) { target in
        EncounterRunnerView(session: target.session, definition: target.definition)
      }
    }
  }

  // MARK: - Single session

  @ViewBuilder
  private func singleResumeView(_ target: ResumeTarget) -> some View {
    VStack(spacing: 32) {
      Spacer()
      VStack(spacing: 12) {
        Image(systemName: "shield.lefthalf.filled")
          .font(.system(size: 48))
          .foregroundStyle(.secondary)
        Text(target.definition.name)
          .font(.title2.bold())
        let activeCount = target.session.activeAdversaries.count
        Text(
          activeCount == 1
            ? "1 adversary still active"
            : "\(activeCount) adversaries still active"
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
      }
      Button("Resume Encounter") {
        resumeTarget = target
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .accessibilityIdentifier("resume.resume-button")
      Spacer()
    }
    .padding()
  }

  // MARK: - Multiple sessions

  private var multiResumeList: some View {
    List(targets) { target in
      Button {
        resumeTarget = target
      } label: {
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text(target.definition.name)
              .font(.headline)
              .foregroundStyle(.primary)
            let activeCount = target.session.activeAdversaries.count
            Text(
              activeCount == 1
                ? "1 adversary active"
                : "\(activeCount) adversaries active"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
          }
          Spacer()
          Image(systemName: "chevron.right")
            .foregroundStyle(.secondary)
        }
      }
      .accessibilityIdentifier("resume.session-\(target.id)")
    }
  }
}

// MARK: - Preview helpers

private let previewCompendium: Compendium = {
  let c = Compendium()
  c.addAdversary(
    Adversary(
      id: "goblin", name: "Goblin", tier: 1, role: .minion,
      flavorText: "Small and cunning.", difficulty: 10,
      thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
      attackModifier: "+2", attackName: "Rusty Blade",
      attackRange: .veryClose, damage: "1d4 phy"
    ))
  return c
}()

#Preview("Single session") {
  let def = EncounterDefinition(name: "Goblin Ambush", adversaryIDs: ["goblin", "goblin"])
  let session = EncounterSession.make(from: def, using: previewCompendium)
  let target = ResumeTarget(id: session.id, session: session, definition: def)
  return ResumePromptView(targets: [target])
    .environment(previewCompendium)
    .environment(SessionRegistry())
    .environment(SessionStore(directory: .temporaryDirectory))
}

#Preview("Multiple sessions") {
  let def1 = EncounterDefinition(name: "Goblin Ambush", adversaryIDs: ["goblin"])
  let def2 = EncounterDefinition(name: "Dragon's Lair", adversaryIDs: ["goblin", "goblin"])
  let s1 = EncounterSession.make(from: def1, using: previewCompendium)
  let s2 = EncounterSession.make(from: def2, using: previewCompendium)
  let targets = [
    ResumeTarget(id: s1.id, session: s1, definition: def1),
    ResumeTarget(id: s2.id, session: s2, definition: def2),
  ]
  return ResumePromptView(targets: targets)
    .environment(previewCompendium)
    .environment(SessionRegistry())
    .environment(SessionStore(directory: .temporaryDirectory))
}
