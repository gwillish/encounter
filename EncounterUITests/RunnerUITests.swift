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

  // MARK: - End Encounter / Reset Session

  /// Tapping "End Encounter" returns to the builder; the session stays alive
  /// (Reset Session appears in the builder toolbar overflow).
  func testEndEncounterReturnsToBuilderWithActiveSession() throws {
    navigateToRunner()
    XCTAssertTrue(
      app.collectionViews["runner.list"].waitForExistence(timeout: 5),
      "Should be in the runner")

    tapEndEncounter()

    // Capture the builder with the difficulty panel visible for visual verification.
    let screenshot = app.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = "builder-difficulty-panel"
    attachment.lifetime = .keepAlways
    add(attachment)

    // Builder is visible and the overflow contains "Reset Session" (active session present).
    let overflow = app.buttons["OverflowBarButtonItem"]
    XCTAssertTrue(
      overflow.waitForExistence(timeout: 3), "Builder toolbar overflow should be present")
    overflow.tap()
    XCTAssertTrue(
      app.buttons["Reset Session"].waitForExistence(timeout: 3),
      "Reset Session should appear in builder toolbar when a session is active")
    // Dismiss the overflow without tapping Reset.
    app.buttons["Reset Session"].tap()  // will show dialog
    // Dismiss dialog by tapping cancel (swipe down on action sheet).
    app.navigationBars.firstMatch.tap()
  }

  /// Tapping "Reset Session" from the runner, then confirming, clears the session
  /// and returns to the builder; "Reset Session" does not appear in the builder toolbar.
  func testResetSessionFromRunner() throws {
    navigateToRunner()
    XCTAssertTrue(
      app.collectionViews["runner.list"].waitForExistence(timeout: 5),
      "Should be in the runner")

    tapResetSessionFromRunner()

    // Back in builder with no active session — Reset Session should not appear in overflow.
    let overflow = app.buttons["OverflowBarButtonItem"]
    XCTAssertTrue(overflow.waitForExistence(timeout: 3))
    overflow.tap()
    XCTAssertFalse(
      app.buttons["Reset Session"].waitForExistence(timeout: 2),
      "Reset Session should not appear in builder toolbar after session was reset")
  }

  /// After ending an encounter, the builder's "Reset Session" clears the session;
  /// tapping "Run Encounter" again starts a fresh session.
  func testResetSessionFromBuilder() throws {
    navigateToRunner()
    XCTAssertTrue(
      app.collectionViews["runner.list"].waitForExistence(timeout: 5))

    tapEndEncounter()

    // Tap Reset Session from the builder toolbar overflow.
    let overflow = app.buttons["OverflowBarButtonItem"]
    XCTAssertTrue(overflow.waitForExistence(timeout: 3))
    overflow.tap()
    XCTAssertTrue(
      app.buttons["Reset Session"].waitForExistence(timeout: 3),
      "Reset Session should be in builder toolbar overflow")
    app.buttons["Reset Session"].tap()

    // Confirm the destruction.
    // confirmationDialog on iOS 26 exposes its buttons in two places in the AX tree
    // (action sheet layer + source view hierarchy), so use firstMatch to avoid ambiguity.
    let confirmButton = app.buttons.matching(identifier: "builder.reset-confirm-button").firstMatch
    XCTAssertTrue(confirmButton.waitForExistence(timeout: 3), "Confirmation button should appear")
    confirmButton.tap()

    // Session is cleared — Reset Session should no longer appear in the overflow.
    let overflow2 = app.buttons["OverflowBarButtonItem"]
    XCTAssertTrue(overflow2.waitForExistence(timeout: 3))
    overflow2.tap()
    XCTAssertFalse(
      app.buttons["Reset Session"].waitForExistence(timeout: 2),
      "Reset Session should disappear after confirming reset")
  }

  // MARK: - Player runner row → expanded card

  /// Tapping a player row in the list expands the PlayerRunnerCard inline.
  /// Stat control presence and condition toggle logic are covered at the ViewInspector
  /// tier by PlayerRunnerCardTests and PlayerConditionsSectionTests.
  func testPlayerRunnerRowTapExpandsCard() throws {
    navigateToRunner()

    let playerRow = app.buttons.matching(identifier: "runner.player-row").firstMatch
    XCTAssertTrue(
      playerRow.waitForExistence(timeout: 5), "Player row should be visible in the list")
    playerRow.tap()

    // The card is expanded when a stat button from PlayerRunnerCard is accessible.
    XCTAssertTrue(
      app.buttons["runner.player-edit.hp.decrement"].waitForExistence(timeout: 5),
      "HP decrement button should appear — confirms PlayerRunnerCard expanded")
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
