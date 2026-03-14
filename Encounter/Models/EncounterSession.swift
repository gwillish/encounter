//
//  EncounterSession.swift
//  Encounter
//
//  Runtime models for a live Daggerheart encounter.
//  These are the mutable, in-play tracking types — separate from the
//  static catalog definitions in Adversary.swift.
//
//  Design notes:
//  - EncounterSession is @Observable so SwiftUI views bind to it directly.
//  - AdversarySlot and EnvironmentSlot are structs stored in the session's
//    arrays; mutations flow through the session class.
//  - Fear and Hope are tracked on the session; individual adversary stress
//    contributes to Fear when thresholds are crossed (GM's discretion).
//  - The `activeSlotID` drives spotlight management in the UI.
//

import Foundation
import Observation

// MARK: - AdversarySlot

/// A single adversary participant in a live encounter.
///
/// Wraps a reference to a catalog ``Adversary`` with runtime mutable state:
/// current HP, current Stress, defeat status, and an optional individual name
/// (useful when running multiple copies of the same adversary).
public struct AdversarySlot: Identifiable, Sendable, Equatable {
    public let id: UUID
    /// The slug that identifies this adversary in the ``Compendium``.
    public let adversaryID: String
    /// Display name override (e.g. "Grimfang" for a named bandit leader).
    /// Falls back to the catalog name when `nil`.
    public var customName: String?

    // MARK: Tracked Stats
    public var currentHP: Int
    public var currentStress: Int
    public var isDefeated: Bool

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        adversaryID: String,
        customName: String? = nil,
        currentHP: Int,
        currentStress: Int = 0,
        isDefeated: Bool = false
    ) {
        self.id = id
        self.adversaryID = adversaryID
        self.customName = customName
        self.currentHP = currentHP
        self.currentStress = currentStress
        self.isDefeated = isDefeated
    }

    /// Convenience factory: create a slot pre-populated from a catalog entry.
    public static func from(_ adversary: Adversary, customName: String? = nil) -> AdversarySlot {
        AdversarySlot(
            adversaryID: adversary.id,
            customName: customName,
            currentHP: adversary.hp,
            currentStress: 0
        )
    }
}

// MARK: - EnvironmentSlot

/// An environment element active in the current encounter scene.
///
/// Environments have no HP or Stress — they are tracked only for
/// their features and activation state.
public struct EnvironmentSlot: Identifiable, Sendable, Equatable {
    public let id: UUID
    /// The slug identifying this environment in the ``Compendium``.
    public let environmentID: String
    /// Whether this environment element is currently active/visible to players.
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        environmentID: String,
        isActive: Bool = true
    ) {
        self.id = id
        self.environmentID = environmentID
        self.isActive = isActive
    }
}

// MARK: - EncounterSession

/// The live state of a Daggerheart encounter being run at the table.
///
/// `EncounterSession` is the central observable object for encounter views.
/// It holds:
/// - The roster of active adversary and environment slots.
/// - The GM's Fear pool and the party's Hope pool.
/// - Spotlight management (which adversary/environment is currently active).
/// - Round and turn counters.
/// - A freeform GM notes field.
///
/// ## Usage
/// Create a session by adding slots from the ``Compendium``, then pass it
/// through the environment to encounter views.
///
/// ```swift
/// let session = EncounterSession(name: "Bandit Ambush")
/// session.add(adversary: bandits.ironguard)
/// session.add(adversary: bandits.ironguard)   // second copy
/// session.add(environment: terrain.forestEdge)
/// ```
@Observable
public final class EncounterSession: Identifiable, Sendable {

    // MARK: Identity
    public let id: UUID
    public var name: String

    // MARK: Participants
    public var adversarySlots: [AdversarySlot]
    public var environmentSlots: [EnvironmentSlot]

    // MARK: Fear & Hope
    /// The GM's Fear pool. Increases when players roll with Fear,
    /// decreases when the GM spends Fear on adversary actions.
    public var fearPool: Int

    /// The party's Hope pool (total across all PCs). Tracked here for
    /// quick reference; primary source of truth is player character sheets.
    public var hopePool: Int

    // MARK: Spotlight
    /// The ID of the adversary slot (or environment slot) currently taking
    /// its turn. `nil` when it is the players' action phase.
    public var activeSlotID: UUID?

    // MARK: Round Tracking
    public var currentRound: Int
    public var turnOrder: [UUID]   // ordered slot IDs for this round

    // MARK: Notes
    public var gmNotes: String

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        name: String,
        adversarySlots: [AdversarySlot] = [],
        environmentSlots: [EnvironmentSlot] = [],
        fearPool: Int = 0,
        hopePool: Int = 0,
        currentRound: Int = 1,
        gmNotes: String = ""
    ) {
        self.id = id
        self.name = name
        self.adversarySlots = adversarySlots
        self.environmentSlots = environmentSlots
        self.fearPool = fearPool
        self.hopePool = hopePool
        self.activeSlotID = nil
        self.currentRound = currentRound
        self.turnOrder = adversarySlots.map(\.id)
        self.gmNotes = gmNotes
    }

    // MARK: - Roster Management

    /// Add a new adversary slot populated from a catalog entry.
    public func add(adversary: Adversary, customName: String? = nil) {
        let slot = AdversarySlot.from(adversary, customName: customName)
        adversarySlots.append(slot)
        turnOrder.append(slot.id)
    }

    /// Add an environment slot.
    public func add(environment: DaggerheartEnvironment) {
        environmentSlots.append(EnvironmentSlot(environmentID: environment.id))
    }

    /// Remove an adversary slot by ID.
    public func removeAdversary(id: UUID) {
        adversarySlots.removeAll { $0.id == id }
        turnOrder.removeAll { $0 == id }
        if activeSlotID == id { activeSlotID = nil }
    }

    // MARK: - HP & Stress Mutations

    /// Apply damage to an adversary slot, clamping HP to 0.
    public func applyDamage(_ amount: Int, to slotID: UUID) {
        guard let index = adversarySlots.firstIndex(where: { $0.id == slotID }) else { return }
        adversarySlots[index].currentHP = max(0, adversarySlots[index].currentHP - amount)
        if adversarySlots[index].currentHP == 0 {
            adversarySlots[index].isDefeated = true
        }
    }

    /// Apply stress to an adversary slot, clamping to its maximum.
    public func applyStress(_ amount: Int, to slotID: UUID, using compendium: Compendium) {
        guard let index = adversarySlots.firstIndex(where: { $0.id == slotID }) else { return }
        let maxStress = compendium.adversary(id: adversarySlots[index].adversaryID)?.stress ?? Int.max
        adversarySlots[index].currentStress = min(maxStress, adversarySlots[index].currentStress + amount)
    }

    /// Heal an adversary slot, clamping HP to its catalog maximum.
    public func heal(_ amount: Int, slotID: UUID, using compendium: Compendium) {
        guard let index = adversarySlots.firstIndex(where: { $0.id == slotID }) else { return }
        let maxHP = compendium.adversary(id: adversarySlots[index].adversaryID)?.hp ?? Int.max
        adversarySlots[index].currentHP = min(maxHP, adversarySlots[index].currentHP + amount)
        if adversarySlots[index].currentHP > 0 {
            adversarySlots[index].isDefeated = false
        }
    }

    // MARK: - Fear & Hope

    public func incrementFear(by amount: Int = 1) {
        fearPool += amount
    }

    public func spendFear(_ amount: Int = 1) {
        fearPool = max(0, fearPool - amount)
    }

    public func incrementHope(by amount: Int = 1) {
        hopePool += amount
    }

    public func spendHope(_ amount: Int = 1) {
        hopePool = max(0, hopePool - amount)
    }

    // MARK: - Round Management

    /// Advance to the next round, resetting the turn position.
    public func advanceRound() {
        currentRound += 1
        activeSlotID = nil
        // Defeated adversaries are removed from the turn order for the new round.
        let defeatedIDs = Set(adversarySlots.filter(\.isDefeated).map(\.id))
        turnOrder = turnOrder.filter { !defeatedIDs.contains($0) }
    }

    /// Set the active spotlight to the next slot in turn order.
    public func advanceTurn() {
        guard !turnOrder.isEmpty else { activeSlotID = nil; return }
        if let current = activeSlotID,
           let currentIndex = turnOrder.firstIndex(of: current),
           currentIndex + 1 < turnOrder.count {
            activeSlotID = turnOrder[currentIndex + 1]
        } else {
            activeSlotID = turnOrder.first
        }
    }

    // MARK: - Computed Helpers

    /// All adversary slots still in the fight.
    public var activeAdversaries: [AdversarySlot] {
        adversarySlots.filter { !$0.isDefeated }
    }

    /// `true` when all adversary slots are defeated.
    public var isOver: Bool {
        adversarySlots.allSatisfy(\.isDefeated)
    }
}
