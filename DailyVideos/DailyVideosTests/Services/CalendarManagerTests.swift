//
//  CalendarManagerTests.swift
//  DailyVideosTests
//
//  Unit tests for CalendarManager service
//

import Testing
import Foundation
@testable import DailyVideos

struct CalendarManagerTests {

    // MARK: - Singleton Tests

    @Test func testSharedInstanceIsSingleton() async throws {
        let instance1 = CalendarManager.shared
        let instance2 = CalendarManager.shared

        #expect(instance1 === instance2)
    }

    // MARK: - Current Month Tests

    @Test func testCurrentMonth() async throws {
        let (year, month) = CalendarManager.shared.currentMonth()

        #expect(year >= 2024)
        #expect(year <= 2100)
        #expect(month >= 1)
        #expect(month <= 12)
    }

    // MARK: - Next Month Tests

    @Test func testNextMonthMidYear() async throws {
        let next = CalendarManager.shared.nextMonth(from: (2024, 6))

        #expect(next.year == 2024)
        #expect(next.month == 7)
    }

    @Test func testNextMonthYearBoundary() async throws {
        let next = CalendarManager.shared.nextMonth(from: (2024, 12))

        #expect(next.year == 2025)
        #expect(next.month == 1)
    }

    @Test func testNextMonthJanuaryToFebruary() async throws {
        let next = CalendarManager.shared.nextMonth(from: (2024, 1))

        #expect(next.year == 2024)
        #expect(next.month == 2)
    }

    @Test func testNextMonthNovemberToDecember() async throws {
        let next = CalendarManager.shared.nextMonth(from: (2024, 11))

        #expect(next.year == 2024)
        #expect(next.month == 12)
    }

    // MARK: - Previous Month Tests

    @Test func testPreviousMonthMidYear() async throws {
        let previous = CalendarManager.shared.previousMonth(from: (2024, 7))

        #expect(previous.year == 2024)
        #expect(previous.month == 6)
    }

    @Test func testPreviousMonthYearBoundary() async throws {
        let previous = CalendarManager.shared.previousMonth(from: (2024, 1))

        #expect(previous.year == 2023)
        #expect(previous.month == 12)
    }

    @Test func testPreviousMonthDecemberToNovember() async throws {
        let previous = CalendarManager.shared.previousMonth(from: (2024, 12))

        #expect(previous.year == 2024)
        #expect(previous.month == 11)
    }

    @Test func testPreviousMonthFebruaryToJanuary() async throws {
        let previous = CalendarManager.shared.previousMonth(from: (2024, 2))

        #expect(previous.year == 2024)
        #expect(previous.month == 1)
    }

    // MARK: - Generate Month Tests

    @Test func testGenerateMonthHasDays() async throws {
        let monthData = CalendarManager.shared.generateMonth(year: 2024, month: 6)

        #expect(!monthData.days.isEmpty)
    }

    @Test func testGenerateMonthHas42Days() async throws {
        let monthData = CalendarManager.shared.generateMonth(year: 2024, month: 6)

        #expect(monthData.days.count == 42)
    }

    @Test func testGenerateMonthCorrectYearAndMonth() async throws {
        let monthData = CalendarManager.shared.generateMonth(year: 2024, month: 6)

        #expect(monthData.year == 2024)
        #expect(monthData.month == 6)
    }

    @Test func testGenerateMonthCurrentMonthDaysMarkedCorrectly() async throws {
        let monthData = CalendarManager.shared.generateMonth(year: 2024, month: 6)

        let currentMonthDays = monthData.days.filter { $0.isInCurrentMonth }
        #expect(currentMonthDays.count == 30) // June has 30 days
    }

    @Test func testGenerateMonthPaddingDaysMarkedCorrectly() async throws {
        let monthData = CalendarManager.shared.generateMonth(year: 2024, month: 6)

        let paddingDays = monthData.days.filter { !$0.isInCurrentMonth }
        #expect(paddingDays.count == 12) // 42 - 30 = 12 padding days
    }

    @Test func testGenerateMonthFebruaryNonLeapYear() async throws {
        let monthData = CalendarManager.shared.generateMonth(year: 2023, month: 2)

        let currentMonthDays = monthData.days.filter { $0.isInCurrentMonth }
        #expect(currentMonthDays.count == 28)
    }

    @Test func testGenerateMonthFebruaryLeapYear() async throws {
        let monthData = CalendarManager.shared.generateMonth(year: 2024, month: 2)

        let currentMonthDays = monthData.days.filter { $0.isInCurrentMonth }
        #expect(currentMonthDays.count == 29)
    }

    @Test func testGenerateMonth30DayMonth() async throws {
        let monthData = CalendarManager.shared.generateMonth(year: 2024, month: 4) // April

        let currentMonthDays = monthData.days.filter { $0.isInCurrentMonth }
        #expect(currentMonthDays.count == 30)
    }

    @Test func testGenerateMonth31DayMonth() async throws {
        let monthData = CalendarManager.shared.generateMonth(year: 2024, month: 1) // January

        let currentMonthDays = monthData.days.filter { $0.isInCurrentMonth }
        #expect(currentMonthDays.count == 31)
    }

    @Test func testGenerateMonthDayNumbersAreSequential() async throws {
        let monthData = CalendarManager.shared.generateMonth(year: 2024, month: 6)

        let currentMonthDays = monthData.days.filter { $0.isInCurrentMonth }
        for (index, day) in currentMonthDays.enumerated() {
            #expect(day.day == index + 1)
        }
    }

    // MARK: - Is Today Tests

    @Test func testIsTodayWithCurrentDate() async throws {
        let today = Date()
        let result = CalendarManager.shared.isToday(today)

        #expect(result == true)
    }

    @Test func testIsTodayWithYesterday() async throws {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let result = CalendarManager.shared.isToday(yesterday)

        #expect(result == false)
    }

    @Test func testIsTodayWithTomorrow() async throws {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let result = CalendarManager.shared.isToday(tomorrow)

        #expect(result == false)
    }

    @Test func testIsTodayWithDifferentYear() async throws {
        let calendar = Calendar.current
        let differentYear = calendar.date(byAdding: .year, value: -1, to: Date())!
        let result = CalendarManager.shared.isToday(differentYear)

        #expect(result == false)
    }

    // MARK: - Weekday Symbols Tests

    @Test func testWeekdaySymbolsCount() async throws {
        let symbols = CalendarManager.shared.weekdaySymbols()

        #expect(symbols.count == 7)
    }

    @Test func testWeekdaySymbolsNotEmpty() async throws {
        let symbols = CalendarManager.shared.weekdaySymbols()

        for symbol in symbols {
            #expect(!symbol.isEmpty)
        }
    }

    // MARK: - Edge Cases

    @Test func testGenerateMonthDecember() async throws {
        let monthData = CalendarManager.shared.generateMonth(year: 2024, month: 12)

        #expect(monthData.days.count == 42)
        let currentMonthDays = monthData.days.filter { $0.isInCurrentMonth }
        #expect(currentMonthDays.count == 31)
    }

    @Test func testGenerateMonthJanuary() async throws {
        let monthData = CalendarManager.shared.generateMonth(year: 2024, month: 1)

        #expect(monthData.days.count == 42)
        let currentMonthDays = monthData.days.filter { $0.isInCurrentMonth }
        #expect(currentMonthDays.count == 31)
    }
}
