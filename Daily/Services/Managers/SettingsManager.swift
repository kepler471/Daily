//
//  SettingsManager.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import Foundation
import Combine

#if os(macOS)
import ServiceManagement
import AppKit
#elseif os(iOS)
import UIKit
import BackgroundTasks
#endif

// MARK: - Notification Extensions

/// Extension for centralizing notification names used in settings
extension Notification.Name {
    /// Notification to show login item instructions for older macOS versions
    static let showLoginItemInstructions = Notification.Name("showLoginItemInstructions")

    /// Notification for settings updates
    static let settingsUpdated = Notification.Name("settingsUpdated")
}

// MARK: - Settings Manager

/// Manages application settings and preferences
///
/// SettingsManager is responsible for:
/// - Persisting user preferences using UserDefaults
/// - Managing system integration like Launch at Login on macOS
/// - Managing background task scheduling on iOS
/// - Providing observable properties for SwiftUI views
/// - Handling default values and settings reset
class SettingsManager: ObservableObject {
    // MARK: Constants

    /// Keys for UserDefaults persistence
    private enum Keys {
        /// Key for the launch at login preference (macOS only)
        static let launchAtLogin = "launchAtLogin"

        /// Key for the hour at which todos reset
        static let resetHour = "resetHour"

        /// Key for tracking whether login instructions have been shown (macOS only)
        static let hasShownLoginItemInstructions = "hasShownLoginItemInstructions"

        /// Key for whether required todo notifications are enabled
        static let requiredTodoNotificationsEnabled = "requiredTodoNotificationsEnabled"

        /// Key for whether suggested todo notifications are enabled
        static let suggestedTodoNotificationsEnabled = "suggestedTodoNotificationsEnabled"

        /// Key for the default reminder time (in minutes before todo time)
        static let defaultReminderMinutesBefore = "defaultReminderMinutesBefore"

        /// Key for whether haptic feedback is enabled (iOS only)
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"

        /// Key for whether background refresh is enabled (iOS only)
        static let backgroundRefreshEnabled = "backgroundRefreshEnabled"
    }

    // MARK: Common Properties

    /// The hour of the day (0-23) when todos should reset
    @Published var resetHour: Int {
        didSet {
            // Persist the change to UserDefaults
            UserDefaults.standard.set(resetHour, forKey: Keys.resetHour)

            // Update system-specific scheduling
            updateSystemScheduling()

            // Notify listeners of settings change
            NotificationCenter.default.post(name: .settingsUpdated, object: nil)
        }
    }

    /// Whether notifications for required todos are enabled
    @Published var requiredTodoNotificationsEnabled: Bool {
        didSet {
            // Persist the change to UserDefaults
            UserDefaults.standard.set(requiredTodoNotificationsEnabled, forKey: Keys.requiredTodoNotificationsEnabled)

            // Notify listeners of settings change
            NotificationCenter.default.post(name: .settingsUpdated, object: nil)
        }
    }

    /// Whether notifications for suggested todos are enabled
    @Published var suggestedTodoNotificationsEnabled: Bool {
        didSet {
            // Persist the change to UserDefaults
            UserDefaults.standard.set(suggestedTodoNotificationsEnabled, forKey: Keys.suggestedTodoNotificationsEnabled)

            // Notify listeners of settings change
            NotificationCenter.default.post(name: .settingsUpdated, object: nil)
        }
    }

    // MARK: Platform-Specific Properties

    #if os(macOS)
    /// Whether the app should launch automatically at login (macOS only)
    @Published var launchAtLogin: Bool {
        didSet {
            // Persist the change to UserDefaults
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)

            // Update the system login item
            updateLoginItem()

            // Notify listeners of settings change
            NotificationCenter.default.post(name: .settingsUpdated, object: nil)
        }
    }

    /// Helper for constructing the login item identifier (macOS only)
    private var loginItemIdentifier: String {
        return Bundle.main.bundleIdentifier! + ".LaunchAtLogin"
    }
    #endif

    #if os(iOS)
    /// Whether haptic feedback is enabled (iOS only)
    @Published var hapticFeedbackEnabled: Bool {
        didSet {
            // Persist the change to UserDefaults
            UserDefaults.standard.set(hapticFeedbackEnabled, forKey: Keys.hapticFeedbackEnabled)

            // Notify listeners of settings change
            NotificationCenter.default.post(name: .settingsUpdated, object: nil)
        }
    }

    /// Whether background refresh is enabled (iOS only)
    @Published var backgroundRefreshEnabled: Bool {
        didSet {
            // Persist the change to UserDefaults
            UserDefaults.standard.set(backgroundRefreshEnabled, forKey: Keys.backgroundRefreshEnabled)

            // Update background tasks
            updateBackgroundTasks()

            // Notify listeners of settings change
            NotificationCenter.default.post(name: .settingsUpdated, object: nil)
        }
    }
    #endif

    // MARK: - Initialization

    /// Initialize the settings manager with persisted or default values
    init() {
        // Load common settings
        self.resetHour = UserDefaults.standard.integer(forKey: Keys.resetHour)
        self.requiredTodoNotificationsEnabled = UserDefaults.standard.bool(forKey: Keys.requiredTodoNotificationsEnabled)
        self.suggestedTodoNotificationsEnabled = UserDefaults.standard.bool(forKey: Keys.suggestedTodoNotificationsEnabled)

        // Platform-specific settings
        #if os(macOS)
        self.launchAtLogin = UserDefaults.standard.bool(forKey: Keys.launchAtLogin)
        #elseif os(iOS)
        self.hapticFeedbackEnabled = UserDefaults.standard.bool(forKey: Keys.hapticFeedbackEnabled)
        self.backgroundRefreshEnabled = UserDefaults.standard.bool(forKey: Keys.backgroundRefreshEnabled)
        #endif

        // Default to 4am for reset hour if not set
        if self.resetHour == 0 {
            self.resetHour = 4
            UserDefaults.standard.set(self.resetHour, forKey: Keys.resetHour)
        }

        // Default to notifications enabled for required todos only
        if UserDefaults.standard.object(forKey: Keys.requiredTodoNotificationsEnabled) == nil {
            self.requiredTodoNotificationsEnabled = true
            UserDefaults.standard.set(true, forKey: Keys.requiredTodoNotificationsEnabled)
        }

        if UserDefaults.standard.object(forKey: Keys.suggestedTodoNotificationsEnabled) == nil {
            self.suggestedTodoNotificationsEnabled = false
            UserDefaults.standard.set(false, forKey: Keys.suggestedTodoNotificationsEnabled)
        }

        // Default iOS-specific settings
        #if os(iOS)
        if UserDefaults.standard.object(forKey: Keys.hapticFeedbackEnabled) == nil {
            self.hapticFeedbackEnabled = true
            UserDefaults.standard.set(true, forKey: Keys.hapticFeedbackEnabled)
        }

        if UserDefaults.standard.object(forKey: Keys.backgroundRefreshEnabled) == nil {
            self.backgroundRefreshEnabled = true
            UserDefaults.standard.set(true, forKey: Keys.backgroundRefreshEnabled)
        }
        #endif

        // Ensure platform-specific settings are synced on startup
        #if os(macOS)
        updateLoginItem()
        #elseif os(iOS)
        updateBackgroundTasks()
        #endif

        // Set up any system scheduling
        updateSystemScheduling()
    }

    // MARK: - Platform-Specific Settings Management

    #if os(macOS)
    /// Updates the application's login item status based on the launchAtLogin setting (macOS only)
    private func updateLoginItem() {
        if #available(macOS 13.0, *) {
            // Modern Service Management API (macOS 13+)
            do {
                if launchAtLogin {
                    // Register the app to launch at login
                    try SMAppService.mainApp.register()
                } else {
                    // Unregister the app from launching at login
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Error updating login item status: \(error.localizedDescription)")
            }
        } else {
            // For older macOS versions, use UserDefaults and show instructions
            print("Using modern macOS versions is recommended for automatic login item management")

            // When user enables this, notify observers to show a dialog with instructions
            if launchAtLogin && !UserDefaults.standard.bool(forKey: Keys.hasShownLoginItemInstructions) {
                UserDefaults.standard.set(true, forKey: Keys.hasShownLoginItemInstructions)

                // Send notification so the SwiftUI view can show appropriate dialog
                NotificationCenter.default.post(
                    name: .showLoginItemInstructions,
                    object: nil
                )
            }
        }
    }
    #endif

    #if os(iOS)
    /// Updates background tasks based on settings (iOS only)
    private func updateBackgroundTasks() {
        if backgroundRefreshEnabled {
            // Register for background fetch if enabled
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.kepler471.Daily.todoReset", using: nil) { task in
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }

            // Schedule the next background fetch
            scheduleBackgroundRefresh()
        } else {
            // Cancel any scheduled background tasks
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "com.kepler471.Daily.todoReset")
        }
    }

    /// Handles background app refresh (iOS only)
    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule the next background refresh
        scheduleBackgroundRefresh()

        // Set up a task expiration handler
        task.expirationHandler = {
            // Handle task expiration (e.g., cancel any ongoing work)
            print("Background task expired before completion")
        }

        // Post a notification to reset todos
        NotificationCenter.default.post(name: .resetTodaysTodos, object: nil)

        // Mark the task as complete
        task.setTaskCompleted(success: true)
    }

    /// Schedules the next background refresh (iOS only)
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.kepler471.Daily.todoReset")

        // Set the earliest begin date to the next reset time
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = self.resetHour
        components.minute = 0
        components.second = 0

        guard let nextDate = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) else {
            print("Could not determine next reset time")
            return
        }

        request.earliestBeginDate = nextDate

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled for \(nextDate)")
        } catch {
            print("Error scheduling background refresh: \(error.localizedDescription)")
        }
    }
    #endif

    /// Updates system scheduling based on reset hour and other settings
    private func updateSystemScheduling() {
        // Set up scheduling for the reset hour
        #if os(iOS)
        if backgroundRefreshEnabled {
            scheduleBackgroundRefresh()
        }
        #endif

        // Platform-independent code to handle reset scheduling can go here
    }

    // MARK: - Settings Management

    /// Resets all settings to their default values
    func resetToDefaults() {
        // Reset common settings
        resetHour = 4
        requiredTodoNotificationsEnabled = true
        suggestedTodoNotificationsEnabled = false

        // Reset platform-specific settings
        #if os(macOS)
        launchAtLogin = false
        #elseif os(iOS)
        hapticFeedbackEnabled = true
        backgroundRefreshEnabled = true
        updateBackgroundTasks()
        #endif

        // Update system scheduling
        updateSystemScheduling()

        // Notify listeners of settings reset
        NotificationCenter.default.post(name: .settingsUpdated, object: nil)
    }
}
