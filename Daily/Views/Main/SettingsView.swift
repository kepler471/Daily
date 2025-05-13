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
/// - Todo reset scheduling
/// - Notification preferences
/// - Options to restore default settings
struct SettingsView: View {
    // MARK: - Properties

    /// Reference to the settings manager for persistent storage
    @EnvironmentObject private var settingsManager: SettingsManager

    /// Reference to the notification manager for notification handling
    @EnvironmentObject private var notificationManager: NotificationManager

    /// Controls visibility of the explanation popover for launch at login
    @State private var showingLaunchExplanation = false

    /// Controls visibility of the confirmation dialog for restoring defaults
    @State private var showingRestoreConfirmation = false

    /// Controls visibility of the login items system settings instructions
    @State private var showingLoginItemsInstructions = false

    /// Controls visibility of the notification explanation popover
    @State private var showingNotificationExplanation = false
    
    // MARK: - Body
    
    var body: some View {
        Form {
            // MARK: General Settings
            
            Section(header: Text("General")) {
                HStack {
                    #if os(macOS)
                    Toggle("Launch at Login", isOn: $settingsManager.launchAtLogin)
                        .toggleStyle(.switch)
                        .accessibilityIdentifier("launchAtLoginToggle")

                    Spacer()
                    #endif

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
                            
                            Text("When enabled, Daily will automatically start when you log in to your Mac. This ensures your todos are always available throughout your workday.")
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
            
            // MARK: Todo Reset Settings

            Section(header: Text("Todo Reset")) {
                HStack {
                    Text("Reset todos daily at:")

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

                Text("Todos will reset automatically at the specified time each day.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // MARK: Notification Settings

            Section(header: Text("Notifications")) {
                HStack {
                    Toggle("Required Todos", isOn: $settingsManager.requiredTodoNotificationsEnabled)
                        .toggleStyle(.switch)
                        .accessibilityIdentifier("requiredTodoNotificationsToggle")

                    Spacer()

                    Button(action: {
                        showingNotificationExplanation = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Notifications help")
                    .popover(isPresented: $showingNotificationExplanation, arrowEdge: .top) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Todo Notifications")
                                .font(.headline)

                            Text("Daily can remind you about your todos at their scheduled times. Enable notifications for the todos you want to be reminded about.")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()

                            Button("OK") {
                                showingNotificationExplanation = false
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding()
                        .frame(width: 300, height: 150)
                    }
                }

                Toggle("Suggested Todos", isOn: $settingsManager.suggestedTodoNotificationsEnabled)
                    .toggleStyle(.switch)
                    .accessibilityIdentifier("suggestedTodoNotificationsToggle")

                HStack {
                    Spacer()

                    Button("Test Notification") {
                        sendTestNotification()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .accessibilityIdentifier("testNotificationButton")
                }

                VStack(alignment: .leading, spacing: 4) {
                    switch notificationManager.authorizationStatus {
                    case .authorized:
                        Text("Notifications are enabled")
                            .font(.caption)
                            .foregroundColor(.green)
                    case .denied:
                        Text("Notifications are disabled in System Settings")
                            .font(.caption)
                            .foregroundColor(.red)
                    case .notDetermined:
                        Text("Notification permission not requested")
                            .font(.caption)
                            .foregroundColor(.orange)
                    case .provisional, .ephemeral:
                        Text("Provisional notification access granted")
                            .font(.caption)
                            .foregroundColor(.blue)
                    @unknown default:
                        Text("Unknown notification status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if notificationManager.isDenied {
                        #if os(macOS)
                        Button("Open Notification Settings") {
                            if let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                                NSWorkspace.shared.open(settingsURL)
                            }
                        }
                        .font(.caption)
                        .padding(.top, 2)
                        #elseif os(iOS)
                        Button("Open Notification Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.caption)
                        .padding(.top, 2)
                        #endif
                    }
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
        .frame(width: 400, height: 400)
        .onAppear {
            // Set up notification observer for login items instructions
            NotificationCenter.default.addObserver(forName: .showLoginItemInstructions,
                                                  object: nil,
                                                  queue: .main) { _ in
                showingLoginItemsInstructions = true
            }
        }
        #if os(macOS)
        .alert("Launch at Login", isPresented: $showingLoginItemsInstructions) {
            Button("Open Login Items") {
                // Open Login Items preferences
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!)
            }
            
            Button("OK", role: .cancel) { }
        } message: {
            Text("To enable 'Launch at Login', open System Settings, go to 'General > Login Items', and add Daily to the list of applications.")
        }
        #endif
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

    /// Sends a test notification to verify notification functionality
    private func sendTestNotification() {
        // Create a notification content
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Your notification settings are working properly!"
        content.sound = .default

        // Create a trigger for immediate delivery (5 seconds from now)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        // Create a request with the content and trigger
        let request = UNNotificationRequest(
            identifier: "com.kepler471.Daily.testNotification",
            content: content,
            trigger: trigger
        )

        // Add the request to the notification center
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("Test notification scheduled successfully")
            } catch {
                print("Error sending test notification: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Previews

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
        .environmentObject(NotificationManager.shared)
}
