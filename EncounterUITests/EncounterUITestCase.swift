//
//  EncounterUITestCase.swift
//  EncounterUITests
//
//  Base class for Encounter UI tests. Provides shared setUp, navigation
//  helpers, and form utilities so test classes don't duplicate this logic.
//

import XCTest

class EncounterUITestCase: XCTestCase {

  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-UITestResetState"]
    app.launch()
    XCTAssertTrue(
      app.navigationBars["Party"].waitForExistence(timeout: 10),
      "App should load and show Party screen within 10 seconds")
  }

  // MARK: - Top-level navigation flows

  /// Navigates from the Party screen all the way into the live encounter runner.
  ///
  /// Flow:
  ///   1. Add one player (required for "Run Encounter" to be enabled).
  ///   2. Switch to Encounters tab.
  ///   3. Create a new encounter.
  ///   4. Open the encounter in the builder.
  ///   5. Add one adversary from the compendium.
  ///   6. Tap "Run Encounter".
  func navigateToRunner() {
    addOnePlayer()
    switchToEncountersTab()
    createEncounter()
    openFirstEncounter()
    addAdversaryFromCompendium()
    tapRunEncounter()
  }

  /// Same as `navigateToRunner`, but adds the same (first) adversary twice so
  /// both slots receive auto-assigned `customName` values ("Name 1", "Name 2").
  func navigateToRunnerWithTwoSameAdversaries() {
    addOnePlayer()
    switchToEncountersTab()
    createEncounter()
    openFirstEncounter()
    addAdversaryFromCompendium()
    addAdversaryFromCompendium()
    tapRunEncounter()
  }

  /// Expands the first adversary row in the runner.
  func expandFirstCard() {
    let row = app.buttons.matching(identifier: "runner.adversary-row").firstMatch
    XCTAssertTrue(row.waitForExistence(timeout: 5), "Adversary row should be in runner")
    row.tap()
    XCTAssertTrue(
      app.buttons["runner.adversary-card.collapse-button"].waitForExistence(timeout: 3),
      "Card should expand after tapping row")
  }

  // MARK: - Step helpers

  func addOnePlayer(
    name: String = "Aric", hp: String = "6", stress: String = "6",
    evasion: String = "12", major: String = "5", severe: String = "10", armor: String = "3"
  ) {
    app.buttons["party.add-player-button"].tap()
    XCTAssertTrue(
      app.textFields["party.form.name-field"].waitForExistence(timeout: 3),
      "Player form should appear")
    fillPlayerForm(
      name: name, hp: hp, stress: stress, evasion: evasion,
      major: major, severe: severe, armor: armor)
    app.buttons["party.form.commit-button"].tap()
    XCTAssertTrue(
      app.buttons.matching(identifier: "party.active-row").firstMatch
        .waitForExistence(timeout: 5),
      "Player should appear in active party")
  }

  func switchToEncountersTab() {
    let tab = app.tabBars.buttons["Encounters"]
    XCTAssertTrue(tab.waitForExistence(timeout: 3))
    tab.tap()
    XCTAssertTrue(
      app.navigationBars["Encounters"].waitForExistence(timeout: 5),
      "Encounters screen should appear")
  }

  func createEncounter() {
    let createButton = app.buttons.matching(identifier: "library.create-button").firstMatch
    XCTAssertTrue(createButton.waitForExistence(timeout: 3))
    createButton.tap()
    let confirm = app.alerts["New Encounter"].buttons["Create"]
    XCTAssertTrue(confirm.waitForExistence(timeout: 3))
    confirm.tap()
  }

  func openFirstEncounter() {
    let row = app.buttons.matching(identifier: "library.row").firstMatch
    XCTAssertTrue(row.waitForExistence(timeout: 5))
    row.tap()
  }

  /// Opens the compendium browser, taps the first adversary, and adds it.
  /// Uses the in-form "Add" button (builder.add-adversary-button) rather than the
  /// toolbar button, because on iOS 26 with .toolbarRole(.editor) the toolbar items
  /// collapse into an overflow "More" menu and are not directly hittable.
  /// The sheet auto-dismisses via `showCompendium = false` in the builder's `onSelect` closure.
  func addAdversaryFromCompendium() {
    let addButton = app.buttons["builder.add-adversary-button"]
    XCTAssertTrue(
      addButton.waitForExistence(timeout: 5), "Add adversary button should be visible")
    addButton.tap()

    let firstRow = app.buttons.matching(identifier: "compendium.adversary-row").firstMatch
    XCTAssertTrue(firstRow.waitForExistence(timeout: 5), "Compendium adversary list should appear")
    firstRow.tap()

    let addToEncounterButton = app.buttons["compendium.add-to-encounter-button"]
    XCTAssertTrue(
      addToEncounterButton.waitForExistence(timeout: 5), "Add to Encounter button should appear")
    addToEncounterButton.tap()

    // Sheet auto-closes; wait for the add button to confirm we're back on the builder.
    XCTAssertTrue(
      addButton.waitForExistence(timeout: 5),
      "Builder should be visible after compendium sheet dismisses")
  }

  func tapRunEncounter() {
    // On iOS 26 with .toolbarRole(.editor), the Run Encounter button is in the toolbar
    // overflow menu (OverflowBarButtonItem / "More"). Menu items lose their AX identifiers
    // and are only findable by label once the menu is open.
    let overflowButton = app.buttons["OverflowBarButtonItem"]
    XCTAssertTrue(
      overflowButton.waitForExistence(timeout: 5), "Toolbar overflow button should be visible")
    overflowButton.tap()

    let runButton = app.buttons["Run Encounter"]
    XCTAssertTrue(
      runButton.waitForExistence(timeout: 3), "Run Encounter button should appear in overflow menu")
    XCTAssertTrue(runButton.isEnabled, "Run Encounter button should be enabled")
    runButton.tap()
    XCTAssertTrue(
      app.collectionViews["runner.adversary-list"].waitForExistence(timeout: 5),
      "Runner adversary list should appear")
  }

  // MARK: - Form helpers

  func fillPlayerForm(
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

  /// Replaces the text field's current value with `text`.
  /// Selects all existing text, then types the replacement (or deletes if empty).
  func replaceText(in field: XCUIElement, with text: String) {
    #if os(iOS)
      // Triple-tap selects all text in a UITextField. Works whether the field is
      // already focused (via @FocusState) or not — no prior single-tap needed.
      field.tap(withNumberOfTaps: 3, numberOfTouches: 1)
    #else
      field.tap()
      field.typeKey("a", modifierFlags: .command)
    #endif
    if text.isEmpty {
      field.typeText(XCUIKeyboardKey.delete.rawValue)
    } else {
      field.typeText(text)
    }
  }
}
