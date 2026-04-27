//
//  ExplorationScreenshotTests.swift
//  EncounterUITests
//
//  Screenshot tests for all exploration harness scenes.
//  Navigates to each scene via accessibilityIdentifier and attaches a
//  full-screen screenshot to the test result (lifetime: keepAlways).
//
//  These tests fulfill the acceptance criteria for issue #85 and produce
//  the visual record needed for issue #84 (icon design language review).
//

import XCTest

class ExplorationScreenshotTests: ExplorationUITestCase {

  func testDesignLanguageScene() throws {
    navigate(to: "exploration.design-language")
    screenshotScene(named: "design-language")
  }

  func testRunnerRowScene() throws {
    navigate(to: "exploration.runner-row")
    screenshotScene(named: "runner-row")
  }

  func testPlayerStripScene() throws {
    navigate(to: "exploration.player-strip")
    screenshotScene(named: "player-strip")
  }

  func testPipTrackScene() throws {
    navigate(to: "exploration.pip-track")
    screenshotScene(named: "pip-track")
  }

  func testAllScenesVisible() throws {
    XCTAssertTrue(
      app.buttons["exploration.design-language"].waitForExistence(timeout: 3),
      "Design language scene should be listed")
    XCTAssertTrue(
      app.buttons["exploration.pip-track"].waitForExistence(timeout: 3),
      "Pip track scene should be listed")
    XCTAssertTrue(
      app.buttons["exploration.runner-row"].waitForExistence(timeout: 3),
      "Runner row scene should be listed")
    XCTAssertTrue(
      app.buttons["exploration.player-strip"].waitForExistence(timeout: 3),
      "Player strip scene should be listed")
    screenshotScene(named: "exploration-root")
  }
}
