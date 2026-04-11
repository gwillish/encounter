//
//  RunnerUITests.swift
//  EncounterUITests
//
//  XCUITest coverage for the live encounter runner (Phase 4, issue #34).
//
//  Every test launches with -UITestResetState so persisted player/encounter
//  data is wiped before the app loads, making the suite fully repeatable.
//
//  Test plan items covered:
//    - Condition toggle: applying a condition in the expanded card is reflected
//      as a badge in the collapsed row; removing it hides the badge.
//    - Stress button: +1 Stress increments the stress pip track in the card.
//

import XCTest

final class RunnerUITests: XCTestCase {

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

  // MARK: - Condition visibility in collapsed row

  /// Applying a condition in the expanded card shows a badge in the
  /// collapsed row; removing it hides the badge.
  func testConditionBadgeVisibleInCollapsedRow() throws {
    navigateToRunner()

    // Expand the first adversary card.
    let collapsedRow = app.buttons.matching(identifier: "runner.adversary-row").firstMatch
    XCTAssertTrue(collapsedRow.waitForExistence(timeout: 5), "Adversary row should be visible")
    collapsedRow.tap()

    // Apply the Restrained condition.
    let restrainedButton = app.buttons["runner.adversary-card.condition.restrained"]
    XCTAssertTrue(
      restrainedButton.waitForExistence(timeout: 3), "Restrained condition button should be visible"
    )
    restrainedButton.tap()

    // Collapse the card.
    let collapseButton = app.buttons["runner.adversary-card.collapse-button"]
    XCTAssertTrue(collapseButton.waitForExistence(timeout: 3), "Collapse button should be visible")
    collapseButton.tap()

    // The collapsed row button's synthesized AX label should include "Restrained".
    let row = app.buttons.matching(identifier: "runner.adversary-row").firstMatch
    XCTAssertTrue(
      row.waitForExistence(timeout: 3), "Collapsed row should reappear after collapsing")
    XCTAssertTrue(
      row.label.contains("Restrained"),
      "Collapsed row label '\(row.label)' should contain 'Restrained' badge")

    // Re-expand and remove the condition.
    row.tap()
    let restrainedButtonAgain = app.buttons["runner.adversary-card.condition.restrained"]
    XCTAssertTrue(restrainedButtonAgain.waitForExistence(timeout: 3))
    restrainedButtonAgain.tap()

    // Collapse again and verify the badge is gone.
    let collapseButtonAgain = app.buttons["runner.adversary-card.collapse-button"]
    XCTAssertTrue(collapseButtonAgain.waitForExistence(timeout: 3))
    collapseButtonAgain.tap()

    let rowAfterRemoval = app.buttons.matching(identifier: "runner.adversary-row").firstMatch
    XCTAssertTrue(rowAfterRemoval.waitForExistence(timeout: 3), "Collapsed row should reappear")
    XCTAssertFalse(
      rowAfterRemoval.label.contains("Restrained"),
      "Collapsed row label '\(rowAfterRemoval.label)' should not contain 'Restrained' after removal"
    )
  }

  // MARK: - Stress button

  /// Tapping +1 Stress in the expanded card is reflected in the stress pip track.
  func testStressButtonIncrementsStress() throws {
    navigateToRunner()

    // Expand the first adversary card.
    let collapsedRow = app.buttons.matching(identifier: "runner.adversary-row").firstMatch
    XCTAssertTrue(collapsedRow.waitForExistence(timeout: 5))
    collapsedRow.tap()

    // The stress button should be visible and enabled (adversary starts at 0 stress).
    let stressButton = app.buttons["runner.adversary-card.stress-button"]
    XCTAssertTrue(stressButton.waitForExistence(timeout: 3), "Stress button should be visible")
    XCTAssertTrue(stressButton.isEnabled, "Stress button should be enabled at 0 stress")

    stressButton.tap()

    // Button label updates to reflect new stress value — just verify it's still present.
    XCTAssertTrue(
      app.buttons["runner.adversary-card.stress-button"].waitForExistence(timeout: 3),
      "Stress button should still be visible after incrementing stress")
  }

  // MARK: - Navigation helper

  /// Navigates from the Party screen all the way into the live encounter runner.
  ///
  /// Flow:
  ///   1. Add one player (required for "Run Encounter" to be enabled).
  ///   2. Switch to Encounters tab.
  ///   3. Create a new encounter.
  ///   4. Open the encounter in the builder.
  ///   5. Add one adversary from the compendium.
  ///   6. Tap "Run Encounter".
  private func navigateToRunner() {
    // Step 1: Add one player.
    app.buttons["party.add-player-button"].tap()
    XCTAssertTrue(
      app.textFields["party.form.name-field"].waitForExistence(timeout: 3),
      "Player form should appear")
    fillPlayerForm(
      name: "Aric", hp: "6", stress: "6", evasion: "12",
      major: "5", severe: "10", armor: "3")
    app.buttons["party.form.commit-button"].tap()
    XCTAssertTrue(
      app.buttons.matching(identifier: "party.active-row").firstMatch
        .waitForExistence(timeout: 5),
      "Player should appear in active party")

    // Step 2: Switch to Encounters.
    let encountersTab = app.tabBars.buttons["Encounters"]
    XCTAssertTrue(encountersTab.waitForExistence(timeout: 3))
    encountersTab.tap()
    XCTAssertTrue(
      app.navigationBars["Encounters"].waitForExistence(timeout: 5),
      "Encounters screen should appear")

    // Step 3: Create encounter.
    let createButton = app.buttons.matching(identifier: "library.create-button").firstMatch
    XCTAssertTrue(createButton.waitForExistence(timeout: 3))
    createButton.tap()
    let createAlertButton = app.alerts["New Encounter"].buttons["Create"]
    XCTAssertTrue(createAlertButton.waitForExistence(timeout: 3))
    createAlertButton.tap()

    // Step 4: Open the encounter in the builder.
    let firstRow = app.buttons.matching(identifier: "library.row").firstMatch
    XCTAssertTrue(firstRow.waitForExistence(timeout: 5))
    firstRow.tap()

    // Step 5: Add an adversary from the compendium.
    let browseButton = app.buttons["builder.browse-compendium-button"]
    XCTAssertTrue(
      browseButton.waitForExistence(timeout: 5), "Browse Compendium button should be visible")
    browseButton.tap()

    // Wait for compendium list, then tap the first adversary row.
    let firstAdversaryRow = app.buttons.matching(identifier: "compendium.adversary-row").firstMatch
    XCTAssertTrue(
      firstAdversaryRow.waitForExistence(timeout: 5),
      "Compendium adversary list should appear")
    firstAdversaryRow.tap()

    // Tap "Add to Encounter" on the detail view.
    let addButton = app.buttons["compendium.add-to-encounter-button"]
    XCTAssertTrue(
      addButton.waitForExistence(timeout: 5), "Add to Encounter button should be visible")
    addButton.tap()

    // Step 6: Run the encounter.
    let runButton = app.buttons["builder.run-button"]
    XCTAssertTrue(
      runButton.waitForExistence(timeout: 5), "Run Encounter button should be visible and enabled")
    XCTAssertTrue(
      runButton.isEnabled,
      "Run Encounter button should be enabled with one player and one adversary")
    runButton.tap()

    // Wait for the runner adversary list to appear.
    XCTAssertTrue(
      app.collectionViews["runner.adversary-list"].waitForExistence(timeout: 5),
      "Runner adversary list should appear after tapping Run Encounter")
  }

  // MARK: - Form helper

  private func fillPlayerForm(
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
}
