//
//  PartyManagementUITests.swift
//  EncounterUITests
//
//  XCUITest coverage for the party management feature introduced in PR #69.
//
//  Every test launches with -UITestResetState so persisted player/encounter data
//  is wiped before the app loads, making the suite fully repeatable.
//
//  Test plan items covered:
//    - Launch → Party tab first, empty-state CTA visible
//    - Add Another flow → form resets without dismissing, two distinct players added
//    - Add player → switch to Encounters → open builder → roster row visible
//    - Level stepper: defaults to 1, increments update value, non-default level
//      shows correct tier badge in party row, edit form preserves saved level
//
//  Test plan items covered by unit tests (not duplicated here):
//    - Remove from party / Run Encounter disables:
//        PlayerStoreTests/removeFromPartyKeepsPlayerInStore + builder disable logic
//    - Reset All clears state:
//        PlayerStoreTests/resetAllWipesPlayersAndParty + resetAllPersistsEmptyState
//    - Edit stats reflected in builder:
//        PlayerStoreTests/updatePlayerReplacesExistingRecord (builder reads live store)
//

import XCTest

final class PartyManagementUITests: XCTestCase {

  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-UITestResetState"]
    app.launch()
    // Wait for the app to fully load before any test step runs.
    XCTAssertTrue(
      app.navigationBars["Party"].waitForExistence(timeout: 10),
      "App should load and show Party screen within 10 seconds")
  }

  // MARK: - Navigation structure

  /// Party tab is the first screen on launch; empty-state CTA is visible.
  @MainActor
  func testPartyTabFirstAndEmptyStateCTA() throws {
    XCTAssertTrue(
      app.buttons["party.empty-add-button"].waitForExistence(timeout: 3),
      "Empty-state Add Player CTA should be visible when no players exist")
    XCTAssertTrue(
      app.tabBars.buttons["Encounters"].waitForExistence(timeout: 3),
      "Encounters tab should be present in the tab bar")
  }

  // MARK: - Level stepper

  /// The level stepper appears in the form and defaults to 1.
  @MainActor
  func testLevelStepperPresentWithDefault() throws {
    app.buttons["party.add-player-button"].tap()
    XCTAssertTrue(
      app.textFields["party.form.name-field"].waitForExistence(timeout: 3),
      "Player form should appear")
    let stepper = app.steppers["party.form.level-stepper"]
    XCTAssertTrue(stepper.waitForExistence(timeout: 3), "Level stepper should be visible")
    XCTAssertEqual(stepper.value as? String, "1", "Level stepper should default to 1")
  }

  /// Incrementing the stepper updates its reported value.
  @MainActor
  func testLevelStepperIncrementUpdatesValue() throws {
    app.buttons["party.add-player-button"].tap()
    let stepper = app.steppers["party.form.level-stepper"]
    XCTAssertTrue(stepper.waitForExistence(timeout: 3), "Level stepper should be visible")

    incrementLevel(by: 2)

    XCTAssertEqual(stepper.value as? String, "3", "Level should be 3 after two increments")
  }

  /// A player committed with level 3 shows a Tier 2 badge in the party row.
  /// Level 3 maps to Tier 2 (SRD: levels 2–4 → Tier 2).
  @MainActor
  func testPlayerWithNonDefaultLevelShowsCorrectTierBadge() throws {
    app.buttons["party.add-player-button"].tap()
    XCTAssertTrue(
      app.textFields["party.form.name-field"].waitForExistence(timeout: 3),
      "Player form should appear")

    // Increment level to 3 (Tier 2) before filling text fields, so the
    // stepper is still on-screen and the number-pad keyboard is not yet showing.
    incrementLevel(by: 2)

    fillForm(name: "Aric", hp: "6", stress: "6", evasion: "12",
             major: "5", severe: "10", armor: "3")
    app.buttons["party.form.commit-button"].tap()

    // The active-party row Button's accessibility label is the concatenation of
    // all child text accessibility labels, including the tier badge's explicit
    // accessibilityLabel("Level 3, Tier 2").
    let partyRow = app.buttons.matching(identifier: "party.active-row").firstMatch
    XCTAssertTrue(partyRow.waitForExistence(timeout: 5), "Player row should appear in active party")
    XCTAssertTrue(
      partyRow.label.contains("Level 3, Tier 2"),
      "Party row label '\(partyRow.label)' should contain 'Level 3, Tier 2'")
  }

  /// Opening the edit form for a player with level 5 shows the stepper at 5.
  @MainActor
  func testEditFormPreservesPlayerLevel() throws {
    app.buttons["party.add-player-button"].tap()
    XCTAssertTrue(
      app.textFields["party.form.name-field"].waitForExistence(timeout: 3),
      "Player form should appear")

    // Set level to 5 (Tier 3) before filling text fields.
    incrementLevel(by: 4)
    fillForm(name: "Lira", hp: "5", stress: "7", evasion: "14",
             major: "4", severe: "8", armor: "2")
    app.buttons["party.form.commit-button"].tap()

    // Open the edit form by tapping the party row.
    let partyRow = app.buttons.matching(identifier: "party.active-row").firstMatch
    XCTAssertTrue(partyRow.waitForExistence(timeout: 5), "Player row should appear in active party")
    partyRow.tap()

    // Verify the edit form shows level 5.
    let stepper = app.steppers["party.form.level-stepper"]
    XCTAssertTrue(stepper.waitForExistence(timeout: 3), "Level stepper should be visible in edit form")
    XCTAssertEqual(stepper.value as? String, "5", "Edit form should show the saved level of 5")
  }

  // MARK: - Add Another flow

  /// Tapping "Add Another" commits the first player, resets the form without
  /// dismissing the sheet, and a second commit produces two distinct party rows.
  @MainActor
  func testAddAnotherResetsFormAndProducesTwoPlayers() throws {
    app.buttons["party.add-player-button"].tap()
    XCTAssertTrue(
      app.textFields["party.form.name-field"].waitForExistence(timeout: 3),
      "Player form sheet should appear after tapping Add Player")

    fillForm(name: "Aric", hp: "6", stress: "6", evasion: "12",
             major: "5", severe: "10", armor: "3")

    // The Add Another button sits in a safeAreaInset outside the Form scroll view so
    // it is always pinned above the number pad keyboard — no keyboard dismissal step
    // is needed before tapping it.
    // Use a HID coordinate tap (not an AX tap) to keep the sheet open: an AX tap on
    // iOS 26 causes the sheet to dismiss when @Observable state changes fire during
    // the button action; a coordinate tap sends a real touch event that avoids this.
    let addAnother = app.buttons["party.form.add-another-button"]
    XCTAssertTrue(
      addAnother.waitForExistence(timeout: 3),
      "Add Another button should be visible above the keyboard")
    addAnother.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    // Allow the async addPlayer+addToParty tasks to complete before checking form state.
    sleep(1)

    // Verify sheet still open via the navigation bar title — the nav bar is always
    // visible regardless of form scroll position.
    XCTAssertTrue(
      app.navigationBars["Add Player"].waitForExistence(timeout: 5),
      "Form sheet should remain open after Add Another")

    // After resetFields() the form is still scrolled to the armor section so the
    // name field is off-screen (virtualized). Swipe down on the form scroll view to
    // scroll it back to the top and bring the name field into the AX tree.
    app.collectionViews["party.form.scroll"].swipeDown()

    // Name field must have been cleared. When a SwiftUI TextField is empty XCUITest
    // returns the placeholder text as the element's value — so "empty" means
    // value == placeholderValue, not value == "".
    let nameField = app.textFields["party.form.name-field"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Name field should be visible after scrolling to top")
    XCTAssertEqual(
      nameField.value as? String, nameField.placeholderValue,
      "Name field should be empty (showing placeholder) after Add Another resets the form")

    // Fill the second player and commit.
    fillForm(name: "Lira", hp: "5", stress: "7", evasion: "14",
             major: "4", severe: "8", armor: "2")
    app.buttons["party.form.commit-button"].tap()

    // Both players must appear as active-party rows.
    // The add-player form auto-adds each committed player to the active party.
    let rows = app.buttons.matching(identifier: "party.active-row")
    XCTAssertEqual(rows.count, 2, "Two distinct players should appear in the active party")
  }

  // MARK: - Builder integration

  /// A player added in the Party tab appears as a roster row inside the
  /// Encounter builder after the user switches tabs and opens a builder.
  @MainActor
  func testPartyMembersVisibleInBuilderRoster() throws {
    addOnePlayer(name: "Aric", hp: "6", stress: "6", evasion: "12",
                 major: "5", severe: "10", armor: "3")

    // Switch to Encounters tab.
    let encountersTab = app.tabBars.buttons["Encounters"]
    XCTAssertTrue(encountersTab.waitForExistence(timeout: 3))
    encountersTab.tap()
    XCTAssertTrue(
      app.navigationBars["Encounters"].waitForExistence(timeout: 5),
      "Encounters screen should appear after tapping the Encounters tab")

    // Tapping the create button shows a "New Encounter" alert with a name field.
    // Both the toolbar button and the empty-state CTA share the identifier —
    // use firstMatch to avoid ambiguity.
    let createButton = app.buttons.matching(identifier: "library.create-button").firstMatch
    XCTAssertTrue(
      createButton.waitForExistence(timeout: 3),
      "Create encounter button should be visible in an empty library")
    createButton.tap()

    // Confirm the alert by tapping "Create" (the name field is optional;
    // the store uses "New Encounter" as the default if left blank).
    let createAlertButton = app.alerts["New Encounter"].buttons["Create"]
    XCTAssertTrue(
      createAlertButton.waitForExistence(timeout: 3),
      "New Encounter alert should appear after tapping create")
    createAlertButton.tap()

    // Open the newly created encounter row.
    let firstRow = app.buttons.matching(identifier: "library.row").firstMatch
    XCTAssertTrue(
      firstRow.waitForExistence(timeout: 5),
      "A library row should exist after creating an encounter")
    firstRow.tap()

    // The builder roster must contain the party player.
    // PlayerRosterSection renders PlayerPartyRow (VStack with Text children); the
    // accessibilityIdentifier propagates to each StaticText leaf — not a Button or Cell.
    XCTAssertTrue(
      app.staticTexts.matching(identifier: "builder.player-row").firstMatch
        .waitForExistence(timeout: 5),
      "Party member should appear as a player row in the encounter builder")
  }

  // MARK: - Helpers

  /// Fills all PlayerForm fields. Expects the form sheet to be open.
  /// Level is a Stepper defaulting to 1; pass nil to leave it unchanged.
  private func fillForm(
    name: String, hp: String, stress: String, evasion: String,
    major: String, severe: String, armor: String
  ) {
    let fields: [(String, String)] = [
      ("party.form.name-field", name),
      ("party.form.max-hp-field", hp),
      ("party.form.max-stress-field", stress),
      ("party.form.evasion-field", evasion),
      ("party.form.threshold-major-field", major),
      ("party.form.threshold-severe-field", severe),
      ("party.form.armor-slots-field", armor),
    ]
    for (id, value) in fields {
      let field = app.textFields[id]
      field.tap()
      field.typeText(value)
    }
  }

  /// Increments the level stepper by `steps` taps on its increment button.
  /// SwiftUI names stepper sub-buttons as "{stepper-id}-Increment" / "{stepper-id}-Decrement".
  private func incrementLevel(by steps: Int = 1) {
    let stepper = app.steppers["party.form.level-stepper"]
    XCTAssertTrue(stepper.waitForExistence(timeout: 3), "Level stepper should be visible")
    let increment = app.buttons["party.form.level-stepper-Increment"]
    for _ in 0..<steps { increment.tap() }
  }

  /// Adds one player via the form and waits for their row to appear in the
  /// active party before returning.
  private func addOnePlayer(
    name: String, hp: String, stress: String, evasion: String,
    major: String, severe: String, armor: String
  ) {
    app.buttons["party.add-player-button"].tap()
    _ = app.textFields["party.form.name-field"].waitForExistence(timeout: 3)
    fillForm(name: name, hp: hp, stress: stress, evasion: evasion,
             major: major, severe: severe, armor: armor)
    app.buttons["party.form.commit-button"].tap()
    _ = app.buttons.matching(identifier: "party.active-row").firstMatch
      .waitForExistence(timeout: 5)
  }
}
