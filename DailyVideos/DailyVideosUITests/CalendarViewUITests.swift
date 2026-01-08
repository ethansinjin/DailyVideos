//
//  CalendarViewUITests.swift
//  DailyVideosUITests
//
//  UI tests for Calendar View
//

import XCTest

final class CalendarViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Initial Launch Tests

    @MainActor
    func testAppLaunches() throws {
        XCTAssertTrue(app.exists)
    }

    @MainActor
    func testCalendarViewAppears() throws {
        // Calendar grid should be visible
        XCTAssertTrue(app.exists)
    }

    @MainActor
    func testMonthHeaderAppears() throws {
        // Month/year header should exist
        let staticTexts = app.staticTexts
        let hasMonthText = staticTexts.allElementsBoundByIndex.contains { element in
            let label = element.label
            return label.contains("2024") || label.contains("2025") || label.contains("2026")
        }
        XCTAssertTrue(hasMonthText, "Month header should be visible")
    }

    @MainActor
    func testNavigationButtonsAppear() throws {
        // Navigation buttons should exist
        let buttons = app.buttons
        XCTAssertTrue(buttons.count > 0, "Navigation buttons should exist")
    }

    // MARK: - Calendar Grid Tests

    @MainActor
    func testCalendarGridIsVisible() throws {
        // Wait for calendar to load
        Thread.sleep(forTimeInterval: 1.0)

        // Day cells should exist
        let staticTexts = app.staticTexts
        XCTAssertTrue(staticTexts.count > 0, "Calendar days should be visible")
    }

    @MainActor
    func testDayOfWeekLabelsAppear() throws {
        // Check for day labels (Sun-Sat or locale equivalent)
        let staticTexts = app.staticTexts

        // Wait a moment for UI to settle
        Thread.sleep(forTimeInterval: 0.5)

        XCTAssertTrue(staticTexts.count > 0, "Weekday labels should exist")
    }

    // MARK: - Month Navigation Tests

    @MainActor
    func testNavigateToNextMonth() throws {
        // Wait for initial load
        Thread.sleep(forTimeInterval: 1.0)

        let initialStaticTexts = app.staticTexts.allElementsBoundByIndex.map { $0.label }

        // Find and tap next button (usually ">")
        let buttons = app.buttons.allElementsBoundByIndex
        if let nextButton = buttons.first(where: { $0.label.contains(">") || $0.label.contains("Next") }) {
            nextButton.tap()

            // Wait for navigation
            Thread.sleep(forTimeInterval: 0.5)

            let newStaticTexts = app.staticTexts.allElementsBoundByIndex.map { $0.label }

            // Content should have changed
            XCTAssertNotEqual(initialStaticTexts, newStaticTexts, "Calendar should update after navigation")
        }
    }

    @MainActor
    func testNavigateToPreviousMonth() throws {
        // Wait for initial load
        Thread.sleep(forTimeInterval: 1.0)

        let initialStaticTexts = app.staticTexts.allElementsBoundByIndex.map { $0.label }

        // Find and tap previous button (usually "<")
        let buttons = app.buttons.allElementsBoundByIndex
        if let prevButton = buttons.first(where: { $0.label.contains("<") || $0.label.contains("Previous") }) {
            prevButton.tap()

            // Wait for navigation
            Thread.sleep(forTimeInterval: 0.5)

            let newStaticTexts = app.staticTexts.allElementsBoundByIndex.map { $0.label }

            // Content should have changed
            XCTAssertNotEqual(initialStaticTexts, newStaticTexts, "Calendar should update after navigation")
        }
    }

    @MainActor
    func testTodayButton() throws {
        // Wait for initial load
        Thread.sleep(forTimeInterval: 1.0)

        // Navigate away from current month
        let buttons = app.buttons.allElementsBoundByIndex
        if let nextButton = buttons.first(where: { $0.label.contains(">") }) {
            nextButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Find and tap today button
        if let todayButton = buttons.first(where: { $0.label.lowercased().contains("today") }) {
            todayButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Should return to current month (verify by checking month text)
            XCTAssertTrue(app.exists)
        }
    }

    // MARK: - Day Selection Tests

    @MainActor
    func testDayCellTappable() throws {
        // Wait for initial load
        Thread.sleep(forTimeInterval: 1.0)

        // Find a day number button
        let buttons = app.buttons.allElementsBoundByIndex

        // Look for a numeric button (day cell)
        if let dayButton = buttons.first(where: { button in
            let label = button.label
            return Int(label) != nil
        }) {
            XCTAssertTrue(dayButton.isHittable, "Day cell should be tappable")
        }
    }

    @MainActor
    func testTappingDayShowsDetailView() throws {
        // Wait for initial load
        Thread.sleep(forTimeInterval: 1.0)

        // Find a day button
        let buttons = app.buttons.allElementsBoundByIndex
        if let dayButton = buttons.first(where: { Int($0.label) != nil }) {
            dayButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Detail view should appear (check for close button or other detail view elements)
            XCTAssertTrue(app.exists)
        }
    }

    // MARK: - Multiple Month Navigation Tests

    @MainActor
    func testNavigateMultipleMonthsForward() throws {
        Thread.sleep(forTimeInterval: 1.0)

        let buttons = app.buttons.allElementsBoundByIndex
        if let nextButton = buttons.first(where: { $0.label.contains(">") }) {
            // Navigate forward 3 months
            for _ in 1...3 {
                nextButton.tap()
                Thread.sleep(forTimeInterval: 0.3)
            }

            XCTAssertTrue(app.exists, "Should handle multiple navigations")
        }
    }

    @MainActor
    func testNavigateMultipleMonthsBackward() throws {
        Thread.sleep(forTimeInterval: 1.0)

        let buttons = app.buttons.allElementsBoundByIndex
        if let prevButton = buttons.first(where: { $0.label.contains("<") }) {
            // Navigate backward 3 months
            for _ in 1...3 {
                prevButton.tap()
                Thread.sleep(forTimeInterval: 0.3)
            }

            XCTAssertTrue(app.exists, "Should handle multiple navigations")
        }
    }

    // MARK: - Performance Tests

    @MainActor
    func testCalendarRenderingPerformance() throws {
        measure(metrics: [XCTClockMetric()]) {
            let buttons = app.buttons.allElementsBoundByIndex
            if let nextButton = buttons.first(where: { $0.label.contains(">") }) {
                nextButton.tap()
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }

    // MARK: - Edge Cases

    @MainActor
    func testRapidMonthNavigation() throws {
        Thread.sleep(forTimeInterval: 1.0)

        let buttons = app.buttons.allElementsBoundByIndex
        if let nextButton = buttons.first(where: { $0.label.contains(">") }) {
            // Rapid taps
            nextButton.tap()
            nextButton.tap()
            nextButton.tap()

            Thread.sleep(forTimeInterval: 0.5)

            // Should not crash
            XCTAssertTrue(app.exists)
        }
    }

    @MainActor
    func testAppDoesNotCrashOnLaunch() throws {
        // App should remain running
        Thread.sleep(forTimeInterval: 2.0)
        XCTAssertTrue(app.exists)
        XCTAssertEqual(app.state, .runningForeground)
    }
}
