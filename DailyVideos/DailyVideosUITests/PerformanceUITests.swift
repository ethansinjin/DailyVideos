//
//  PerformanceUITests.swift
//  DailyVideosUITests
//
//  Performance tests for the app
//

import XCTest

final class PerformanceUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // MARK: - Launch Performance Tests

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }

    @MainActor
    func testAppLaunchTime() throws {
        let launchMetric = XCTClockMetric()

        measure(metrics: [launchMetric]) {
            app.launch()
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    // MARK: - Navigation Performance Tests

    @MainActor
    func testMonthNavigationPerformance() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        measure(metrics: [XCTClockMetric()]) {
            let buttons = app.buttons.allElementsBoundByIndex
            if let nextButton = buttons.first(where: { $0.label.contains(">") }) {
                nextButton.tap()
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }

    @MainActor
    func testDaySelectionPerformance() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        measure(metrics: [XCTClockMetric()]) {
            let buttons = app.buttons.allElementsBoundByIndex
            if let dayButton = buttons.first(where: { Int($0.label) != nil }) {
                dayButton.tap()
                Thread.sleep(forTimeInterval: 0.1)

                // Close detail view
                app.swipeDown()
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }

    // MARK: - UI Rendering Performance Tests

    @MainActor
    func testCalendarRenderingPerformance() throws {
        app.launch()

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            Thread.sleep(forTimeInterval: 1.0)

            // Navigate through months
            let buttons = app.buttons.allElementsBoundByIndex
            if let nextButton = buttons.first(where: { $0.label.contains(">") }) {
                for _ in 1...3 {
                    nextButton.tap()
                    Thread.sleep(forTimeInterval: 0.2)
                }
            }
        }
    }

    // MARK: - Memory Performance Tests

    @MainActor
    func testMemoryUsageDuringNavigation() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        measure(metrics: [XCTMemoryMetric()]) {
            let buttons = app.buttons.allElementsBoundByIndex
            if let nextButton = buttons.first(where: { $0.label.contains(">") }) {
                // Navigate through multiple months
                for _ in 1...5 {
                    nextButton.tap()
                    Thread.sleep(forTimeInterval: 0.2)
                }
            }
        }
    }

    // MARK: - Scrolling Performance Tests

    @MainActor
    func testScrollingPerformance() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        // Navigate to day detail (if it has scrollable content)
        let buttons = app.buttons.allElementsBoundByIndex
        if let dayButton = buttons.first(where: { Int($0.label) != nil }) {
            dayButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            measure(metrics: [XCTClockMetric()]) {
                // Try scrolling if possible
                app.swipeUp()
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }

    // MARK: - Stress Tests

    @MainActor
    func testRapidNavigationDoesNotDegradPerformance() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        let startTime = Date()

        // Rapid navigation
        let buttons = app.buttons.allElementsBoundByIndex
        if let nextButton = buttons.first(where: { $0.label.contains(">") }) {
            for _ in 1...10 {
                nextButton.tap()
                Thread.sleep(forTimeInterval: 0.1)
            }
        }

        let endTime = Date()
        let elapsed = endTime.timeIntervalSince(startTime)

        // Should complete in reasonable time (< 5 seconds)
        XCTAssertLessThan(elapsed, 5.0, "Navigation should be fast")
    }

    @MainActor
    func testAppResponsiveAfterExtendedUse() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        // Simulate extended use
        let buttons = app.buttons.allElementsBoundByIndex

        if let nextButton = buttons.first(where: { $0.label.contains(">") }) {
            // Navigate forward
            for _ in 1...5 {
                nextButton.tap()
                Thread.sleep(forTimeInterval: 0.2)
            }
        }

        if let prevButton = buttons.first(where: { $0.label.contains("<") }) {
            // Navigate backward
            for _ in 1...5 {
                prevButton.tap()
                Thread.sleep(forTimeInterval: 0.2)
            }
        }

        // App should still be responsive
        XCTAssertTrue(app.exists)
        XCTAssertEqual(app.state, .runningForeground)
    }
}
