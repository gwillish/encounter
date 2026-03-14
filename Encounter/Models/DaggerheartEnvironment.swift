//
//  DaggerheartEnvironment.swift
//  Encounter
//
//  Daggerheart environment catalog model.
//  Environments are distinct from adversaries: they have no HP or Stress,
//  and represent terrain hazards, magical phenomena, or scene elements
//  that interact with the action economy.
//
//  Named "DaggerheartEnvironment" to avoid collision with SwiftUI's
//  `Environment` property wrapper.
//
//  JSON schema: same community ecosystem as Adversary.swift.
//  BeastVault discriminates adversary vs. environment by absence of hp/stress.
//  See docs/data-schema.md for the full field reference.
//

import Foundation

/// A Daggerheart environment — a scene element with features but no HP or Stress.
///
/// Environments share the same feature schema as adversaries but represent
/// location hazards, terrain, or interactive elements rather than combatants.
/// They participate in encounters but are not tracked as HP pools.
public struct DaggerheartEnvironment: Codable, Identifiable, Sendable, Equatable {

    // MARK: Identity
    /// URL-safe slug, e.g. `"collapsing-cavern"`.
    public let id: String
    public let name: String
    /// Content source tag: `"SRD"`, `"Homebrew"`, a book name, etc.
    public let source: String

    // MARK: Description
    public let description: String

    // MARK: Features
    /// Passives, reactions, and actions this environment contributes to the scene.
    public let features: [AdversaryFeature]

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, name, source, description
        case features = "feats"
    }

    // MARK: - Memberwise init (for previews / tests)

    public init(
        id: String,
        name: String,
        source: String = "SRD",
        description: String,
        features: [AdversaryFeature] = []
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.description = description
        self.features = features
    }
}
