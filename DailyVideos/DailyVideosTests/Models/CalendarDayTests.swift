//
//  CalendarDayTests.swift
//  DailyVideosTests
//
//  Unit tests for CalendarDay model
//

import Testing
import Foundation
@testable import DailyVideos

struct CalendarDayTests {

    // MARK: - Initialization Tests

    @Test func testInitialization() async throws {
        let date = Date()
        let day = 15
        let isInCurrentMonth = true

        let calendarDay = CalendarDay(date: date, day: day, isInCurrentMonth: isInCurrentMonth)

        #expect(calendarDay.date == date)
        #expect(calendarDay.day == day)
        #expect(calendarDay.isInCurrentMonth == isInCurrentMonth)
    }

    @Test func testDefaultValues() async throws {
        let date = Date()
        let calendarDay = CalendarDay(date: date, day: 1, isInCurrentMonth: true)

        #expect(calendarDay.mediaCount == 0)
        #expect(calendarDay.representativeAssetIdentifier == nil)
    }

    // MARK: - Computed Property Tests

    @Test func testHasMediaReturnsFalseWhenCountIsZero() async throws {
        let date = Date()
        var calendarDay = CalendarDay(date: date, day: 1, isInCurrentMonth: true)
        calendarDay.mediaCount = 0

        #expect(calendarDay.hasMedia == false)
    }

    @Test func testHasMediaReturnsTrueWhenCountIsPositive() async throws {
        let date = Date()
        var calendarDay = CalendarDay(date: date, day: 1, isInCurrentMonth: true)
        calendarDay.mediaCount = 1

        #expect(calendarDay.hasMedia == true)
    }

    @Test func testHasMediaReturnsTrueWhenCountIsMultiple() async throws {
        let date = Date()
        var calendarDay = CalendarDay(date: date, day: 1, isInCurrentMonth: true)
        calendarDay.mediaCount = 5

        #expect(calendarDay.hasMedia == true)
    }

    @Test func testIdReturnsDate() async throws {
        let date = Date()
        let calendarDay = CalendarDay(date: date, day: 1, isInCurrentMonth: true)

        #expect(calendarDay.id == date)
    }

    // MARK: - Mutability Tests

    @Test func testMediaCountCanBeUpdated() async throws {
        let date = Date()
        var calendarDay = CalendarDay(date: date, day: 1, isInCurrentMonth: true)

        calendarDay.mediaCount = 3
        #expect(calendarDay.mediaCount == 3)

        calendarDay.mediaCount = 7
        #expect(calendarDay.mediaCount == 7)
    }

    @Test func testRepresentativeAssetIdentifierCanBeUpdated() async throws {
        let date = Date()
        var calendarDay = CalendarDay(date: date, day: 1, isInCurrentMonth: true)

        let assetId = "test-asset-123"
        calendarDay.representativeAssetIdentifier = assetId
        #expect(calendarDay.representativeAssetIdentifier == assetId)

        let newAssetId = "new-asset-456"
        calendarDay.representativeAssetIdentifier = newAssetId
        #expect(calendarDay.representativeAssetIdentifier == newAssetId)
    }

    // MARK: - Edge Cases

    @Test func testDayOutsideCurrentMonth() async throws {
        let date = Date()
        let calendarDay = CalendarDay(date: date, day: 30, isInCurrentMonth: false)

        #expect(calendarDay.isInCurrentMonth == false)
    }

    @Test func testVariousDayNumbers() async throws {
        let date = Date()

        // Test day 1
        let day1 = CalendarDay(date: date, day: 1, isInCurrentMonth: true)
        #expect(day1.day == 1)

        // Test day 15
        let day15 = CalendarDay(date: date, day: 15, isInCurrentMonth: true)
        #expect(day15.day == 15)

        // Test day 31
        let day31 = CalendarDay(date: date, day: 31, isInCurrentMonth: true)
        #expect(day31.day == 31)
    }
}
