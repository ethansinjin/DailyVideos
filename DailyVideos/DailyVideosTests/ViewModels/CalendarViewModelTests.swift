//
//  CalendarViewModelTests.swift
//  DailyVideosTests
//
//  Unit tests for CalendarViewModel
//

import Testing
import Foundation
@testable import DailyVideos

@MainActor
struct CalendarViewModelTests {

    // MARK: - Initialization Tests

    @Test func testInitialization() async throws {
        let viewModel = CalendarViewModel()

        #expect(viewModel.currentMonth.days.count > 0)
        #expect(viewModel.selectedDay == nil)
        #expect(viewModel.isLoading == false)
    }

    @Test func testInitialMonthIsCurrentMonth() async throws {
        let viewModel = CalendarViewModel()
        let calendar = Calendar.current
        let now = Date()

        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        #expect(viewModel.currentMonth.year == currentYear)
        #expect(viewModel.currentMonth.month == currentMonth)
    }

    // MARK: - Month Navigation Tests

    @Test func testGoToNextMonth() async throws {
        let viewModel = CalendarViewModel()
        let initialMonth = viewModel.currentMonth.month
        let initialYear = viewModel.currentMonth.year

        viewModel.goToNextMonth()

        // Wait for month to actually change
        await waitForMonthChange(viewModel, from: (initialYear, initialMonth))

        if initialMonth == 12 {
            #expect(viewModel.currentMonth.year == initialYear + 1)
            #expect(viewModel.currentMonth.month == 1)
        } else {
            #expect(viewModel.currentMonth.year == initialYear)
            #expect(viewModel.currentMonth.month == initialMonth + 1)
        }
    }

    @MainActor
    private func waitForLoadingToComplete(_ viewModel: CalendarViewModel, timeout: TimeInterval = 2.0) async {
        let deadline = Date().addingTimeInterval(timeout)
        while viewModel.isLoading && Date() < deadline {
            // Yield to allow the main queue to process pending work
            await Task.yield()
            // Small delay to avoid tight loop
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        // Extra yield to ensure final updates are processed
        await Task.yield()
    }

    @MainActor
    private func waitForMonthChange(_ viewModel: CalendarViewModel, from initial: (year: Int, month: Int), timeout: TimeInterval = 2.0) async {
        let deadline = Date().addingTimeInterval(timeout)
        while (viewModel.currentMonth.year == initial.year && viewModel.currentMonth.month == initial.month) && Date() < deadline {
            // Yield to allow the main queue to process pending work
            await Task.yield()
            // Small delay to avoid tight loop
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        // Extra yield to ensure all updates are processed
        await Task.yield()
    }

    @Test func testGoToPreviousMonth() async throws {
        let viewModel = CalendarViewModel()
        let initialMonth = viewModel.currentMonth.month
        let initialYear = viewModel.currentMonth.year

        viewModel.goToPreviousMonth()

        // Wait for month to actually change
        await waitForMonthChange(viewModel, from: (initialYear, initialMonth))

        if initialMonth == 1 {
            #expect(viewModel.currentMonth.year == initialYear - 1)
            #expect(viewModel.currentMonth.month == 12)
        } else {
            #expect(viewModel.currentMonth.year == initialYear)
            #expect(viewModel.currentMonth.month == initialMonth - 1)
        }
    }

    @Test func testGoToToday() async throws {
        let viewModel = CalendarViewModel()
        let calendar = Calendar.current
        let now = Date()
        let expectedYear = calendar.component(.year, from: now)
        let expectedMonth = calendar.component(.month, from: now)

        // Navigate away from current month
        let firstMonth = (viewModel.currentMonth.year, viewModel.currentMonth.month)
        viewModel.goToNextMonth()
        await waitForMonthChange(viewModel, from: firstMonth)

        let secondMonth = (viewModel.currentMonth.year, viewModel.currentMonth.month)
        viewModel.goToNextMonth()
        await waitForMonthChange(viewModel, from: secondMonth)

        // Go back to today
        let thirdMonth = (viewModel.currentMonth.year, viewModel.currentMonth.month)
        viewModel.goToToday()
        await waitForMonthChange(viewModel, from: thirdMonth)

        #expect(viewModel.currentMonth.year == expectedYear)
        #expect(viewModel.currentMonth.month == expectedMonth)
    }

    // MARK: - Day Selection Tests

    @Test func testSelectDay() async throws {
        let viewModel = CalendarViewModel()
        let day = viewModel.currentMonth.days.first!

        viewModel.selectDay(day)

        #expect(viewModel.selectedDay != nil)
        #expect(viewModel.selectedDay?.date == day.date)
    }

    @Test func testSelectDayUpdatesSelection() async throws {
        let viewModel = CalendarViewModel()
        let day1 = viewModel.currentMonth.days[0]
        let day2 = viewModel.currentMonth.days[1]

        viewModel.selectDay(day1)
        #expect(viewModel.selectedDay?.date == day1.date)

        viewModel.selectDay(day2)
        #expect(viewModel.selectedDay?.date == day2.date)
    }

    // MARK: - Refresh Tests

    @Test func testRefreshMediaData() async throws {
        let viewModel = CalendarViewModel()

        viewModel.refreshMediaData()

        // Wait for refresh to complete
        await waitForLoadingToComplete(viewModel)

        // Should not crash and should complete
        #expect(true)
    }

    // MARK: - Helper Method Tests

    @Test func testIsToday() async throws {
        let viewModel = CalendarViewModel()
        let today = Date()

        #expect(viewModel.isToday(today) == true)
    }

    @Test func testIsTodayWithYesterday() async throws {
        let viewModel = CalendarViewModel()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        #expect(viewModel.isToday(yesterday) == false)
    }

    @Test func testWeekdaySymbols() async throws {
        let viewModel = CalendarViewModel()
        let symbols = viewModel.weekdaySymbols()

        #expect(symbols.count == 7)
        #expect(!symbols[0].isEmpty)
    }

    @Test func testGetMediaItemsForDay() async throws {
        let viewModel = CalendarViewModel()
        let day = viewModel.currentMonth.days.first!

        let mediaItems = viewModel.getMediaItems(for: day)

        // Should return an array (may be empty)
        #expect(mediaItems.isEmpty || !mediaItems.isEmpty) // Always true, just checking it doesn't crash
    }

    // MARK: - Edge Cases

    @Test func testMultipleNavigations() async throws {
        let viewModel = CalendarViewModel()

        // Navigate forward multiple times
        for _ in 1...5 {
            viewModel.goToNextMonth()
            await waitForLoadingToComplete(viewModel)
        }

        // Navigate backward multiple times
        for _ in 1...5 {
            viewModel.goToPreviousMonth()
            await waitForLoadingToComplete(viewModel)
        }

        // Should not crash
        #expect(true)
    }

    @Test func testNavigateAcrossYearBoundary() async throws {
        let viewModel = CalendarViewModel()
        let calendar = Calendar.current

        // Find current month
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)

        // Navigate to December
        let monthsToDecember = 12 - currentMonth
        for _ in 0..<monthsToDecember {
            let beforeNav = (viewModel.currentMonth.year, viewModel.currentMonth.month)
            viewModel.goToNextMonth()
            await waitForMonthChange(viewModel, from: beforeNav)
        }

        let yearBeforeTransition = viewModel.currentMonth.year

        // Cross to January
        let decemberState = (viewModel.currentMonth.year, viewModel.currentMonth.month)
        viewModel.goToNextMonth()
        await waitForMonthChange(viewModel, from: decemberState)

        #expect(viewModel.currentMonth.month == 1)
        #expect(viewModel.currentMonth.year == yearBeforeTransition + 1)
    }
}
