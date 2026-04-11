//
//  RenameAdversaryUITests.swift
//  EncounterUITests
//
//  Covers the PR #76 test plan: editable adversary name in runner.
//  Items verified:
//   1. Tap name in expanded card → TextField appears pre-filled
//   2. Type unique name, tap Done → card and collapsed row both update
//   3. Press Return → same as Done
//   4. Type name already in use → inline error appears
//   5. Clear field, tap Done → silently reverts
//   6. Tap Cancel → reverts without error
//   7. Collapse button accessible in normal (non-editing) state
//

import XCTest

final class RenameAdversaryUITests: XCTestCase {

  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-UITestResetState"]
    app.launch()
    XCTAssertTrue(
      app.navigationBars["Party"].waitForExistence(timeout: 10),
      "App should load and show Party screen")
  }

  // MARK: - Test Plan Item 7: Collapse button accessible in normal state

  func testCollapseButtonAccessibleBeforeEditing() {
    navigateToRunner()
    expandFirstCard()

    let collapseButton = app.buttons["runner.adversary-card.collapse-button"]
    XCTAssertTrue(
      collapseButton.waitForExistence(timeout: 3),
      "Collapse button should be visible in the card header")
    XCTAssertTrue(collapseButton.isHittable, "Collapse button should be tappable")
  }

  // MARK: - Test Plan Item 1: Tap name → TextField appears pre-filled

  func testTapNameShowsPrefilledTextField() {
    navigateToRunner()
    expandFirstCard()

    let nameButton = app.buttons["runner.adversary-card.name"]
    XCTAssertTrue(nameButton.waitForExistence(timeout: 3), "Name button should be visible")
    let preFilled = nameButton.label
    XCTAssertFalse(preFilled.isEmpty, "Name button should have a non-empty label")

    nameButton.tap()

    let nameField = app.textFields["runner.adversary-card.name-field"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Name field should appear")
    XCTAssertEqual(
      nameField.value as? String, preFilled,
      "Name field should be pre-filled with the current name")
  }

  // MARK: - Test Plan Item 2: Unique rename → Done → both views update

  func testRenameViaDonenButtonUpdatesDisplay() {
    navigateToRunner()
    expandFirstCard()

    app.buttons["runner.adversary-card.name"].tap()

    let nameField = app.textFields["runner.adversary-card.name-field"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 2))
    replaceText(in: nameField, with: "Grimfang")

    app.buttons["Done"].firstMatch.tap()

    // Card header should show the new name
    let nameButton = app.buttons["runner.adversary-card.name"]
    XCTAssertTrue(nameButton.waitForExistence(timeout: 2))
    XCTAssertEqual(nameButton.label, "Grimfang", "Card header should show new name")

    // Collapsed row label also updates (collapse first to expose the row)
    app.buttons["runner.adversary-card.collapse-button"].tap()
    let row = app.buttons.matching(identifier: "runner.adversary-row").firstMatch
    XCTAssertTrue(row.waitForExistence(timeout: 2))
    XCTAssertEqual(row.label, "Grimfang", "Collapsed row accessibility label should show new name")
  }

  // MARK: - Test Plan Item 3: Return key commits rename

  func testReturnKeyCommitsRename() {
    navigateToRunner()
    expandFirstCard()

    app.buttons["runner.adversary-card.name"].tap()

    let nameField = app.textFields["runner.adversary-card.name-field"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 2))
    replaceText(in: nameField, with: "Shadowclaw")

    nameField.typeText("\n")

    // Editing mode should exit and name should update
    let nameButton = app.buttons["runner.adversary-card.name"]
    XCTAssertTrue(nameButton.waitForExistence(timeout: 2))
    XCTAssertEqual(nameButton.label, "Shadowclaw", "Return key should commit the rename")
  }

  // MARK: - Test Plan Item 5: Clear field → Done → silent revert

  func testEmptyFieldReverts() {
    navigateToRunner()
    expandFirstCard()

    let nameButton = app.buttons["runner.adversary-card.name"]
    XCTAssertTrue(nameButton.waitForExistence(timeout: 3))
    let originalName = nameButton.label

    nameButton.tap()

    let nameField = app.textFields["runner.adversary-card.name-field"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 2))
    replaceText(in: nameField, with: "")  // clear to empty

    app.buttons["Done"].firstMatch.tap()

    // Editing exits, name reverts to original
    let nameButtonAfter = app.buttons["runner.adversary-card.name"]
    XCTAssertTrue(nameButtonAfter.waitForExistence(timeout: 2))
    XCTAssertEqual(
      nameButtonAfter.label, originalName,
      "Empty commit should revert to original name")

    // No error should remain
    XCTAssertFalse(
      app.staticTexts["runner.adversary-card.name-error"].exists,
      "No error should appear for empty-field revert")
  }

  // MARK: - Test Plan Item 6: Cancel → reverts without error

  func testCancelReverts() {
    navigateToRunner()
    expandFirstCard()

    let nameButton = app.buttons["runner.adversary-card.name"]
    XCTAssertTrue(nameButton.waitForExistence(timeout: 3))
    let originalName = nameButton.label

    nameButton.tap()

    let nameField = app.textFields["runner.adversary-card.name-field"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 2))
    replaceText(in: nameField, with: "SomethingElse")

    app.buttons["Cancel"].firstMatch.tap()

    let nameButtonAfter = app.buttons["runner.adversary-card.name"]
    XCTAssertTrue(nameButtonAfter.waitForExistence(timeout: 2))
    XCTAssertEqual(nameButtonAfter.label, originalName, "Cancel should revert to original name")
    XCTAssertFalse(
      app.staticTexts["runner.adversary-card.name-error"].exists,
      "No error should appear after Cancel")
  }

  // MARK: - Test Plan Item 4: Duplicate name → inline error

  func testDuplicateNameShowsError() {
    navigateToRunnerWithTwoSameAdversaries()

    // Both adversary rows should be present
    let rows = app.buttons.matching(identifier: "runner.adversary-row")
    XCTAssertTrue(
      rows.element(boundBy: 1).waitForExistence(timeout: 5), "Two adversary rows expected")

    // Get the second slot's display name (its accessibility label = customName)
    let secondSlotName = rows.element(boundBy: 1).label

    // Expand the first row
    rows.firstMatch.tap()

    let nameButton = app.buttons["runner.adversary-card.name"]
    XCTAssertTrue(nameButton.waitForExistence(timeout: 3))
    nameButton.tap()

    let nameField = app.textFields["runner.adversary-card.name-field"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 2))
    replaceText(in: nameField, with: secondSlotName)

    app.buttons["Done"].firstMatch.tap()

    // Error label should appear inline
    let errorLabel = app.staticTexts["runner.adversary-card.name-error"]
    XCTAssertTrue(errorLabel.waitForExistence(timeout: 2), "Inline error should appear")
    XCTAssertEqual(errorLabel.label, "Name already in use")

    // TextField should still be visible (edit mode persists)
    XCTAssertTrue(
      app.textFields["runner.adversary-card.name-field"].exists,
      "Name field should stay visible after rejected rename")
  }

  // MARK: - Navigation helpers

  /// Navigate to the live runner with one adversary and one player.
  private func navigateToRunner() {
    addOnePlayer()
    switchToEncountersTab()
    createEncounter()
    openFirstEncounter()
    addAdversaryFromCompendium()
    tapRunEncounter()
  }

  /// Navigate to the live runner with two copies of the same adversary,
  /// so both slots get auto-assigned customNames ("Name 1", "Name 2").
  private func navigateToRunnerWithTwoSameAdversaries() {
    addOnePlayer()
    switchToEncountersTab()
    createEncounter()
    openFirstEncounter()
    addAdversaryFromCompendium()  // adds first copy, sheet auto-closes
    addAdversaryFromCompendium()  // adds same (first) adversary again
    tapRunEncounter()
  }

  private func addOnePlayer() {
    app.buttons["party.add-player-button"].tap()
    XCTAssertTrue(app.textFields["party.form.name-field"].waitForExistence(timeout: 3))
    fillPlayerForm(
      name: "Aric", hp: "6", stress: "6", evasion: "12",
      major: "5", severe: "10", armor: "3")
    app.buttons["party.form.commit-button"].tap()
    XCTAssertTrue(
      app.buttons.matching(identifier: "party.active-row").firstMatch
        .waitForExistence(timeout: 5))
  }

  private func switchToEncountersTab() {
    let tab = app.tabBars.buttons["Encounters"]
    XCTAssertTrue(tab.waitForExistence(timeout: 3))
    tab.tap()
    XCTAssertTrue(app.navigationBars["Encounters"].waitForExistence(timeout: 5))
  }

  private func createEncounter() {
    let createButton = app.buttons.matching(identifier: "library.create-button").firstMatch
    XCTAssertTrue(createButton.waitForExistence(timeout: 3))
    createButton.tap()
    let confirm = app.alerts["New Encounter"].buttons["Create"]
    XCTAssertTrue(confirm.waitForExistence(timeout: 3))
    confirm.tap()
  }

  private func openFirstEncounter() {
    let row = app.buttons.matching(identifier: "library.row").firstMatch
    XCTAssertTrue(row.waitForExistence(timeout: 5))
    row.tap()
  }

  /// Opens the compendium, taps the first adversary, adds it to the encounter,
  /// and waits for the sheet to dismiss (auto-dismissed by showCompendium = false).
  private func addAdversaryFromCompendium() {
    let browseButton = app.buttons["builder.browse-compendium-button"]
    XCTAssertTrue(browseButton.waitForExistence(timeout: 5))
    browseButton.tap()

    let firstRow = app.buttons.matching(identifier: "compendium.adversary-row").firstMatch
    XCTAssertTrue(firstRow.waitForExistence(timeout: 5))
    firstRow.tap()

    let addButton = app.buttons["compendium.add-to-encounter-button"]
    XCTAssertTrue(addButton.waitForExistence(timeout: 5))
    addButton.tap()

    // Sheet auto-dismisses (showCompendium = false in onSelect closure).
    // Wait for browse button to reappear as confirmation.
    XCTAssertTrue(
      browseButton.waitForExistence(timeout: 5), "Builder should be visible after sheet dismisses")
  }

  private func tapRunEncounter() {
    let runButton = app.buttons["builder.run-button"]
    XCTAssertTrue(runButton.waitForExistence(timeout: 5))
    XCTAssertTrue(runButton.isEnabled, "Run button should be enabled")
    runButton.tap()
    XCTAssertTrue(
      app.collectionViews["runner.adversary-list"].waitForExistence(timeout: 5),
      "Runner should appear")
  }

  private func expandFirstCard() {
    let row = app.buttons.matching(identifier: "runner.adversary-row").firstMatch
    XCTAssertTrue(row.waitForExistence(timeout: 5), "Adversary row should be in runner")
    row.tap()
    XCTAssertTrue(
      app.buttons["runner.adversary-card.collapse-button"].waitForExistence(timeout: 3),
      "Card should expand")
  }

  // MARK: - Text field helpers

  /// Replaces the text field's current value with `text`.
  /// Triple-taps to select all, then types the replacement (or just deletes if empty).
  private func replaceText(in field: XCUIElement, with text: String) {
    field.tap(withNumberOfTaps: 3, numberOfTouches: 1)
    if text.isEmpty {
      field.typeText(XCUIKeyboardKey.delete.rawValue)
    } else {
      field.typeText(text)
    }
  }

  // MARK: - Player form helper

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
