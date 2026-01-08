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
    @State private var showingClearPinsAllAlert = false
    @State private var showingClearPinsOneYearAlert = false
    @State private var showingClearPinsTwoYearsAlert = false
    @State private var showingCleanupOrphanedPinsAlert = false
    @AppStorage("navigationControlsPosition") private var navigationControlsPosition: NavigationControlsPosition = .bottom

    var body: some View {
        NavigationStack {
            settingsList
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .modifier(NotificationAlertModifier(
            showingPermissionAlert: $showingPermissionAlert,
            notificationsEnabled: $notificationsEnabled
        ))
        .modifier(PreferenceAlertsModifier(
            showingClearAllAlert: $showingClearAllAlert,
            showingClearOneYearAlert: $showingClearOneYearAlert,
            showingClearTwoYearsAlert: $showingClearTwoYearsAlert
        ))
        .modifier(PinAlertsModifier(
            showingClearPinsAllAlert: $showingClearPinsAllAlert,
            showingClearPinsOneYearAlert: $showingClearPinsOneYearAlert,
            showingClearPinsTwoYearsAlert: $showingClearPinsTwoYearsAlert,
            showingCleanupOrphanedPinsAlert: $showingCleanupOrphanedPinsAlert
        ))
    }

    private var settingsList: some View {
        List {
            appearanceSection
            notificationsSection
            preferredMediaSection
            pinnedMediaSection
            aboutSection
            permissionsSection
        }
    }

    private var appearanceSection: some View {
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
    }

    private var notificationsSection: some View {
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
    }

    private var preferredMediaSection: some View {
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
    }

    private var pinnedMediaSection: some View {
        Section {
            Button {
                showingCleanupOrphanedPinsAlert = true
            } label: {
                Label("Remove Orphaned Pins", systemImage: "arrow.triangle.2.circlepath")
            }

            Button(role: .destructive) {
                showingClearPinsAllAlert = true
            } label: {
                Label("Clear All Pins", systemImage: "trash")
            }

            Button(role: .destructive) {
                showingClearPinsOneYearAlert = true
            } label: {
                Label("Clear Pins Older Than 1 Year", systemImage: "calendar.badge.minus")
            }

            Button(role: .destructive) {
                showingClearPinsTwoYearsAlert = true
            } label: {
                Label("Clear Pins Older Than 2 Years", systemImage: "calendar.badge.minus")
            }
        } header: {
            Text("Pinned Media")
        } footer: {
            Text("Manage media pinned from other days. Orphaned pins are those where the original media has been deleted from your library. Current pin count: \(PinnedMediaManager.shared.getPinCount())")
        }
    }

    private var aboutSection: some View {
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
    }

    private var permissionsSection: some View {
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

// MARK: - View Modifiers for Alerts

private struct NotificationAlertModifier: ViewModifier {
    @Binding var showingPermissionAlert: Bool
    @Binding var notificationsEnabled: Bool

    func body(content: Content) -> some View {
        content
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
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

private struct PreferenceAlertsModifier: ViewModifier {
    @Binding var showingClearAllAlert: Bool
    @Binding var showingClearOneYearAlert: Bool
    @Binding var showingClearTwoYearsAlert: Bool

    func body(content: Content) -> some View {
        content
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

private struct PinAlertsModifier: ViewModifier {
    @Binding var showingClearPinsAllAlert: Bool
    @Binding var showingClearPinsOneYearAlert: Bool
    @Binding var showingClearPinsTwoYearsAlert: Bool
    @Binding var showingCleanupOrphanedPinsAlert: Bool

    func body(content: Content) -> some View {
        content
            .alert("Clear All Pinned Media?", isPresented: $showingClearPinsAllAlert) {
                Button("Clear All", role: .destructive) {
                    PinnedMediaManager.shared.cleanupPins(olderThan: .all)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove all media pinned from other days. The original media will remain on their actual dates. This action cannot be undone.")
            }
            .alert("Clear Old Pins?", isPresented: $showingClearPinsOneYearAlert) {
                Button("Clear", role: .destructive) {
                    PinnedMediaManager.shared.cleanupPins(olderThan: .olderThanOneYear)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove pins older than 1 year. This action cannot be undone.")
            }
            .alert("Clear Old Pins?", isPresented: $showingClearPinsTwoYearsAlert) {
                Button("Clear", role: .destructive) {
                    PinnedMediaManager.shared.cleanupPins(olderThan: .olderThanTwoYears)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove pins older than 2 years. This action cannot be undone.")
            }
            .alert("Remove Orphaned Pins?", isPresented: $showingCleanupOrphanedPinsAlert) {
                Button("Remove", role: .destructive) {
                    let count = PinnedMediaManager.shared.cleanupOrphanedPins()
                    print("Removed \(count) orphaned pins")
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove pins for media that no longer exists in your photo library. This action cannot be undone.")
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
