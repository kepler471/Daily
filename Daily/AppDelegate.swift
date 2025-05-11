//
//  AppDelegate.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import SwiftUI
import AppKit
import SwiftData
import UserNotifications

// MARK: - App Delegate

/// AppDelegate to handle the AppKit integration for the window app functionality
///
/// This AppDelegate is responsible for:
/// - Configuring the application as a regular windowed app
/// - Coordinating between AppKit and SwiftUI components
/// - Setting up keyboard shortcuts
/// - Managing notification permissions and handling
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    // MARK: Properties

    /// The application menu manager that handles the app menus
    private var appMenuManager = AppMenuManager()

    /// The SwiftData model container for data persistence
    var modelContainer: ModelContainer?

    /// Manager for handling task reset functionality
    var taskResetManager: TaskResetManager?

    /// Manager for app settings and preferences
    var settingsManager: SettingsManager?

    /// Manager for handling keyboard shortcuts
    private var keyboardShortcutManager = KeyboardShortcutManager()

    /// Manager for handling notifications
    private var notificationManager = NotificationManager.shared

    // MARK: - Application Lifecycle

    /// Called when the application has finished launching
    /// - Parameter notification: The notification object
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure the application as a regular windowed app
        NSApp.setActivationPolicy(.regular)

        // Set up the application menu
        appMenuManager.setupApplicationMenu()

        // Start monitoring for keyboard shortcuts
        keyboardShortcutManager.startMonitoring()

        // Set up notification handling and request permissions
        setupNotifications()
    }

    /// Sets up notification handling and requests permissions
    private func setupNotifications() {
        // Set this class as the notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Request notification permission using async/await pattern
        SwiftUI.Task {
            do {
                let (granted, error) = await notificationManager.requestAuthorization()

                if let error = error {
                    print("Error requesting notification permissions: \(error.localizedDescription)")
                }

                if granted {
                    print("Notification permission granted")
                } else {
                    print("Notification permission denied")
                }
            }
        }
    }

    // MARK: - Window Setup

    /// Configures the application with the necessary data context and dependencies
    ///
    /// This method is called after the model container and managers
    /// are passed from DailyApp to the AppDelegate.
    func setupPopoverWithContext() {
        // This method is retained for compatibility but doesn't need to configure a popover anymore
        // since we're using a regular window now

        // We keep the method signature the same to avoid breaking changes elsewhere
        guard modelContainer != nil,
              taskResetManager != nil,
              settingsManager != nil else {
            print("Warning: Required dependencies not available.")
            return
        }

        // No need to set up a popover - SwiftUI will handle window creation
    }
    
    /// Called when the application is about to terminate
    /// - Parameter notification: The notification object
    func applicationWillTerminate(_ notification: Notification) {
        // Stop keyboard shortcut monitoring when the app terminates
        keyboardShortcutManager.stopMonitoring()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification is delivered while the app is in the foreground
    /// - Parameters:
    ///   - center: The notification center
    ///   - notification: The notification that arrived
    ///   - completionHandler: A handler to execute with the presentation options
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Always show notifications even when the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Called when the user responds to a notification
    /// - Parameters:
    ///   - center: The notification center
    ///   - response: The user's response to the notification
    ///   - completionHandler: A completion handler to call when you're done processing the response
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Forward to the notification manager to handle
        SwiftUI.Task {
            await notificationManager.userNotificationCenter(center, didReceive: response)
            completionHandler()
        }
    }
}
