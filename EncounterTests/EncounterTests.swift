//
//  EncounterTests.swift
//  EncounterTests
//
//  Unit tests for Daggerheart data models.
//

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
        #expect(adversary.features[0].featType == .passive)
        #expect(adversary.features[1].featType == .reaction)
        #expect(adversary.features[2].featType == .action)
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

// MARK: - EncounterSession

struct EncounterSessionTests {

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
        #expect(env.features[0].featType == .passive)
    }
}
