//
//  AdversaryFilterBarTests.swift
//  EncounterTests
//

import DHModels
import Testing

@testable import Encounter

@MainActor
@Suite("AdversaryFilterBar.filter")
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
    let result = AdversaryFilterBar.filter(all, searchText: "", tier: nil, type: nil)
    #expect(result.count == 3)
  }

  @Test func searchTextFiltersName() {
    let result = AdversaryFilterBar.filter(all, searchText: "Goblin", tier: nil, type: nil)
    #expect(result.map(\.id) == ["goblin"])
  }

  @Test func searchTextIsCaseInsensitive() {
    let result = AdversaryFilterBar.filter(all, searchText: "goblin", tier: nil, type: nil)
    #expect(result.map(\.id) == ["goblin"])
  }

  @Test func searchTextIsPartialMatch() {
    let result = AdversaryFilterBar.filter(all, searchText: "shadow", tier: nil, type: nil)
    #expect(result.map(\.id) == ["shadow-skulk"])
  }

  // MARK: - Tier filter

  @Test func nilTierReturnsAll() {
    let result = AdversaryFilterBar.filter(all, searchText: "", tier: nil, type: nil)
    #expect(result.count == 3)
  }

  @Test func tierFilterIncludesOnlyMatchingTier() {
    let result = AdversaryFilterBar.filter(all, searchText: "", tier: 1, type: nil)
    #expect(result.map(\.id).sorted() == ["goblin", "shadow-skulk"])
  }

  @Test func tierFilterExcludesNonMatchingTier() {
    let result = AdversaryFilterBar.filter(all, searchText: "", tier: 3, type: nil)
    #expect(result.isEmpty)
  }

  // MARK: - Type filter

  @Test func nilTypeReturnsAll() {
    let result = AdversaryFilterBar.filter(all, searchText: "", tier: nil, type: nil)
    #expect(result.count == 3)
  }

  @Test func typeFilterIncludesOnlyMatchingType() {
    let result = AdversaryFilterBar.filter(all, searchText: "", tier: nil, type: .minion)
    #expect(result.map(\.id) == ["goblin"])
  }

  @Test func typeFilterExcludesNonMatchingType() {
    let result = AdversaryFilterBar.filter(all, searchText: "", tier: nil, type: .solo)
    #expect(result.isEmpty)
  }

  // MARK: - AND composition

  @Test func searchAndTierComposeWithAND() {
    // Both goblin and shadow-skulk are tier 1; only goblin matches "Goblin"
    let result = AdversaryFilterBar.filter(all, searchText: "Goblin", tier: 1, type: nil)
    #expect(result.map(\.id) == ["goblin"])
  }

  @Test func searchAndTypeComposeWithAND() {
    // Both goblin and orc-bruiser could match "o"; only orc-bruiser is .bruiser
    let result = AdversaryFilterBar.filter(all, searchText: "o", tier: nil, type: .bruiser)
    #expect(result.map(\.id) == ["orc-bruiser"])
  }

  @Test func allThreeFiltersComposeWithAND() {
    let result = AdversaryFilterBar.filter(all, searchText: "Goblin", tier: 1, type: .minion)
    #expect(result.map(\.id) == ["goblin"])
  }

  @Test func composedFiltersYieldEmptyWhenNoMatch() {
    let result = AdversaryFilterBar.filter(all, searchText: "Goblin", tier: 2, type: .minion)
    #expect(result.isEmpty)
  }
}
