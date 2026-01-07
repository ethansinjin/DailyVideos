import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = NotificationManager.shared.areNotificationsEnabled
    @State private var notificationTime = NotificationManager.shared.notificationTime
    @State private var showingPermissionAlert = false
    @State private var showingClearAllAlert = false
    @State private var showingClearOneYearAlert = false
    @State private var showingClearTwoYearsAlert = false
    @AppStorage("navigationControlsPosition") private var navigationControlsPosition: NavigationControlsPosition = .bottom

    var body: some View {
        NavigationStack {
            List {
                // Appearance Section
                Section {
                    Picker("Navigation Controls", selection: $navigationControlsPosition) {
                        Label("Bottom Toolbar", systemImage: "rectangle.bottomthird.inset.filled")
                            .tag(NavigationControlsPosition.bottom)
                        Label("Top Navigation Bar", systemImage: "rectangle.topthird.inset.filled")
                            .tag(NavigationControlsPosition.top)
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose where month navigation controls appear.")
                }

                // Notifications Section
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Daily Reminders", systemImage: "bell.fill")
                    }
                    .onChange(of: notificationsEnabled) { oldValue, newValue in
                        handleNotificationToggle(newValue)
                    }

                    if notificationsEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: notificationTime) { oldValue, newValue in
                            NotificationManager.shared.notificationTime = newValue
                            NotificationManager.shared.updateNotificationSchedule()
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get a daily reminder to capture your memories.")
                }

                // Preferred Media Section
                Section {
                    Button(role: .destructive) {
                        showingClearAllAlert = true
                    } label: {
                        Label("Clear All Preferences", systemImage: "trash")
                    }

                    Button(role: .destructive) {
                        showingClearOneYearAlert = true
                    } label: {
                        Label("Clear Older Than 1 Year", systemImage: "calendar.badge.minus")
                    }

                    Button(role: .destructive) {
                        showingClearTwoYearsAlert = true
                    } label: {
                        Label("Clear Older Than 2 Years", systemImage: "calendar.badge.minus")
                    }
                } header: {
                    Text("Preferred Media")
                } footer: {
                    Text("Remove saved preferences for which photo or video represents each day in the calendar. Current count: \(PreferencesManager.shared.getPreferenceCount())")
                }

                // About Section
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }

                // Permissions Section
                Section {
                    Button(action: openAppSettings) {
                        HStack {
                            Label("Edit Permissions in Settings", systemImage: "gear")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Permissions")
                } footer: {
                    Text("Manage photo library access and other app permissions.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings", role: nil) {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) {
                    notificationsEnabled = false
                }
            } message: {
                Text("Please enable notifications in Settings to receive daily reminders.")
            }
            .alert("Clear All Preferences?", isPresented: $showingClearAllAlert) {
                Button("Clear All", role: .destructive) {
                    PreferencesManager.shared.cleanupPreferences(olderThan: .all)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove all saved preferred media selections. This action cannot be undone.")
            }
            .alert("Clear Old Preferences?", isPresented: $showingClearOneYearAlert) {
                Button("Clear", role: .destructive) {
                    PreferencesManager.shared.cleanupPreferences(olderThan: .olderThanOneYear)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove preferred media selections older than 1 year. This action cannot be undone.")
            }
            .alert("Clear Old Preferences?", isPresented: $showingClearTwoYearsAlert) {
                Button("Clear", role: .destructive) {
                    PreferencesManager.shared.cleanupPreferences(olderThan: .olderThanTwoYears)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove preferred media selections older than 2 years. This action cannot be undone.")
            }
        }
    }

    private func handleNotificationToggle(_ enabled: Bool) {
        if enabled {
            // Request permission first
            NotificationManager.shared.checkAuthorizationStatus { status in
                switch status {
                case .authorized:
                    // Already authorized, just enable
                    NotificationManager.shared.areNotificationsEnabled = true
                    NotificationManager.shared.updateNotificationSchedule()

                case .notDetermined:
                    // Request permission
                    NotificationManager.shared.requestPermission { granted in
                        if granted {
                            NotificationManager.shared.areNotificationsEnabled = true
                            NotificationManager.shared.updateNotificationSchedule()
                        } else {
                            notificationsEnabled = false
                        }
                    }

                case .denied, .provisional, .ephemeral:
                    // Show alert to go to settings
                    showingPermissionAlert = true

                @unknown default:
                    notificationsEnabled = false
                }
            }
        } else {
            // Disable notifications
            NotificationManager.shared.areNotificationsEnabled = false
            NotificationManager.shared.updateNotificationSchedule()
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Navigation Controls Position

enum NavigationControlsPosition: String, CaseIterable {
    case bottom = "bottom"
    case top = "top"
}

#Preview {
    SettingsView()
}
