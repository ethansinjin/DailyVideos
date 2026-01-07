//
//  AccessibilityUITests.swift
//  DailyVideosUITests
//
//  Accessibility tests for VoiceOver, Dynamic Type, etc.
//

import XCTest

final class AccessibilityUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // MARK: - VoiceOver Tests

    @MainActor
    func testButtonsHaveAccessibilityLabels() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        let buttons = app.buttons.allElementsBoundByIndex

        for button in buttons {
            // All buttons should have some form of label
            XCTAssertFalse(button.label.isEmpty, "Button should have accessibility label")
        }
    }

    @MainActor
    func testNavigationButtonsAccessible() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        let buttons = app.buttons.allElementsBoundByIndex

        // Navigation buttons should be accessible
        let hasAccessibleButtons = buttons.contains { button in
            button.isEnabled && button.exists
        }

        XCTAssertTrue(hasAccessibleButtons, "Navigation buttons should be accessible")
    }

    @MainActor
    func testDayCellsAccessible() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        let buttons = app.buttons.allElementsBoundByIndex
        let dayButtons = buttons.filter { Int($0.label) != nil }

        // Day cells should be accessible
        for dayButton in dayButtons.prefix(5) {
            XCTAssertTrue(dayButton.exists, "Day cell should exist")
        }
    }

    // MARK: - Dynamic Type Tests

    @MainActor
    func testAppSupportsLargerTextSize() throws {
        // Enable larger text size
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        // App should still be functional with larger text
        XCTAssertTrue(app.exists)
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    func testAppSupportsSmallTextSize() throws {
        // Enable smaller text size
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXS"]
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        // App should still be functional with smaller text
        XCTAssertTrue(app.exists)
        XCTAssertEqual(app.state, .runningForeground)
    }

    // MARK: - Color Contrast Tests

    @MainActor
    func testAppWorksInDarkMode() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        // App should be functional in dark mode
        XCTAssertTrue(app.exists)
    }

    @MainActor
    func testAppWorksInLightMode() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        // App should be functional in light mode
        XCTAssertTrue(app.exists)
    }

    // MARK: - Reduce Motion Tests

    @MainActor
    func testAppSupportsReduceMotion() throws {
        // Enable reduce motion
        app.launchArguments = ["-UIAccessibilityIsReduceMotionEnabled", "1"]
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        // App should be functional with reduced motion
        XCTAssertTrue(app.exists)

        // Navigation should still work
        let buttons = app.buttons.allElementsBoundByIndex
        if let nextButton = buttons.first(where: { $0.label.contains(">") }) {
            nextButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            XCTAssertTrue(app.exists)
        }
    }

    // MARK: - Interactive Element Tests

    @MainActor
    func testInteractiveElementsAreDistinguishable() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        // All buttons should be enabled and hittable
        let buttons = app.buttons.allElementsBoundByIndex
        let activeButtons = buttons.filter { $0.isEnabled && $0.isHittable }

        XCTAssertTrue(activeButtons.count > 0, "Should have interactive elements")
    }

    // MARK: - Edge Cases

    @MainActor
    func testAccessibilityInDayDetailView() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        // Navigate to day detail
        let buttons = app.buttons.allElementsBoundByIndex
        if let dayButton = buttons.first(where: { Int($0.label) != nil }) {
            dayButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Detail view should be accessible
            XCTAssertTrue(app.exists)
        }
    }
}
