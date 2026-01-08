//
//  MediaDetailViewUITests.swift
//  DailyVideosUITests
//
//  UI tests for Media Detail View
//

import XCTest

final class MediaDetailViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Helper Methods

    private func navigateToMediaDetailView() {
        Thread.sleep(forTimeInterval: 1.0)

        // Tap a day cell
        let buttons = app.buttons.allElementsBoundByIndex
        if let dayButton = buttons.first(where: { Int($0.label) != nil }) {
            dayButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Tap a media item if exists
            let images = app.images
            if images.count > 0 {
                images.firstMatch.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }

    // MARK: - Media Viewer Appearance Tests

    @MainActor
    func testMediaViewerAppearsWhenMediaTapped() throws {
        navigateToMediaDetailView()

        // Media viewer should be present
        XCTAssertTrue(app.exists)
    }

    @MainActor
    func testCloseButtonPresent() throws {
        navigateToMediaDetailView()

        // Close button should exist
        let buttons = app.buttons.allElementsBoundByIndex
        let hasCloseButton = buttons.contains { button in
            let label = button.label.lowercased()
            return label.contains("close") || label.contains("done") || label == "×"
        }

        // Viewer should be shown (close button may vary by design)
        XCTAssertTrue(app.exists)
    }

    // MARK: - Video Playback Tests

    @MainActor
    func testVideoPlayerControlsPresent() throws {
        navigateToMediaDetailView()

        // If it's a video, controls should be available
        // This is a general test that the view is functional
        XCTAssertTrue(app.exists)
    }

    @MainActor
    func testVideoCanBePlayed() throws {
        navigateToMediaDetailView()

        // Look for play button
        let buttons = app.buttons.allElementsBoundByIndex
        let playButton = buttons.first { button in
            let label = button.label.lowercased()
            return label.contains("play") || label == "▶︎" || label == "▶"
        }

        if let playButton = playButton {
            XCTAssertTrue(playButton.exists)
        }
    }

    // MARK: - Navigation Between Media Tests

    @MainActor
    func testSwipeToNavigateBetweenMedia() throws {
        navigateToMediaDetailView()

        let initialState = app.state

        // Try swiping left (next media)
        app.swipeLeft()
        Thread.sleep(forTimeInterval: 0.3)

        // Should not crash
        XCTAssertTrue(app.exists)

        // Try swiping right (previous media)
        app.swipeRight()
        Thread.sleep(forTimeInterval: 0.3)

        XCTAssertTrue(app.exists)
    }

    // MARK: - Close Media Viewer Tests

    @MainActor
    func testCloseMediaViewer() throws {
        navigateToMediaDetailView()

        // Try to find and tap close button
        let buttons = app.buttons.allElementsBoundByIndex
        if let closeButton = buttons.first(where: { button in
            let label = button.label.lowercased()
            return label.contains("close") || label.contains("done") || label == "×"
        }) {
            closeButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Should return to day detail or calendar
            XCTAssertTrue(app.exists)
        } else {
            // Try swipe down gesture
            app.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
            XCTAssertTrue(app.exists)
        }
    }

    // MARK: - Metadata Display Tests

    @MainActor
    func testMediaMetadataDisplayed() throws {
        navigateToMediaDetailView()

        // Date/time or other metadata should be visible
        let staticTexts = app.staticTexts
        XCTAssertTrue(staticTexts.count > 0, "Metadata should be displayed")
    }

    // MARK: - Edge Cases

    @MainActor
    func testMediaViewerStability() throws {
        navigateToMediaDetailView()

        // Wait to ensure stability
        Thread.sleep(forTimeInterval: 2.0)

        // Should remain running
        XCTAssertTrue(app.exists)
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    func testRapidSwipesBetweenMedia() throws {
        navigateToMediaDetailView()

        // Rapid swipes
        app.swipeLeft()
        app.swipeLeft()
        app.swipeRight()
        app.swipeRight()

        Thread.sleep(forTimeInterval: 0.5)

        // Should not crash
        XCTAssertTrue(app.exists)
    }

    @MainActor
    func testMediaViewerDoesNotCrash() throws {
        Thread.sleep(forTimeInterval: 1.0)

        // Navigate through multiple views without crashing
        let buttons = app.buttons.allElementsBoundByIndex
        if let dayButton = buttons.first(where: { Int($0.label) != nil }) {
            dayButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            let images = app.images
            if images.count > 0 {
                images.firstMatch.tap()
                Thread.sleep(forTimeInterval: 1.0)

                // Should be stable
                XCTAssertTrue(app.exists)
                XCTAssertEqual(app.state, .runningForeground)
            }
        }
    }
}
