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

        // Wait a moment for async operations
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        if initialMonth == 12 {
            #expect(viewModel.currentMonth.year == initialYear + 1)
            #expect(viewModel.currentMonth.month == 1)
        } else {
            #expect(viewModel.currentMonth.year == initialYear)
            #expect(viewModel.currentMonth.month == initialMonth + 1)
        }
    }

    @Test func testGoToPreviousMonth() async throws {
        let viewModel = CalendarViewModel()
        let initialMonth = viewModel.currentMonth.month
        let initialYear = viewModel.currentMonth.year

        viewModel.goToPreviousMonth()

        // Wait a moment for async operations
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

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

        // Navigate away from current month
        viewModel.goToNextMonth()
        try await Task.sleep(nanoseconds: 100_000_000)
        viewModel.goToNextMonth()
        try await Task.sleep(nanoseconds: 100_000_000)

        // Go back to today
        viewModel.goToToday()
        try await Task.sleep(nanoseconds: 100_000_000)

        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        #expect(viewModel.currentMonth.year == currentYear)
        #expect(viewModel.currentMonth.month == currentMonth)
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
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

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
        #expect(mediaItems is [MediaItem])
    }

    // MARK: - Edge Cases

    @Test func testMultipleNavigations() async throws {
        let viewModel = CalendarViewModel()

        // Navigate forward multiple times
        for _ in 1...5 {
            viewModel.goToNextMonth()
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        // Navigate backward multiple times
        for _ in 1...5 {
            viewModel.goToPreviousMonth()
            try await Task.sleep(nanoseconds: 50_000_000)
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
            viewModel.goToNextMonth()
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        let yearBeforeTransition = viewModel.currentMonth.year

        // Cross to January
        viewModel.goToNextMonth()
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.currentMonth.month == 1)
        #expect(viewModel.currentMonth.year == yearBeforeTransition + 1)
    }
}
