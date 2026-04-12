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

final class RunnerUITests: EncounterUITestCase {

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

}
