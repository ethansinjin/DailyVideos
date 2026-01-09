//
//  MonthDataTests.swift
//  DailyVideosTests
//
//  Unit tests for MonthData model
//

import Testing
import Foundation
@testable import DailyVideos

@MainActor
struct MonthDataTests {

    // MARK: - Initialization Tests

    @Test func testInitialization() async throws {
        let year = 2024
        let month = 6
        let days = [
            CalendarDay(date: Date(), day: 1, isInCurrentMonth: true),
            CalendarDay(date: Date(), day: 2, isInCurrentMonth: true)
        ]

        let monthData = MonthData(year: year, month: month, days: days)

        #expect(monthData.year == year)
        #expect(monthData.month == month)
        #expect(monthData.days.count == 2)
    }

    @Test func testInitializationWithEmptyDays() async throws {
        let monthData = MonthData(year: 2024, month: 1, days: [])

        #expect(monthData.days.isEmpty)
    }

    // MARK: - Month Name Tests

    @Test func testMonthNameJanuary() async throws {
        let monthData = MonthData(year: 2024, month: 1, days: [])
        #expect(monthData.monthName == "January")
    }

    @Test func testMonthNameFebruary() async throws {
        let monthData = MonthData(year: 2024, month: 2, days: [])
        #expect(monthData.monthName == "February")
    }

    @Test func testMonthNameMarch() async throws {
        let monthData = MonthData(year: 2024, month: 3, days: [])
        #expect(monthData.monthName == "March")
    }

    @Test func testMonthNameApril() async throws {
        let monthData = MonthData(year: 2024, month: 4, days: [])
        #expect(monthData.monthName == "April")
    }

    @Test func testMonthNameMay() async throws {
        let monthData = MonthData(year: 2024, month: 5, days: [])
        #expect(monthData.monthName == "May")
    }

    @Test func testMonthNameJune() async throws {
        let monthData = MonthData(year: 2024, month: 6, days: [])
        #expect(monthData.monthName == "June")
    }

    @Test func testMonthNameJuly() async throws {
        let monthData = MonthData(year: 2024, month: 7, days: [])
        #expect(monthData.monthName == "July")
    }

    @Test func testMonthNameAugust() async throws {
        let monthData = MonthData(year: 2024, month: 8, days: [])
        #expect(monthData.monthName == "August")
    }

    @Test func testMonthNameSeptember() async throws {
        let monthData = MonthData(year: 2024, month: 9, days: [])
        #expect(monthData.monthName == "September")
    }

    @Test func testMonthNameOctober() async throws {
        let monthData = MonthData(year: 2024, month: 10, days: [])
        #expect(monthData.monthName == "October")
    }

    @Test func testMonthNameNovember() async throws {
        let monthData = MonthData(year: 2024, month: 11, days: [])
        #expect(monthData.monthName == "November")
    }

    @Test func testMonthNameDecember() async throws {
        let monthData = MonthData(year: 2024, month: 12, days: [])
        #expect(monthData.monthName == "December")
    }

    // MARK: - Display String Tests

    @Test func testDisplayString() async throws {
        let monthData = MonthData(year: 2024, month: 6, days: [])
        #expect(monthData.displayString == "June 2024")
    }

    @Test func testDisplayStringJanuary2025() async throws {
        let monthData = MonthData(year: 2025, month: 1, days: [])
        #expect(monthData.displayString == "January 2025")
    }

    @Test func testDisplayStringDecember2023() async throws {
        let monthData = MonthData(year: 2023, month: 12, days: [])
        #expect(monthData.displayString == "December 2023")
    }

    // MARK: - Various Year/Month Combinations

    @Test func testVariousYearMonthCombinations() async throws {
        let testCases: [(year: Int, month: Int, expected: String)] = [
            (2020, 2, "February 2020"),
            (2021, 7, "July 2021"),
            (2022, 12, "December 2022"),
            (2023, 1, "January 2023"),
            (2024, 6, "June 2024"),
            (2025, 11, "November 2025")
        ]

        for testCase in testCases {
            let monthData = MonthData(year: testCase.year, month: testCase.month, days: [])
            #expect(monthData.displayString == testCase.expected)
        }
    }

    // MARK: - Edge Cases

    @Test func testWithFullDaysArray() async throws {
        var days: [CalendarDay] = []
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2024, month: 6, day: 1))!

        // Create 42 days (full calendar grid)
        for i in 1...42 {
            let dayDate = calendar.date(byAdding: .day, value: i - 1, to: date)!
            days.append(CalendarDay(date: dayDate, day: i, isInCurrentMonth: i <= 30))
        }

        let monthData = MonthData(year: 2024, month: 6, days: days)
        #expect(monthData.days.count == 42)
    }
}
