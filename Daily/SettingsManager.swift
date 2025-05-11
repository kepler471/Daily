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
import UserNotifications

// MARK: - UserDefaults Extension

extension UserDefaults {
    /// Check if a key exists in UserDefaults
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}

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
        
        /// Key for the hour at which tasks reset
        static let resetHour = "resetHour"
        
        /// Key for tracking whether login instructions have been shown
        static let hasShownLoginItemInstructions = "hasShownLoginItemInstructions"
        
        /// Key for notification reminder time
        static let reminderTime = "reminderTime"
        
        /// Key for whether to notify for required tasks
        static let notifyForRequiredTasks = "notifyForRequiredTasks"
        
        /// Key for whether to notify for suggested tasks
        static let notifyForSuggestedTasks = "notifyForSuggestedTasks"
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
    
    /// The hour of the day (0-23) when tasks should reset
    @Published var resetHour: Int {
        didSet {
            // Persist the change to UserDefaults
            UserDefaults.standard.set(resetHour, forKey: Keys.resetHour)
        }
    }
    
    /// The time of day for general task reminders
    @Published var reminderTime: Date {
        didSet {
            if let timeData = try? JSONEncoder().encode(reminderTime) {
                UserDefaults.standard.set(timeData, forKey: Keys.reminderTime)
                // Update notification schedules when this changes
                NotificationManager.shared.reminderTime = reminderTime
                NotificationManager.shared.refreshNotifications()
            }
        }
    }
    
    /// Whether to send notifications for required tasks
    @Published var notifyForRequiredTasks: Bool {
        didSet {
            UserDefaults.standard.set(notifyForRequiredTasks, forKey: Keys.notifyForRequiredTasks)
            // Update notification preferences
            NotificationManager.shared.notifyForRequiredTasks = notifyForRequiredTasks
            NotificationManager.shared.refreshNotifications()
        }
    }
    
    /// Whether to send notifications for suggested tasks
    @Published var notifyForSuggestedTasks: Bool {
        didSet {
            UserDefaults.standard.set(notifyForSuggestedTasks, forKey: Keys.notifyForSuggestedTasks)
            // Update notification preferences
            NotificationManager.shared.notifyForSuggestedTasks = notifyForSuggestedTasks
            NotificationManager.shared.refreshNotifications()
        }
    }
    
    /// Helper for constructing the login item identifier
    private var loginItemIdentifier: String {
        return Bundle.main.bundleIdentifier! + ".LaunchAtLogin"
    }
    
    // MARK: - Initialization
    
    /// Initialize the settings manager with persisted or default values
    init() {
        // Initialize properties with default values first
        self.launchAtLogin = false
        self.resetHour = 4
        self.reminderTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
        self.notifyForRequiredTasks = true
        self.notifyForSuggestedTasks = false
        
        // Then load saved values
        self.launchAtLogin = UserDefaults.standard.bool(forKey: Keys.launchAtLogin)
        let savedResetHour = UserDefaults.standard.integer(forKey: Keys.resetHour)
        
        // Only update if there's a value stored
        if savedResetHour > 0 {
            self.resetHour = savedResetHour
        } else {
            // Save default value
            UserDefaults.standard.set(self.resetHour, forKey: Keys.resetHour)
        }
        
        // Load notification settings or use defaults
        if let reminderData = UserDefaults.standard.data(forKey: Keys.reminderTime),
           let decodedTime = try? JSONDecoder().decode(Date.self, from: reminderData) {
            self.reminderTime = decodedTime
        } else {
            // Save default value
            if let timeData = try? JSONEncoder().encode(self.reminderTime) {
                UserDefaults.standard.set(timeData, forKey: Keys.reminderTime)
            }
        }
        
        // Load notification type preferences
        if UserDefaults.standard.contains(key: Keys.notifyForRequiredTasks) {
            self.notifyForRequiredTasks = UserDefaults.standard.bool(forKey: Keys.notifyForRequiredTasks)
        } else {
            // Save default value
            UserDefaults.standard.set(self.notifyForRequiredTasks, forKey: Keys.notifyForRequiredTasks)
        }
        
        if UserDefaults.standard.contains(key: Keys.notifyForSuggestedTasks) {
            self.notifyForSuggestedTasks = UserDefaults.standard.bool(forKey: Keys.notifyForSuggestedTasks)
        } else {
            // Save default value
            UserDefaults.standard.set(self.notifyForSuggestedTasks, forKey: Keys.notifyForSuggestedTasks)
        }
        
        // Ensure login item status is synced on startup
        updateLoginItem()
        
        // Sync these values to the notification manager after initialization
        DispatchQueue.main.async {
            NotificationManager.shared.reminderTime = self.reminderTime
            NotificationManager.shared.notifyForRequiredTasks = self.notifyForRequiredTasks
            NotificationManager.shared.notifyForSuggestedTasks = self.notifyForSuggestedTasks
        }
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
        reminderTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
        notifyForRequiredTasks = true
        notifyForSuggestedTasks = false

        // Cancel all notifications and then reschedule based on new settings
        NotificationManager.shared.cancelAllNotifications()
        NotificationManager.shared.refreshNotifications()
    }
}