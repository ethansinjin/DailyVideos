import Foundation
import UserNotifications

/// Manages local notifications for daily reminders
class NotificationManager {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationIdentifier = "daily-video-reminder"

    // UserDefaults keys
    private let notificationsEnabledKey = "notificationsEnabled"
    private let notificationTimeKey = "notificationTime"

    private init() {}

    // MARK: - Settings

    /// Check if notifications are enabled
    var areNotificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: notificationsEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: notificationsEnabledKey) }
    }

    /// Get/set the notification time
    var notificationTime: Date {
        get {
            if let timeInterval = UserDefaults.standard.object(forKey: notificationTimeKey) as? TimeInterval {
                return Date(timeIntervalSince1970: timeInterval)
            }
            // Default to 8:00 PM
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 20
            components.minute = 0
            return calendar.date(from: components) ?? Date()
        }
        set {
            UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: notificationTimeKey)
        }
    }

    // MARK: - Permissions

    /// Request notification permissions
    func requestPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    completion(true)
                } else {
                    print("Notification permission denied: \(error?.localizedDescription ?? "unknown error")")
                    completion(false)
                }
            }
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - Scheduling

    /// Schedule daily reminder notification
    func scheduleDailyReminder() {
        // Cancel any existing notifications first
        cancelNotifications()

        guard areNotificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Daily Video Reminder"
        content.body = "Don't forget to capture today's moment! 📸"
        content.sound = .default

        // Get the hour and minute from the saved time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)

        // Create trigger for daily at specified time
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Daily reminder scheduled for \(components.hour ?? 0):\(String(format: "%02d", components.minute ?? 0))")
            }
        }
    }

    /// Cancel all scheduled notifications
    func cancelNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        print("Notifications cancelled")
    }

    /// Update notification schedule (call this when settings change)
    func updateNotificationSchedule() {
        if areNotificationsEnabled {
            scheduleDailyReminder()
        } else {
            cancelNotifications()
        }
    }
}
