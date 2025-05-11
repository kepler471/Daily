//
//  SettingsView.swift
//  Daily
//
//  //  Created by Stelios Georgiou on 08/05/2025.
//

import SwiftUI
import UserNotifications

/// A view that provides user interface for configuring app settings
///
/// SettingsView manages configuration options for the application, including:
/// - Launch at login behavior
/// - Task reset scheduling  
/// - Options to restore default settings
struct SettingsView: View {
    // MARK: - Properties
    
    /// Reference to the settings manager for persistent storage
    @EnvironmentObject private var settingsManager: SettingsManager

    /// Reference to the notification manager
    @EnvironmentObject private var notificationManager: NotificationManager
    
    /// Controls visibility of the explanation popover for launch at login
    @State private var showingLaunchExplanation = false
    
    /// Controls visibility of the confirmation dialog for restoring defaults
    @State private var showingRestoreConfirmation = false
    
    /// Controls visibility of the login items system settings instructions
    @State private var showingLoginItemsInstructions = false
    
    // MARK: - Body
    
    var body: some View {
        Form {
            // MARK: General Settings
            
            Section(header: Text("General")) {
                HStack {
                    Toggle("Launch at Login", isOn: $settingsManager.launchAtLogin)
                        .toggleStyle(.switch)
                        .accessibilityIdentifier("launchAtLoginToggle")
                    
                    Spacer()
                    
                    Button(action: {
                        // Show SwiftUI explanation popup
                        showingLaunchExplanation = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Launch at login help")
                    .popover(isPresented: $showingLaunchExplanation, arrowEdge: .top) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Launch at Login")
                                .font(.headline)
                            
                            Text("When enabled, Daily will automatically start when you log in to your Mac. This ensures your tasks are always available throughout your workday.")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                            
                            Button("OK") {
                                showingLaunchExplanation = false
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding()
                        .frame(width: 300, height: 150)
                    }
                }
            }
            
            // MARK: Task Reset Settings

            Section(header: Text("Task Reset")) {
                HStack {
                    Text("Reset tasks daily at:")
                    
                    Spacer()
                    
                    Picker("Reset Hour", selection: $settingsManager.resetHour) {
                        ForEach(0..<24) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 100)
                    .accessibilityIdentifier("resetHourPicker")
                }
                
                Text("Tasks will reset automatically at the specified time each day.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // MARK: Notification Settings

            Section(header: Text("Notifications")) {
                HStack {
                    Text("Notification status: ")
                    Text(notificationManager.notificationsEnabled ? "Enabled" : "Disabled")
                        .foregroundColor(notificationManager.notificationsEnabled ? .green : .red)
                        .fontWeight(.bold)

                    Spacer()

                    Button("Open System Settings") {
                        openNotificationSettings()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
                .help("Notification permissions are managed in System Settings")

                if notificationManager.notificationsEnabled {
                    Divider()

                    DatePicker(
                        "Default reminder time:",
                        selection: $settingsManager.reminderTime,
                        displayedComponents: .hourAndMinute
                    )

                    Toggle("Notify for required tasks", isOn: $settingsManager.notifyForRequiredTasks)
                    Toggle("Notify for suggested tasks", isOn: $settingsManager.notifyForSuggestedTasks)

                    Button("Test Notification") {
                        sendTestNotification()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Text("To receive task reminders, enable notifications in System Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // MARK: Reset to Defaults
            
            Section {
                Button("Restore Defaults") {
                    // Show SwiftUI confirmation dialog
                    showingRestoreConfirmation = true
                }
                .foregroundColor(.red)
                .accessibilityIdentifier("restoreDefaultsButton")
                .confirmationDialog(
                    "Restore Default Settings",
                    isPresented: $showingRestoreConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Cancel", role: .cancel) { }
                    
                    Button("Restore", role: .destructive) {
                        settingsManager.resetToDefaults()
                    }
                } message: {
                    Text("This will reset all settings to their default values. Are you sure you want to continue?")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 300)
        .onAppear {
            // Set up notification observer for login items instructions
            NotificationCenter.default.addObserver(forName: .showLoginItemInstructions,
                                                  object: nil,
                                                  queue: .main) { _ in
                showingLoginItemsInstructions = true
            }
        }
        .alert("Launch at Login", isPresented: $showingLoginItemsInstructions) {
            Button("Open Login Items") {
                // Open Login Items preferences
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!)
            }
            
            Button("OK", role: .cancel) { }
        } message: {
            Text("To enable 'Launch at Login', open System Settings, go to 'General > Login Items', and add Daily to the list of applications.")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Format hour for display in 12-hour format
    /// - Parameter hour: The hour in 24-hour format (0-23)
    /// - Returns: A formatted string in 12-hour format with AM/PM indicator
    private func formatHour(_ hour: Int) -> String {
        let hourIn12Format = hour % 12 == 0 ? 12 : hour % 12
        let amPm = hour < 12 ? "AM" : "PM"
        return "\(hourIn12Format):00 \(amPm)"
    }

    /// Send a test notification to verify settings
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Your notification settings are working!"
        content.sound = UNNotificationSound.default

        // Trigger the notification 2 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)

        // Create the request
        let request = UNNotificationRequest(
            identifier: "test-notification",
            content: content,
            trigger: trigger
        )

        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending test notification: \(error.localizedDescription)")
            }
        }
    }

    /// Open system notification settings
    private func openNotificationSettings() {
        if let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(settingsURL)
        }
    }
}

// MARK: - Previews

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
        .environmentObject(NotificationManager.shared)
}
