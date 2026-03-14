//
//  Adversary.swift
//  Encounter
//
//  Static catalog models for Daggerheart adversaries.
//  These represent SRD or homebrew definitions — not live encounter state.
//  See EncounterSession.swift for runtime tracking types.
//
//  JSON schema compatible with:
//    - seansbox/daggerheart-srd  (.build/json/adversaries.json)
//    - ly0va/beastvault           (YAML/JSON library format)
//    - javalent/fantasy-statblocks (Daggerheart layout)
//  See docs/data-schema.md for full field reference and source notes.
//

import Foundation

// MARK: - AdversaryType

/// The role an adversary plays in a conflict.
///
/// Source: Daggerheart SRD "Using Adversaries" — each type modifies
/// how the adversary is run at the table.
public enum AdversaryType: String, Codable, CaseIterable, Sendable {
    /// Tough; deliver powerful attacks. Usually have extra HP.
    case bruiser  = "Bruiser"
    /// Groups of identical creatures acting as a single unit.
    /// Special HP/attack rules apply; see SRD "Horde" section.
    case horde    = "Horde"
    /// Command and summon other adversaries. High stress capacity.
    case leader   = "Leader"
    /// Easily dispatched but dangerous in numbers.
    case minion   = "Minion"
    /// Fragile up close; deal high damage at range.
    case ranged   = "Ranged"
    /// Designed for one-on-one or climactic encounters.
    case solo     = "Solo"
    /// Catch-all for adversaries without an explicit type label.
    case standard = "Standard"
}

// MARK: - AttackRange

/// Distance bands used for attacks and abilities in Daggerheart.
public enum AttackRange: String, Codable, CaseIterable, Sendable {
    case veryClose = "Very Close"
    case close     = "Close"
    case far       = "Far"
    case veryFar   = "Very Far"
}

// MARK: - FeatureType

/// The three categories of adversary features from the SRD.
///
/// - **Actions** trigger when the adversary has the spotlight.
/// - **Reactions** trigger regardless of who has the spotlight.
/// - **Passives** are always in effect.
public enum FeatureType: String, Codable, CaseIterable, Sendable {
    case action   = "action"
    case reaction = "reaction"
    case passive  = "passive"
}

// MARK: - AdversaryFeature

/// A single named feature (action, reaction, or passive) on an adversary or environment.
public struct AdversaryFeature: Codable, Identifiable, Sendable, Equatable {
    // `id` uses name because feature names are unique within a given adversary.
    public var id: String { name }

    public let name: String
    public let text: String
    public let featType: FeatureType

    // Community JSON uses "feat_type"; some sources use "type".
    // We normalise to featType in Swift.
    enum CodingKeys: String, CodingKey {
        case name
        case text
        case featType = "feat_type"
    }

    public init(name: String, text: String, featType: FeatureType) {
        self.name = name
        self.text = text
        self.featType = featType
    }
}

// MARK: - Adversary

/// A Daggerheart adversary as defined in the SRD or a homebrew compendium.
///
/// This is a **catalog model** — it represents the static definition of an
/// adversary, not a live instance being tracked in an encounter.
/// See ``AdversarySlot`` in `EncounterSession.swift` for the runtime type.
///
/// ## JSON Compatibility
/// The `thresholds` field is stored in community JSON as a single
/// `"major/severe"` string (e.g. `"8/15"`). The custom decoder splits this
/// into `thresholdMajor` and `thresholdSevere` integers. Both the combined
/// string key and pre-split `threshold_major` / `threshold_severe` keys
/// are accepted.
public struct Adversary: Codable, Identifiable, Sendable, Equatable {

    // MARK: Identity
    /// URL-safe slug, e.g. `"acid-burrower"`. Used as stable ID for cross-referencing.
    public let id: String
    public let name: String
    /// Content source tag: `"SRD"`, `"Homebrew"`, a book name, etc.
    public let source: String

    // MARK: Classification
    /// Opposes PCs of the matching tier (1–4).
    public let tier: Int
    public let type: AdversaryType

    // MARK: Description
    public let description: String
    /// GM-facing guidance on how to play this adversary at the table.
    public let motivesAndTactics: String?

    // MARK: Core Stats
    /// The DC for all player rolls made against this adversary.
    /// Adversaries never roll Evasion — they use a flat Difficulty.
    public let difficulty: Int
    /// Damage required to trigger a **Major** hit on this adversary.
    public let thresholdMajor: Int
    /// Damage required to trigger a **Severe** hit on this adversary.
    public let thresholdSevere: Int
    public let hp: Int
    public let stress: Int

    // MARK: Standard Attack
    /// Attack modifier string, e.g. `"+3"`.
    public let attackModifier: String
    /// Name of the standard attack or weapon, e.g. `"Claws"`.
    public let attackName: String
    public let attackRange: AttackRange
    /// Damage expression, e.g. `"1d12+2 phy"`. Parse with a dice library as needed.
    public let damage: String

    // MARK: Additional
    /// Optional experience tag, e.g. `"Tremor Sense +2"`.
    public let experience: String?
    /// Actions, reactions, and passives for this adversary.
    public let features: [AdversaryFeature]

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, name, source, tier, type, description
        case motivesAndTactics  = "motives_and_tactics"
        case difficulty
        // Raw combined key from community JSON ("8/15"):
        case thresholds
        // Pre-split alternative keys (our own export format):
        case thresholdMajor     = "threshold_major"
        case thresholdSevere    = "threshold_severe"
        case hp, stress
        case attackModifier     = "atk"
        case attackName         = "attack"
        case attackRange        = "range"
        case damage, experience
        case features           = "feats"
    }

    // MARK: - Decodable

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id          = try c.decode(String.self,       forKey: .id)
        name        = try c.decode(String.self,       forKey: .name)
        source      = try c.decodeIfPresent(String.self, forKey: .source) ?? "Unknown"
        tier        = try c.decode(Int.self,          forKey: .tier)
        type        = try c.decode(AdversaryType.self, forKey: .type)
        description = try c.decode(String.self,       forKey: .description)
        motivesAndTactics = try c.decodeIfPresent(String.self, forKey: .motivesAndTactics)
        difficulty  = try c.decode(Int.self,          forKey: .difficulty)
        hp          = try c.decode(Int.self,          forKey: .hp)
        stress      = try c.decode(Int.self,          forKey: .stress)
        attackModifier = try c.decode(String.self,    forKey: .attackModifier)
        attackName  = try c.decode(String.self,       forKey: .attackName)
        attackRange = try c.decode(AttackRange.self,  forKey: .attackRange)
        damage      = try c.decode(String.self,       forKey: .damage)
        experience  = try c.decodeIfPresent(String.self, forKey: .experience)
        features    = try c.decodeIfPresent([AdversaryFeature].self, forKey: .features) ?? []

        // Threshold decoding: prefer pre-split keys, fall back to "major/severe" string.
        if let major  = try c.decodeIfPresent(Int.self, forKey: .thresholdMajor),
           let severe = try c.decodeIfPresent(Int.self, forKey: .thresholdSevere) {
            thresholdMajor  = major
            thresholdSevere = severe
        } else if let raw = try c.decodeIfPresent(String.self, forKey: .thresholds) {
            let parts = raw
                .split(separator: "/")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            guard parts.count == 2 else {
                throw DecodingError.dataCorruptedError(
                    forKey: .thresholds, in: c,
                    debugDescription: "Expected 'major/severe' integer format, got '\(raw)'"
                )
            }
            thresholdMajor  = parts[0]
            thresholdSevere = parts[1]
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.thresholds,
                DecodingError.Context(
                    codingPath: c.codingPath,
                    debugDescription: "No threshold data found (tried 'thresholds', 'threshold_major'/'threshold_severe')"
                )
            )
        }
    }

    // MARK: - Encodable (uses pre-split keys for clarity)

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,             forKey: .id)
        try c.encode(name,           forKey: .name)
        try c.encode(source,         forKey: .source)
        try c.encode(tier,           forKey: .tier)
        try c.encode(type,           forKey: .type)
        try c.encode(description,    forKey: .description)
        try c.encodeIfPresent(motivesAndTactics, forKey: .motivesAndTactics)
        try c.encode(difficulty,     forKey: .difficulty)
        try c.encode(thresholdMajor, forKey: .thresholdMajor)
        try c.encode(thresholdSevere, forKey: .thresholdSevere)
        try c.encode(hp,             forKey: .hp)
        try c.encode(stress,         forKey: .stress)
        try c.encode(attackModifier, forKey: .attackModifier)
        try c.encode(attackName,     forKey: .attackName)
        try c.encode(attackRange,    forKey: .attackRange)
        try c.encode(damage,         forKey: .damage)
        try c.encodeIfPresent(experience, forKey: .experience)
        try c.encode(features,       forKey: .features)
    }

    // MARK: - Memberwise init (for previews / tests)

    public init(
        id: String,
        name: String,
        source: String = "SRD",
        tier: Int,
        type: AdversaryType,
        description: String,
        motivesAndTactics: String? = nil,
        difficulty: Int,
        thresholdMajor: Int,
        thresholdSevere: Int,
        hp: Int,
        stress: Int,
        attackModifier: String,
        attackName: String,
        attackRange: AttackRange,
        damage: String,
        experience: String? = nil,
        features: [AdversaryFeature] = []
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.tier = tier
        self.type = type
        self.description = description
        self.motivesAndTactics = motivesAndTactics
        self.difficulty = difficulty
        self.thresholdMajor = thresholdMajor
        self.thresholdSevere = thresholdSevere
        self.hp = hp
        self.stress = stress
        self.attackModifier = attackModifier
        self.attackName = attackName
        self.attackRange = attackRange
        self.damage = damage
        self.experience = experience
        self.features = features
    }
}
