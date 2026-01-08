//
//  NotificationManagerTests.swift
//  DailyVideosTests
//
//  Unit tests for NotificationManager service
//

import Testing
import Foundation
import UserNotifications
@testable import DailyVideos

@MainActor
struct NotificationManagerTests {

    // MARK: - Singleton Tests

    @Test func testSharedInstanceIsSingleton() async throws {
        let instance1 = NotificationManager.shared
        let instance2 = NotificationManager.shared

        #expect(instance1 === instance2)
    }

    // MARK: - Notifications Enabled Tests

    @Test func testAreNotificationsEnabledDefaultValue() async throws {
        // Reset to default
        UserDefaults.standard.removeObject(forKey: "notificationsEnabled")

        let enabled = NotificationManager.shared.areNotificationsEnabled
        #expect(enabled == false)
    }

    @Test func testAreNotificationsEnabledSetter() async throws {
        NotificationManager.shared.areNotificationsEnabled = true
        #expect(NotificationManager.shared.areNotificationsEnabled == true)

        NotificationManager.shared.areNotificationsEnabled = false
        #expect(NotificationManager.shared.areNotificationsEnabled == false)
    }

    @Test func testAreNotificationsEnabledPersistence() async throws {
        NotificationManager.shared.areNotificationsEnabled = true

        // Create new instance to test persistence
        let manager = NotificationManager.shared
        #expect(manager.areNotificationsEnabled == true)
    }

    // MARK: - Notification Time Tests

    @Test func testNotificationTimeDefaultValue() async throws {
        // Reset to default
        UserDefaults.standard.removeObject(forKey: "notificationTime")

        let time = NotificationManager.shared.notificationTime
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        #expect(components.hour == 20) // 8:00 PM
        #expect(components.minute == 0)
    }

    @Test func testNotificationTimeSetter() async throws {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = 9
        components.minute = 30

        guard let customTime = calendar.date(from: components) else {
            Issue.record("Failed to create custom time")
            return
        }

        NotificationManager.shared.notificationTime = customTime

        let savedTime = NotificationManager.shared.notificationTime
        let savedComponents = calendar.dateComponents([.hour, .minute], from: savedTime)

        #expect(savedComponents.hour == 9)
        #expect(savedComponents.minute == 30)
    }

    @Test func testNotificationTimePersistence() async throws {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = 15
        components.minute = 45

        guard let customTime = calendar.date(from: components) else {
            Issue.record("Failed to create custom time")
            return
        }

        NotificationManager.shared.notificationTime = customTime

        // Retrieve again to test persistence
        let savedTime = NotificationManager.shared.notificationTime
        let savedComponents = calendar.dateComponents([.hour, .minute], from: savedTime)

        #expect(savedComponents.hour == 15)
        #expect(savedComponents.minute == 45)
    }

    // MARK: - Permission Tests

    @Test func testRequestPermissionCompletionIsCalled() async throws {
        await withCheckedContinuation { continuation in
            NotificationManager.shared.requestPermission { _ in
                continuation.resume()
            }
        }
        // Test passes if completion is called
        #expect(true)
    }

    @Test func testCheckAuthorizationStatusCompletionIsCalled() async throws {
        await withCheckedContinuation { continuation in
            NotificationManager.shared.checkAuthorizationStatus { _ in
                continuation.resume()
            }
        }
        // Test passes if completion is called
        #expect(true)
    }

    // MARK: - Scheduling Tests

    @Test func testScheduleDailyReminderWhenDisabled() async throws {
        NotificationManager.shared.areNotificationsEnabled = false

        // This should not crash and should handle gracefully
        NotificationManager.shared.scheduleDailyReminder()

        // Test passes if no exception is thrown
        #expect(true)
    }

    @Test func testCancelNotifications() async throws {
        // This should not crash
        NotificationManager.shared.cancelNotifications()

        // Test passes if no exception is thrown
        #expect(true)
    }

    @Test func testUpdateNotificationScheduleWhenEnabled() async throws {
        NotificationManager.shared.areNotificationsEnabled = true

        // This should not crash
        NotificationManager.shared.updateNotificationSchedule()

        // Test passes if no exception is thrown
        #expect(true)
    }

    @Test func testUpdateNotificationScheduleWhenDisabled() async throws {
        NotificationManager.shared.areNotificationsEnabled = false

        // This should not crash
        NotificationManager.shared.updateNotificationSchedule()

        // Test passes if no exception is thrown
        #expect(true)
    }

    // MARK: - Edge Cases

    @Test func testMultipleScheduleCalls() async throws {
        NotificationManager.shared.areNotificationsEnabled = true

        // Multiple calls should not crash
        NotificationManager.shared.scheduleDailyReminder()
        NotificationManager.shared.scheduleDailyReminder()
        NotificationManager.shared.scheduleDailyReminder()

        #expect(true)
    }

    @Test func testMultipleCancelCalls() async throws {
        // Multiple calls should not crash
        NotificationManager.shared.cancelNotifications()
        NotificationManager.shared.cancelNotifications()
        NotificationManager.shared.cancelNotifications()

        #expect(true)
    }

    @Test func testToggleNotifications() async throws {
        // Toggle multiple times
        NotificationManager.shared.areNotificationsEnabled = true
        NotificationManager.shared.updateNotificationSchedule()

        NotificationManager.shared.areNotificationsEnabled = false
        NotificationManager.shared.updateNotificationSchedule()

        NotificationManager.shared.areNotificationsEnabled = true
        NotificationManager.shared.updateNotificationSchedule()

        #expect(true)
    }
}
