//
//  AdversaryFilterBarTests.swift
//  EncounterTests
//

import DHModels
import Testing

@testable import Encounter

@Suite("[Adversary].filtered")
struct AdversaryFilterBarTests {

  private let goblinMinion = Adversary(
    id: "goblin", name: "Goblin", tier: 1, role: .minion,
    flavorText: "", difficulty: 8,
    thresholdMajor: 4, thresholdSevere: 8, hp: 3, stress: 2,
    attackModifier: "+1", attackName: "Club", attackRange: .melee, damage: "1d4 phy")

  private let orcBruiser = Adversary(
    id: "orc-bruiser", name: "Orc Bruiser", tier: 2, role: .bruiser,
    flavorText: "", difficulty: 14,
    thresholdMajor: 10, thresholdSevere: 20, hp: 8, stress: 4,
    attackModifier: "+5", attackName: "Greataxe", attackRange: .melee, damage: "2d8+4 phy")

  private let shadowSkulk = Adversary(
    id: "shadow-skulk", name: "Shadow Skulk", tier: 1, role: .skulk,
    flavorText: "", difficulty: 10,
    thresholdMajor: 5, thresholdSevere: 10, hp: 4, stress: 2,
    attackModifier: "+3", attackName: "Shadow Strike", attackRange: .close, damage: "1d6+2 phy")

  private var all: [Adversary] { [goblinMinion, orcBruiser, shadowSkulk] }

  // MARK: - Search text

  @Test func emptySearchReturnsAll() {
    let result = all.filtered(searchText: "", tier: nil, type: nil)
    #expect(result.count == 3)
  }

  @Test func searchTextFiltersName() {
    let result = all.filtered(searchText: "Goblin", tier: nil, type: nil)
    #expect(result.map(\.id) == ["goblin"])
  }

  @Test func searchTextIsCaseInsensitive() {
    let result = all.filtered(searchText: "goblin", tier: nil, type: nil)
    #expect(result.map(\.id) == ["goblin"])
  }

  @Test func searchTextIsPartialMatch() {
    let result = all.filtered(searchText: "shadow", tier: nil, type: nil)
    #expect(result.map(\.id) == ["shadow-skulk"])
  }

  // MARK: - Tier filter

  @Test func nilTierReturnsAll() {
    // nil tier does not filter; type=.bruiser confirms orcBruiser (tier 2) is not excluded
    let result = all.filtered(searchText: "", tier: nil, type: .bruiser)
    #expect(result.map(\.id) == ["orc-bruiser"])
  }

  @Test func tierFilterIncludesOnlyMatchingTier() {
    let result = all.filtered(searchText: "", tier: 1, type: nil)
    #expect(result.map(\.id).sorted() == ["goblin", "shadow-skulk"])
  }

  @Test func tierFilterExcludesNonMatchingTier() {
    let result = all.filtered(searchText: "", tier: 3, type: nil)
    #expect(result.isEmpty)
  }

  // MARK: - Type filter

  @Test func nilTypeReturnsAll() {
    // nil type does not filter; tier=1 confirms both tier-1 types are returned
    let result = all.filtered(searchText: "", tier: 1, type: nil)
    #expect(result.map(\.id).sorted() == ["goblin", "shadow-skulk"])
  }

  @Test func typeFilterIncludesOnlyMatchingType() {
    let result = all.filtered(searchText: "", tier: nil, type: .minion)
    #expect(result.map(\.id) == ["goblin"])
  }

  @Test func typeFilterExcludesNonMatchingType() {
    let result = all.filtered(searchText: "", tier: nil, type: .solo)
    #expect(result.isEmpty)
  }

  // MARK: - AND composition

  @Test func searchAndTierComposeWithAND() {
    // Both goblin and shadow-skulk are tier 1; only goblin matches "Goblin"
    let result = all.filtered(searchText: "Goblin", tier: 1, type: nil)
    #expect(result.map(\.id) == ["goblin"])
  }

  @Test func searchAndTypeComposeWithAND() {
    let result = all.filtered(searchText: "o", tier: nil, type: .bruiser)
    #expect(result.map(\.id) == ["orc-bruiser"])
  }

  @Test func allThreeFiltersComposeWithAND() {
    // "o" matches all three adversaries; tier 1 narrows to goblin + shadow-skulk;
    // type .minion eliminates shadow-skulk — each filter contributes.
    let result = all.filtered(searchText: "o", tier: 1, type: .minion)
    #expect(result.map(\.id) == ["goblin"])
  }

  @Test func composedFiltersYieldEmptyWhenNoMatch() {
    let result = all.filtered(searchText: "Goblin", tier: 2, type: .minion)
    #expect(result.isEmpty)
  }

  // MARK: - Edge cases

  @Test func emptyArrayReturnsEmpty() {
    let result = [Adversary]().filtered(searchText: "Goblin", tier: 1, type: .minion)
    #expect(result.isEmpty)
  }

  @Test func whitespaceSearchReturnsEmpty() {
    // Whitespace is treated as a non-empty search string — no results
    let result = all.filtered(searchText: "   ", tier: nil, type: nil)
    #expect(result.isEmpty)
  }

  @Test func multiWordSearchMatchesFullName() {
    let result = all.filtered(searchText: "Orc Bruiser", tier: nil, type: nil)
    #expect(result.map(\.id) == ["orc-bruiser"])
  }
}
