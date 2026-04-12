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

final class RenameAdversaryUITests: EncounterUITestCase {

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

  func testRenameViaDoneButtonUpdatesDisplay() {
    navigateToRunner()
    expandFirstCard()

    app.buttons["runner.adversary-card.name"].tap()

    let nameField = app.textFields["runner.adversary-card.name-field"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 2))
    replaceText(in: nameField, with: "Grimfang")

    app.buttons["runner.adversary-card.rename-done-button"].tap()

    // Card header should show the new name.
    let nameButton = app.buttons["runner.adversary-card.name"]
    XCTAssertTrue(nameButton.waitForExistence(timeout: 2))
    XCTAssertEqual(nameButton.label, "Grimfang", "Card header should show new name")

    // Collapsed row label also updates (collapse first to expose the row).
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
    replaceText(in: nameField, with: "")

    app.buttons["runner.adversary-card.rename-done-button"].tap()

    let nameButtonAfter = app.buttons["runner.adversary-card.name"]
    XCTAssertTrue(nameButtonAfter.waitForExistence(timeout: 2))
    XCTAssertEqual(
      nameButtonAfter.label, originalName,
      "Empty commit should revert to original name")
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

    app.buttons["runner.adversary-card.rename-cancel-button"].tap()

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

    let rows = app.buttons.matching(identifier: "runner.adversary-row")
    XCTAssertTrue(
      rows.element(boundBy: 1).waitForExistence(timeout: 5), "Two adversary rows expected")

    // Get the second slot's display name (its accessibility label = customName).
    let secondSlotName = rows.element(boundBy: 1).label

    // Expand the first row.
    rows.firstMatch.tap()

    let nameButton = app.buttons["runner.adversary-card.name"]
    XCTAssertTrue(nameButton.waitForExistence(timeout: 3))
    nameButton.tap()

    let nameField = app.textFields["runner.adversary-card.name-field"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 2))
    replaceText(in: nameField, with: secondSlotName)

    app.buttons["runner.adversary-card.rename-done-button"].tap()

    let errorLabel = app.staticTexts["runner.adversary-card.name-error"]
    XCTAssertTrue(errorLabel.waitForExistence(timeout: 2), "Inline error should appear")
    XCTAssertEqual(errorLabel.label, "Name already in use")

    XCTAssertTrue(
      app.textFields["runner.adversary-card.name-field"].exists,
      "Name field should stay visible after rejected rename")
  }
}
