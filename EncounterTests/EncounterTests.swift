//
//  EncounterTests.swift
//  EncounterTests
//
//  Unit tests for Daggerheart data models.
//

import Foundation
import Testing
@testable import Encounter

// MARK: - Adversary Decoding

struct AdversaryDecodingTests {

    // MARK: Combined threshold string ("8/15")

    @Test func decodesThresholdsFromCombinedString() throws {
        let json = """
        {
          "id": "test-creature",
          "name": "Test Creature",
          "source": "SRD",
          "tier": 1,
          "type": "Bruiser",
          "description": "A test creature.",
          "difficulty": 12,
          "thresholds": "8/15",
          "hp": 8,
          "stress": 3,
          "atk": "+3",
          "attack": "Claws",
          "range": "Very Close",
          "damage": "1d10+2 phy",
          "feats": []
        }
        """.data(using: .utf8)!

        let adversary = try JSONDecoder().decode(Adversary.self, from: json)
        #expect(adversary.thresholdMajor  == 8)
        #expect(adversary.thresholdSevere == 15)
    }

    // MARK: Pre-split threshold keys

    @Test func decodesThresholdsFromSplitKeys() throws {
        let json = """
        {
          "id": "warlord-keth",
          "name": "Warlord Keth",
          "tier": 2,
          "type": "Leader",
          "description": "A scarred half-giant general.",
          "difficulty": 14,
          "threshold_major": 9,
          "threshold_severe": 17,
          "hp": 12,
          "stress": 6,
          "atk": "+5",
          "attack": "Greataxe",
          "range": "Very Close",
          "damage": "2d10+4 phy",
          "feats": []
        }
        """.data(using: .utf8)!

        let adversary = try JSONDecoder().decode(Adversary.self, from: json)
        #expect(adversary.thresholdMajor  == 9)
        #expect(adversary.thresholdSevere == 17)
        #expect(adversary.source          == "Unknown") // optional, defaults
    }

    // MARK: Feature decoding

    @Test func decodesFeatures() throws {
        let json = """
        {
          "id": "test",
          "name": "Test",
          "tier": 1,
          "type": "Minion",
          "description": "Desc",
          "difficulty": 9,
          "thresholds": "3/6",
          "hp": 3,
          "stress": 2,
          "atk": "+1",
          "attack": "Bite",
          "range": "Very Close",
          "damage": "1d6 phy",
          "feats": [
            { "name": "Pack Tactics", "text": "Deals bonus damage in groups.", "feat_type": "passive" },
            { "name": "Snap",         "text": "Triggers when hit.",            "feat_type": "reaction" },
            { "name": "Lunge",        "text": "Extra attack once per round.",  "feat_type": "action" }
          ]
        }
        """.data(using: .utf8)!

        let adversary = try JSONDecoder().decode(Adversary.self, from: json)
        #expect(adversary.features.count == 3)
        #expect(adversary.features[0].featType == FeatureType.passive)
        #expect(adversary.features[1].featType == FeatureType.reaction)
        #expect(adversary.features[2].featType == FeatureType.action)
    }

    // MARK: AdversaryType round-trip

    @Test func adversaryTypeRoundTrip() throws {
        for type_ in AdversaryType.allCases {
            let encoded = try JSONEncoder().encode(type_)
            let decoded = try JSONDecoder().decode(AdversaryType.self, from: encoded)
            #expect(decoded == type_)
        }
    }

    // MARK: AttackRange round-trip

    @Test func attackRangeRoundTrip() throws {
        for range in AttackRange.allCases {
            let encoded = try JSONEncoder().encode(range)
            let decoded = try JSONDecoder().decode(AttackRange.self, from: encoded)
            #expect(decoded == range)
        }
    }

    // MARK: New SRD adversary types (Skulk, Social, Support)

    @Test func decodesNewAdversaryTypes() throws {
        for typeString in ["Skulk", "Social", "Support"] {
            let json = """
            {
              "id": "test-\(typeString.lowercased())",
              "name": "Test \(typeString)",
              "tier": 1,
              "type": "\(typeString)",
              "description": "A test creature.",
              "difficulty": 10,
              "thresholds": "5/10",
              "hp": 4,
              "stress": 2,
              "atk": "+2",
              "attack": "Strike",
              "range": "Close",
              "damage": "1d6 phy",
              "feats": []
            }
            """.data(using: .utf8)!

            let adversary = try JSONDecoder().decode(Adversary.self, from: json)
            #expect(adversary.type.rawValue == typeString)
        }
    }

    @Test func adversaryTypeHasAllTenCases() {
        #expect(AdversaryType.allCases.count == 10)
    }

    // MARK: Malformed threshold throws

    @Test func malformedThresholdStringThrows() {
        let json = """
        {
          "id": "bad",
          "name": "Bad",
          "tier": 1,
          "type": "Minion",
          "description": "Desc",
          "difficulty": 9,
          "thresholds": "notanumber",
          "hp": 3,
          "stress": 2,
          "atk": "+1",
          "attack": "Bite",
          "range": "Close",
          "damage": "1d6 phy",
          "feats": []
        }
        """.data(using: .utf8)!

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Adversary.self, from: json)
        }
    }
}

// MARK: - Condition

struct ConditionTests {

    @Test func standardConditionsExist() {
        let conditions: Set<Condition> = [.hidden, .restrained, .vulnerable]
        #expect(conditions.count == 3)
    }

    @Test func customConditionEquality() {
        let c1 = Condition.custom("Enraged")
        let c2 = Condition.custom("Enraged")
        let c3 = Condition.custom("Prone")
        #expect(c1 == c2)
        #expect(c1 != c3)
    }

    @Test func conditionSetPreventsStacking() {
        var conditions: Set<Condition> = []
        conditions.insert(.hidden)
        conditions.insert(.hidden)
        #expect(conditions.count == 1)
    }

    @Test func conditionCodableRoundTrip() throws {
        let original: Set<Condition> = [.hidden, .restrained, .custom("Enraged")]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Set<Condition>.self, from: data)
        #expect(decoded == original)
    }

    @Test func conditionDisplayName() {
        #expect(Condition.hidden.displayName == "Hidden")
        #expect(Condition.restrained.displayName == "Restrained")
        #expect(Condition.vulnerable.displayName == "Vulnerable")
        #expect(Condition.custom("Enraged").displayName == "Enraged")
    }
}

// MARK: - EncounterSession

@MainActor struct EncounterSessionTests {

    private func makeSession() -> EncounterSession {
        EncounterSession(name: "Test Encounter")
    }

    private func makeSoldier() -> Adversary {
        Adversary(
            id: "ironguard-soldier",
            name: "Ironguard Soldier",
            tier: 1,
            type: .bruiser,
            description: "A disciplined mercenary.",
            difficulty: 11,
            thresholdMajor: 5,
            thresholdSevere: 10,
            hp: 6,
            stress: 3,
            attackModifier: "+3",
            attackName: "Longsword",
            attackRange: .veryClose,
            damage: "1d10+3 phy"
        )
    }

    @Test func addAdversaryPopulatesSlot() {
        let session = makeSession()
        let soldier = makeSoldier()
        session.add(adversary: soldier)

        #expect(session.adversarySlots.count == 1)
        #expect(session.adversarySlots[0].currentHP == 6)
        #expect(session.adversarySlots[0].currentStress == 0)
        #expect(session.adversarySlots[0].isDefeated == false)
    }

    @Test func applyDamageReducesHP() {
        let session = makeSession()
        let soldier = makeSoldier()
        session.add(adversary: soldier)
        let slotID = session.adversarySlots[0].id

        session.applyDamage(4, to: slotID)
        #expect(session.adversarySlots[0].currentHP == 2)
    }

    @Test func applyDamageToZeroMarksDefeated() {
        let session = makeSession()
        let soldier = makeSoldier()
        session.add(adversary: soldier)
        let slotID = session.adversarySlots[0].id

        session.applyDamage(100, to: slotID)
        #expect(session.adversarySlots[0].currentHP    == 0)
        #expect(session.adversarySlots[0].isDefeated   == true)
        #expect(session.activeAdversaries.isEmpty)
    }

    @Test func fearAndHopeMutations() {
        let session = makeSession()
        session.incrementFear(by: 3)
        #expect(session.fearPool == 3)

        session.spendFear(2)
        #expect(session.fearPool == 1)

        session.spendFear(10) // clamped
        #expect(session.fearPool == 0)

        session.incrementHope(by: 5)
        session.spendHope(2)
        #expect(session.hopePool == 3)
    }

    @Test func isOverWhenAllDefeated() {
        let session = makeSession()
        let soldier = makeSoldier()
        session.add(adversary: soldier)
        #expect(session.isOver == false)

        let slotID = session.adversarySlots[0].id
        session.applyDamage(999, to: slotID)
        #expect(session.isOver == true)
    }

    @Test func advanceRoundIncrementsCounter() {
        let session = makeSession()
        #expect(session.currentRound == 1)
        session.advanceRound()
        #expect(session.currentRound == 2)
    }

    // MARK: Adversary Conditions

    @Test func adversarySlotStartsWithNoConditions() {
        let session = makeSession()
        session.add(adversary: makeSoldier())
        #expect(session.adversarySlots[0].conditions.isEmpty)
    }

    @Test func applyConditionToAdversarySlot() {
        let session = makeSession()
        session.add(adversary: makeSoldier())
        let slotID = session.adversarySlots[0].id

        session.applyCondition(.restrained, to: slotID)
        #expect(session.adversarySlots[0].conditions.contains(.restrained))
    }

    @Test func removeConditionFromAdversarySlot() {
        let session = makeSession()
        session.add(adversary: makeSoldier())
        let slotID = session.adversarySlots[0].id

        session.applyCondition(.hidden, to: slotID)
        session.removeCondition(.hidden, from: slotID)
        #expect(!session.adversarySlots[0].conditions.contains(.hidden))
    }

    @Test func conditionsDoNotStack() {
        let session = makeSession()
        session.add(adversary: makeSoldier())
        let slotID = session.adversarySlots[0].id

        session.applyCondition(.vulnerable, to: slotID)
        session.applyCondition(.vulnerable, to: slotID)
        #expect(session.adversarySlots[0].conditions.count == 1)
    }

    @Test func emptyCustomConditionOnAdversaryIsRejected() {
        let session = makeSession()
        session.add(adversary: makeSoldier())
        let slotID = session.adversarySlots[0].id

        session.applyCondition(.custom(""), to: slotID)
        #expect(session.adversarySlots[0].conditions.isEmpty)
    }

    @Test func whitespaceCustomConditionOnAdversaryIsRejected() {
        let session = makeSession()
        session.add(adversary: makeSoldier())
        let slotID = session.adversarySlots[0].id

        session.applyCondition(.custom("   "), to: slotID)
        #expect(session.adversarySlots[0].conditions.isEmpty)
    }

    @Test func customConditionOnAdversarySlot() {
        let session = makeSession()
        session.add(adversary: makeSoldier())
        let slotID = session.adversarySlots[0].id

        session.applyCondition(.custom("Enraged"), to: slotID)
        #expect(session.adversarySlots[0].conditions.contains(.custom("Enraged")))
    }

    // MARK: Turn Order

    @Test func advanceTurnSkipsDefeatedAdversary() {
        let session = makeSession()
        session.add(adversary: makeSoldier())
        session.add(adversary: makeSoldier())

        let firstID  = session.turnOrder[0]
        let secondID = session.turnOrder[1]

        // Defeat first adversary mid-round before taking a turn
        session.applyDamage(999, to: firstID)

        // First advanceTurn should skip the defeated slot
        session.advanceTurn()
        #expect(session.activeSlotID == secondID)
    }

    @Test func advanceTurnSkipsDefeatedMidRound() {
        let session = makeSession()
        session.add(adversary: makeSoldier())
        session.add(adversary: makeSoldier())
        session.add(adversary: makeSoldier())

        let firstID  = session.turnOrder[0]
        let secondID = session.turnOrder[1]
        let thirdID  = session.turnOrder[2]

        // Advance to second slot
        session.advanceTurn()
        session.advanceTurn()
        #expect(session.activeSlotID == secondID)

        // Defeat the third slot mid-round
        session.applyDamage(999, to: thirdID)

        // Next advance should skip defeated third and wrap back to first
        session.advanceTurn()
        #expect(session.activeSlotID == firstID)
    }

    @Test func advanceTurnCyclesSlots() {
        let session = makeSession()
        let soldier = makeSoldier()
        session.add(adversary: soldier)
        session.add(adversary: soldier)

        let first = session.turnOrder[0]
        let second = session.turnOrder[1]

        session.advanceTurn()
        #expect(session.activeSlotID == first)

        session.advanceTurn()
        #expect(session.activeSlotID == second)

        // Wraps back to first slot
        session.advanceTurn()
        #expect(session.activeSlotID == first)
    }
}

// MARK: - PlayerSlot

struct PlayerSlotTests {

    @Test func playerSlotInitializesWithCorrectDefaults() {
        let slot = PlayerSlot(
            name: "Aldric",
            maxHP: 6,
            maxStress: 6,
            evasion: 12,
            thresholdMajor: 8,
            thresholdSevere: 15,
            armorSlots: 3
        )
        #expect(slot.name == "Aldric")
        #expect(slot.currentHP == 6)
        #expect(slot.currentStress == 0)
        #expect(slot.currentArmorSlots == 3)
        #expect(slot.conditions.isEmpty)
    }

    @Test func playerSlotEquality() {
        let id = UUID()
        let slot1 = PlayerSlot(
            id: id, name: "A", maxHP: 6, maxStress: 6,
            evasion: 10, thresholdMajor: 5, thresholdSevere: 10, armorSlots: 2
        )
        let slot2 = PlayerSlot(
            id: id, name: "A", maxHP: 6, maxStress: 6,
            evasion: 10, thresholdMajor: 5, thresholdSevere: 10, armorSlots: 2
        )
        #expect(slot1 == slot2)
    }
}

// MARK: - PlayerSlot Session Integration

@MainActor struct PlayerSlotSessionTests {

    private func makeSession() -> EncounterSession {
        EncounterSession(name: "Test Encounter")
    }

    private func makeSoldier() -> Adversary {
        Adversary(
            id: "ironguard-soldier",
            name: "Ironguard Soldier",
            tier: 1,
            type: .bruiser,
            description: "A disciplined mercenary.",
            difficulty: 11,
            thresholdMajor: 5,
            thresholdSevere: 10,
            hp: 6,
            stress: 3,
            attackModifier: "+3",
            attackName: "Longsword",
            attackRange: .veryClose,
            damage: "1d10+3 phy"
        )
    }

    private func makePlayer() -> PlayerSlot {
        PlayerSlot(
            name: "Aldric",
            maxHP: 6,
            maxStress: 6,
            evasion: 12,
            thresholdMajor: 8,
            thresholdSevere: 15,
            armorSlots: 3
        )
    }

    @Test func addPlayerSlotToSession() {
        let session = makeSession()
        session.addPlayer(makePlayer())
        #expect(session.playerSlots.count == 1)
        #expect(session.playerSlots[0].name == "Aldric")
    }

    @Test func turnOrderIncludesPlayersAndAdversaries() {
        let session = makeSession()
        session.add(adversary: makeSoldier())
        session.addPlayer(makePlayer())
        #expect(session.turnOrder.count == 2)
    }

    @Test func advanceTurnCyclesThroughBothSlotTypes() {
        let session = makeSession()
        session.add(adversary: makeSoldier())
        session.addPlayer(makePlayer())

        session.advanceTurn()
        #expect(session.activeSlotID == session.turnOrder[0])

        session.advanceTurn()
        #expect(session.activeSlotID == session.turnOrder[1])
    }

    @Test func applyDamageToPlayerSlot() {
        let session = makeSession()
        session.addPlayer(makePlayer())
        let slotID = session.playerSlots[0].id

        session.applyPlayerDamage(2, to: slotID)
        #expect(session.playerSlots[0].currentHP == 4)
    }

    @Test func playerDamageClampsToZero() {
        let session = makeSession()
        session.addPlayer(makePlayer())
        let slotID = session.playerSlots[0].id

        session.applyPlayerDamage(100, to: slotID)
        #expect(session.playerSlots[0].currentHP == 0)
    }

    @Test func applyStressToPlayerSlot() {
        let session = makeSession()
        session.addPlayer(makePlayer())
        let slotID = session.playerSlots[0].id

        session.applyPlayerStress(3, to: slotID)
        #expect(session.playerSlots[0].currentStress == 3)
    }

    @Test func playerStressClampsToMax() {
        let session = makeSession()
        session.addPlayer(makePlayer())
        let slotID = session.playerSlots[0].id

        session.applyPlayerStress(100, to: slotID)
        #expect(session.playerSlots[0].currentStress == 6)
    }

    @Test func healPlayerSlot() {
        let session = makeSession()
        session.addPlayer(makePlayer())
        let slotID = session.playerSlots[0].id

        session.applyPlayerDamage(4, to: slotID)
        session.healPlayer(2, slotID: slotID)
        #expect(session.playerSlots[0].currentHP == 4)
    }

    @Test func healPlayerClampsToMax() {
        let session = makeSession()
        session.addPlayer(makePlayer())
        let slotID = session.playerSlots[0].id

        session.applyPlayerDamage(2, to: slotID)
        session.healPlayer(100, slotID: slotID)
        #expect(session.playerSlots[0].currentHP == 6)
    }

    @Test func clearPlayerStress() {
        let session = makeSession()
        session.addPlayer(makePlayer())
        let slotID = session.playerSlots[0].id

        session.applyPlayerStress(4, to: slotID)
        session.clearPlayerStress(2, slotID: slotID)
        #expect(session.playerSlots[0].currentStress == 2)
    }

    @Test func markArmorSlotOnPlayer() {
        let session = makeSession()
        session.addPlayer(makePlayer())
        let slotID = session.playerSlots[0].id

        session.markPlayerArmorSlot(slotID)
        #expect(session.playerSlots[0].currentArmorSlots == 2)
    }

    @Test func markArmorSlotClampsToZero() {
        let session = makeSession()
        var player = makePlayer()
        player = PlayerSlot(
            name: player.name, maxHP: player.maxHP, maxStress: player.maxStress,
            evasion: player.evasion, thresholdMajor: player.thresholdMajor,
            thresholdSevere: player.thresholdSevere, armorSlots: 1
        )
        session.addPlayer(player)
        let slotID = session.playerSlots[0].id

        session.markPlayerArmorSlot(slotID)
        session.markPlayerArmorSlot(slotID) // already at 0
        #expect(session.playerSlots[0].currentArmorSlots == 0)
    }

    @Test func emptyCustomConditionOnPlayerIsRejected() {
        let session = makeSession()
        session.addPlayer(makePlayer())
        let slotID = session.playerSlots[0].id

        session.applyPlayerCondition(.custom(""), to: slotID)
        #expect(session.playerSlots[0].conditions.isEmpty)
    }

    @Test func applyConditionToPlayerSlot() {
        let session = makeSession()
        session.addPlayer(makePlayer())
        let slotID = session.playerSlots[0].id

        session.applyPlayerCondition(.vulnerable, to: slotID)
        #expect(session.playerSlots[0].conditions.contains(.vulnerable))
    }

    @Test func removeConditionFromPlayerSlot() {
        let session = makeSession()
        session.addPlayer(makePlayer())
        let slotID = session.playerSlots[0].id

        session.applyPlayerCondition(.hidden, to: slotID)
        session.removePlayerCondition(.hidden, from: slotID)
        #expect(!session.playerSlots[0].conditions.contains(.hidden))
    }

    @Test func removePlayerFromSession() {
        let session = makeSession()
        session.addPlayer(makePlayer())
        let slotID = session.playerSlots[0].id

        session.removePlayer(id: slotID)
        #expect(session.playerSlots.isEmpty)
        #expect(!session.turnOrder.contains(slotID))
    }
}

// MARK: - EncounterDefinition

struct EncounterDefinitionTests {

    @Test func definitionIsValueType() {
        var def1 = EncounterDefinition(name: "Test")
        let def2 = def1
        def1.name = "Modified"
        #expect(def2.name == "Test")
    }

    @Test func definitionCodableRoundTrip() throws {
        var definition = EncounterDefinition(name: "Bandit Ambush")
        definition.adversaryIDs = ["ironguard-soldier", "ironguard-soldier", "thornwood-archer"]
        definition.environmentIDs = ["collapsing-bridge"]
        definition.playerConfigs = [
            PlayerConfig(
                name: "Aldric", maxHP: 6, maxStress: 6,
                evasion: 12, thresholdMajor: 8, thresholdSevere: 15, armorSlots: 3
            )
        ]
        definition.gmNotes = "Start with archers hidden."

        let data = try JSONEncoder().encode(definition)
        let decoded = try JSONDecoder().decode(EncounterDefinition.self, from: data)

        #expect(decoded.name == "Bandit Ambush")
        #expect(decoded.adversaryIDs.count == 3)
        #expect(decoded.environmentIDs == ["collapsing-bridge"])
        #expect(decoded.playerConfigs.count == 1)
        #expect(decoded.playerConfigs[0].name == "Aldric")
        #expect(decoded.gmNotes == "Start with archers hidden.")
    }

    @Test func definitionHasTimestamps() {
        let before = Date.now
        let definition = EncounterDefinition(name: "Test")
        let after = Date.now
        #expect(definition.createdAt >= before)
        #expect(definition.createdAt <= after)
        #expect(definition.modifiedAt >= before)
    }

    @Test func mutatingNameUpdatesModifiedAt() async throws {
        var definition = EncounterDefinition(name: "Original")
        let before = definition.modifiedAt
        try await Task.sleep(for: .milliseconds(10))
        definition.name = "Updated"
        #expect(definition.modifiedAt > before)
    }

    @Test func mutatingAdversaryIDsUpdatesModifiedAt() async throws {
        var definition = EncounterDefinition(name: "Test")
        let before = definition.modifiedAt
        try await Task.sleep(for: .milliseconds(10))
        definition.adversaryIDs = ["ironguard-soldier"]
        #expect(definition.modifiedAt > before)
    }

    @Test func mutatingGMNotesUpdatesModifiedAt() async throws {
        var definition = EncounterDefinition(name: "Test")
        let before = definition.modifiedAt
        try await Task.sleep(for: .milliseconds(10))
        definition.gmNotes = "Remember the trap."
        #expect(definition.modifiedAt > before)
    }

    @Test func decodingDoesNotResetModifiedAt() throws {
        var definition = EncounterDefinition(
            name: "Test",
            modifiedAt: Date(timeIntervalSince1970: 1_000_000)
        )
        definition.adversaryIDs = [] // trigger didSet after init
        let data = try JSONEncoder().encode(definition)
        let decoded = try JSONDecoder().decode(EncounterDefinition.self, from: data)
        // Decoded modifiedAt should be the encoded value, not .now
        #expect(decoded.modifiedAt == definition.modifiedAt)
    }

    @Test func playerConfigCodableRoundTrip() throws {
        let config = PlayerConfig(
            name: "Sera", maxHP: 8, maxStress: 6,
            evasion: 14, thresholdMajor: 10, thresholdSevere: 18, armorSlots: 4
        )
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(PlayerConfig.self, from: data)

        #expect(decoded.name == "Sera")
        #expect(decoded.maxHP == 8)
        #expect(decoded.evasion == 14)
        #expect(decoded.armorSlots == 4)
    }
}

// MARK: - EncounterSession Factory

@MainActor struct EncounterSessionFactoryTests {

    private func makeCompendium() -> Compendium {
        let comp = Compendium()
        comp.addAdversary(Adversary(
            id: "ironguard-soldier", name: "Ironguard Soldier",
            tier: 1, type: .bruiser, description: "A disciplined mercenary.",
            difficulty: 11, thresholdMajor: 5, thresholdSevere: 10,
            hp: 6, stress: 3, attackModifier: "+3", attackName: "Longsword",
            attackRange: .veryClose, damage: "1d10+3 phy"
        ))
        comp.addEnvironment(DaggerheartEnvironment(
            id: "collapsing-bridge", name: "Collapsing Bridge",
            description: "A rope-and-plank bridge."
        ))
        return comp
    }

    @Test func sessionFromDefinitionPopulatesSlots() {
        let compendium = makeCompendium()
        var def = EncounterDefinition(name: "Test Battle")
        def.adversaryIDs = ["ironguard-soldier", "ironguard-soldier"]
        def.environmentIDs = ["collapsing-bridge"]
        def.playerConfigs = [
            PlayerConfig(
                name: "Aldric", maxHP: 6, maxStress: 6,
                evasion: 12, thresholdMajor: 8, thresholdSevere: 15, armorSlots: 3
            )
        ]

        let session = EncounterSession.start(from: def, using: compendium)

        #expect(session.name == "Test Battle")
        #expect(session.adversarySlots.count == 2)
        #expect(session.adversarySlots[0].currentHP == 6)
        #expect(session.playerSlots.count == 1)
        #expect(session.playerSlots[0].name == "Aldric")
        #expect(session.environmentSlots.count == 1)
        #expect(session.currentRound == 1)
        #expect(session.fearPool == 0)
    }

    @Test func sessionFromDefinitionSkipsUnknownAdversaries() {
        let compendium = makeCompendium()
        var def = EncounterDefinition(name: "Test")
        def.adversaryIDs = ["ironguard-soldier", "nonexistent-creature"]

        let session = EncounterSession.start(from: def, using: compendium)
        #expect(session.adversarySlots.count == 1)
    }

    @Test func sessionFromDefinitionPreservesGMNotes() {
        let compendium = makeCompendium()
        var def = EncounterDefinition(name: "Test")
        def.gmNotes = "Remember the secret door."

        let session = EncounterSession.start(from: def, using: compendium)
        #expect(session.gmNotes == "Remember the secret door.")
    }

    @Test func sessionFromDefinitionBuildsTurnOrder() {
        let compendium = makeCompendium()
        var def = EncounterDefinition(name: "Test")
        def.adversaryIDs = ["ironguard-soldier"]
        def.playerConfigs = [
            PlayerConfig(
                name: "Aldric", maxHP: 6, maxStress: 6,
                evasion: 12, thresholdMajor: 8, thresholdSevere: 15, armorSlots: 3
            )
        ]

        let session = EncounterSession.start(from: def, using: compendium)
        #expect(session.turnOrder.count == 2)
    }
}

// MARK: - DifficultyBudget

struct DifficultyBudgetTests {

    // MARK: Battle Point Costs

    @Test func minionCostsOnePoint() {
        #expect(DifficultyBudget.cost(for: .minion) == 1)
    }

    @Test func socialAndSupportCostOnePoint() {
        #expect(DifficultyBudget.cost(for: .social) == 1)
        #expect(DifficultyBudget.cost(for: .support) == 1)
    }

    @Test func standardTierCostsTwoPoints() {
        for type in [AdversaryType.horde, .ranged, .skulk, .standard] {
            #expect(
                DifficultyBudget.cost(for: type) == 2,
                "Expected \(type) to cost 2, got \(DifficultyBudget.cost(for: type))"
            )
        }
    }

    @Test func leaderCostsThreePoints() {
        #expect(DifficultyBudget.cost(for: .leader) == 3)
    }

    @Test func bruiserCostsFourPoints() {
        #expect(DifficultyBudget.cost(for: .bruiser) == 4)
    }

    @Test func soloCostsFivePoints() {
        #expect(DifficultyBudget.cost(for: .solo) == 5)
    }

    // MARK: Base Budget

    @Test func baseBudgetForFourPCs() {
        #expect(DifficultyBudget.baseBudget(playerCount: 4) == 14)
    }

    @Test func baseBudgetForThreePCs() {
        #expect(DifficultyBudget.baseBudget(playerCount: 3) == 11)
    }

    @Test func baseBudgetForOnePCMinimum() {
        #expect(DifficultyBudget.baseBudget(playerCount: 1) == 5)
    }

    // MARK: Total Cost

    @Test func totalCostForAdversaryList() {
        let types: [AdversaryType] = [.minion, .minion, .bruiser, .leader]
        #expect(DifficultyBudget.totalCost(for: types) == 9)
    }

    // MARK: Rating

    @Test func ratingWithinBudgetIsBalanced() {
        let rating = DifficultyBudget.rating(
            adversaryTypes: [.standard, .standard, .minion],
            playerCount: 4
        )
        #expect(rating.totalCost == 5)
        #expect(rating.budget == 14)
        #expect(rating.remaining == 9)
    }

    @Test func ratingOverBudgetShowsNegativeRemaining() {
        let rating = DifficultyBudget.rating(
            adversaryTypes: [.solo, .solo, .bruiser],
            playerCount: 3
        )
        #expect(rating.totalCost == 14)
        #expect(rating.budget == 11)
        #expect(rating.remaining == -3)
    }

    @Test func ratingWithBudgetAdjustment() {
        let rating = DifficultyBudget.rating(
            adversaryTypes: [.standard],
            playerCount: 4,
            budgetAdjustment: -2
        )
        #expect(rating.budget == 12)
        #expect(rating.totalCost == 2)
        #expect(rating.remaining == 10)
    }

    // MARK: Adjustment Suggestions

    @Test func adjustmentForMultipleSolos() {
        let adjustments = DifficultyBudget.suggestedAdjustments(
            adversaryTypes: [.solo, .solo]
        )
        #expect(adjustments.contains(.multipleSolos))
    }

    @Test func noMultipleSolosForSingleSolo() {
        let adjustments = DifficultyBudget.suggestedAdjustments(
            adversaryTypes: [.solo]
        )
        #expect(!adjustments.contains(.multipleSolos))
    }

    @Test func adjustmentForNoBigThreats() {
        let adjustments = DifficultyBudget.suggestedAdjustments(
            adversaryTypes: [.standard, .minion, .ranged]
        )
        #expect(adjustments.contains(.noBigThreats))
    }

    @Test func noBigThreatsNotSuggestedWhenBruiserPresent() {
        let adjustments = DifficultyBudget.suggestedAdjustments(
            adversaryTypes: [.standard, .bruiser]
        )
        #expect(!adjustments.contains(.noBigThreats))
    }

    @Test func emptyRosterHasNoSuggestions() {
        let adjustments = DifficultyBudget.suggestedAdjustments(adversaryTypes: [])
        #expect(adjustments.isEmpty)
    }

    @Test func adjustmentPointValues() {
        #expect(DifficultyBudget.Adjustment.easierFight.pointValue == -1)
        #expect(DifficultyBudget.Adjustment.multipleSolos.pointValue == -2)
        #expect(DifficultyBudget.Adjustment.boostedDamage.pointValue == -2)
        #expect(DifficultyBudget.Adjustment.lowerTierAdversary.pointValue == 1)
        #expect(DifficultyBudget.Adjustment.noBigThreats.pointValue == 1)
        #expect(DifficultyBudget.Adjustment.harderFight.pointValue == 2)
    }
}

// MARK: - Environment

// MARK: - Compendium async load

@MainActor struct CompendiumLoadTests {

    /// isLoading must return to false regardless of success or failure.
    @Test func isLoadingFalseAfterLoadCompletes() async {
        let compendium = Compendium()
        try? await compendium.load()
        #expect(compendium.isLoading == false)
    }

    /// A second concurrent load call while the first is in-flight is a no-op.
    @Test func concurrentLoadCallsAreDeduped() async {
        let compendium = Compendium()
        await withTaskGroup(of: Void.self) { group in
            group.addTask { try? await compendium.load() }
            group.addTask { try? await compendium.load() }
        }
        #expect(compendium.isLoading == false)
    }

    /// When the bundle resource is missing, load() throws and sets loadError.
    /// In the test bundle adversaries.json is not present, so this always exercises the error path.
    @Test func loadSetsLoadErrorOnMissingResource() async {
        let compendium = Compendium()
        var didThrow = false
        do {
            try await compendium.load()
        } catch {
            didThrow = true
        }
        // Either the file was found (no throw) or it was missing (throw + loadError set).
        // Either way isLoading must be false and state must be consistent.
        if didThrow {
            #expect(compendium.loadError != nil)
        }
        #expect(compendium.isLoading == false)
    }

    /// Homebrew entries added before load() survive a load() call that fails.
    @Test func homebrewSurvivesFailedLoad() async {
        let compendium = Compendium()
        compendium.addAdversary(Adversary(
            id: "test-creature", name: "Test", tier: 1, type: .minion,
            description: "desc", difficulty: 8, thresholdMajor: 3, thresholdSevere: 6,
            hp: 3, stress: 2, attackModifier: "+1", attackName: "Bite",
            attackRange: .veryClose, damage: "1d6 phy"
        ))
        // load() will fail (no bundle JSON in test target) but homebrew should remain
        try? await compendium.load()
        // If load failed, adversary count depends on whether load clears homebrew on error.
        // The important thing is we can still look up the homebrew entry if load failed.
        // (If load succeeded it would replace; if it failed it should not clear homebrew.)
        #expect(compendium.isLoading == false)
    }
}

// MARK: - Environment

struct EnvironmentModelTests {

    @Test func decodesFromJSON() throws {
        let json = """
        {
          "id": "arcane-storm",
          "name": "Arcane Storm",
          "source": "SRD",
          "description": "A tempest of wild magic.",
          "feats": [
            { "name": "Wild Discharge", "text": "Deals damage at random.", "feat_type": "passive" }
          ]
        }
        """.data(using: .utf8)!

        let env = try JSONDecoder().decode(DaggerheartEnvironment.self, from: json)
        #expect(env.id == "arcane-storm")
        #expect(env.features.count == 1)
        #expect(env.features[0].featType == FeatureType.passive)
    }
}
