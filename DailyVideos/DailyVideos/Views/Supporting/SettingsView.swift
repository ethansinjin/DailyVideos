import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = NotificationManager.shared.areNotificationsEnabled
    @State private var notificationTime = NotificationManager.shared.notificationTime
    @State private var showingPermissionAlert = false

    var body: some View {
        NavigationStack {
            List {
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

#Preview {
    SettingsView()
}
