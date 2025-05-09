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

/// AppDelegate to handle the AppKit integration for the menu bar functionality
///
/// This AppDelegate is responsible for:
/// - Configuring the application as a menu bar app
/// - Setting up the menu bar icon and behavior
/// - Creating and configuring the popover that displays the main interface
/// - Coordinating between AppKit and SwiftUI components
class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: Properties
    
    /// The menu bar manager that handles the status item and context menu
    private var menuBarManager = MenuBarManager()
    
    /// The popover that contains the main app interface
    private var popover = NSPopover()
    
    /// The SwiftData model container for data persistence
    var modelContainer: ModelContainer?
    
    /// Manager for handling task reset functionality
    var taskResetManager: TaskResetManager?
    
    /// Manager for app settings and preferences
    var settingsManager: SettingsManager?
    
    // MARK: - Application Lifecycle
    
    /// Called when the application has finished launching
    /// - Parameter notification: The notification object
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure the application as a menu bar accessory app
        NSApp.setActivationPolicy(.accessory)
        
        // Set up the menu bar item with our configured popover
        menuBarManager.setupMenuBar(with: popover)
    }
    
    // MARK: - Popover Configuration
    
    /// Configures the popover with the necessary data context and dependencies
    ///
    /// This method is called after the model container and managers
    /// are passed from DailyApp to the AppDelegate.
    func setupPopoverWithContext() {
        // Ensure all required dependencies are available
        guard let container = modelContainer, 
              let resetManager = taskResetManager,
              let settings = settingsManager else {
            print("Warning: Required dependencies not available.")
            return
        }
        
        // Configure the popover appearance and behavior
        popover.contentSize = NSSize(width: 800, height: 600)
        popover.behavior = .transient // Auto-close when clicking outside
        
        // Create the SwiftUI view for the popover with the proper environment
        let contentView = MainView()
            .modelContainer(container)
            .environmentObject(resetManager)
            .environmentObject(settings)
        
        // Create a hosting controller for the SwiftUI view
        let hostingController = NSHostingController(rootView: contentView)
        
        // Set the hosting view controller as the popover's content
        popover.contentViewController = hostingController
    }
}
