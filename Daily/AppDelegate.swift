//
//  AppDelegate.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import SwiftUI
import AppKit
import SwiftData

// MARK: - App Delegate

/// AppDelegate to handle the AppKit integration for the window app functionality
///
/// This AppDelegate is responsible for:
/// - Configuring the application as a regular windowed app
/// - Coordinating between AppKit and SwiftUI components
/// - Setting up keyboard shortcuts
class AppDelegate: NSObject, NSApplicationDelegate {
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
}
