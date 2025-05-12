//
//  SettingsManager.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import Foundation
import ServiceManagement
import AppKit
import Combine

// MARK: - Notification Extensions

/// Extension for centralizing notification names used in settings
extension Notification.Name {
    /// Notification to show login item instructions for older macOS versions
    static let showLoginItemInstructions = Notification.Name("showLoginItemInstructions")
}

// MARK: - Settings Manager

/// Manages application settings and preferences
///
/// SettingsManager is responsible for:
/// - Persisting user preferences using UserDefaults
/// - Managing system integration like Launch at Login
/// - Providing observable properties for SwiftUI views
/// - Handling default values and settings reset
class SettingsManager: ObservableObject {
    // MARK: Constants
    
    /// Keys for UserDefaults persistence
    private enum Keys {
        /// Key for the launch at login preference
        static let launchAtLogin = "launchAtLogin"

        /// Key for the hour at which todos reset
        static let resetHour = "resetHour"

        /// Key for tracking whether login instructions have been shown
        static let hasShownLoginItemInstructions = "hasShownLoginItemInstructions"

        /// Key for whether required todo notifications are enabled
        static let requiredTodoNotificationsEnabled = "requiredTodoNotificationsEnabled"

        /// Key for whether suggested todo notifications are enabled
        static let suggestedTodoNotificationsEnabled = "suggestedTodoNotificationsEnabled"

        /// Key for the default reminder time (in minutes before todo time)
        static let defaultReminderMinutesBefore = "defaultReminderMinutesBefore"
    }
    
    // MARK: Properties
    
    /// Whether the app should launch automatically at login
    @Published var launchAtLogin: Bool {
        didSet {
            // Persist the change to UserDefaults
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
            // Update the system login item
            updateLoginItem()
        }
    }
    
    /// The hour of the day (0-23) when todos should reset
    @Published var resetHour: Int {
        didSet {
            // Persist the change to UserDefaults
            UserDefaults.standard.set(resetHour, forKey: Keys.resetHour)
        }
    }

    /// Whether notifications for required todos are enabled
    @Published var requiredTodoNotificationsEnabled: Bool {
        didSet {
            // Persist the change to UserDefaults
            UserDefaults.standard.set(requiredTodoNotificationsEnabled, forKey: Keys.requiredTodoNotificationsEnabled)
        }
    }

    /// Whether notifications for suggested todos are enabled
    @Published var suggestedTodoNotificationsEnabled: Bool {
        didSet {
            // Persist the change to UserDefaults
            UserDefaults.standard.set(suggestedTodoNotificationsEnabled, forKey: Keys.suggestedTodoNotificationsEnabled)
        }
    }
    
    /// Helper for constructing the login item identifier
    private var loginItemIdentifier: String {
        return Bundle.main.bundleIdentifier! + ".LaunchAtLogin"
    }
    
    // MARK: - Initialization
    
    /// Initialize the settings manager with persisted or default values
    init() {
        // Load saved settings or use defaults
        self.launchAtLogin = UserDefaults.standard.bool(forKey: Keys.launchAtLogin)
        self.resetHour = UserDefaults.standard.integer(forKey: Keys.resetHour)
        self.requiredTodoNotificationsEnabled = UserDefaults.standard.bool(forKey: Keys.requiredTodoNotificationsEnabled)
        self.suggestedTodoNotificationsEnabled = UserDefaults.standard.bool(forKey: Keys.suggestedTodoNotificationsEnabled)

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

        // Ensure login item status is synced on startup
        updateLoginItem()
    }
    
    // MARK: - Login Item Management
    
    /// Updates the application's login item status based on the launchAtLogin setting
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
    
    // MARK: - Settings Management
    
    /// Resets all settings to their default values
    func resetToDefaults() {
        launchAtLogin = false
        resetHour = 4
        requiredTodoNotificationsEnabled = true
        suggestedTodoNotificationsEnabled = false
    }
}
