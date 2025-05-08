//
//  AppDelegate.swift
//  Daily
//
//  Created with Claude Code.
//

import SwiftUI
import AppKit
import SwiftData

/// AppDelegate to handle the AppKit integration for the menu bar functionality
class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager = MenuBarManager()
    private var popover = NSPopover()
    var modelContainer: ModelContainer?
    var taskResetManager: TaskResetManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure the application
        NSApp.setActivationPolicy(.accessory) // Make it an accessory app instead of a regular app
        
        // Set up the menu bar item with our configured popover
        menuBarManager.setupMenuBar(with: popover)
    }
    
    // This method will be called after the model container is passed from DailyApp
    func setupPopoverWithContext() {
        guard let container = modelContainer, let resetManager = taskResetManager else {
            print("Warning: Model container or reset manager not available.")
            return
        }
        
        // Configure the popover
        popover.contentSize = NSSize(width: 800, height: 600)
        popover.behavior = .transient
        
        // Create the SwiftUI view for the popover with the proper environment
        let contentView = MainView()
            .modelContainer(container)
            .environmentObject(resetManager)
        
        // Create a hosting controller for the SwiftUI view
        let hostingController = NSHostingController(rootView: contentView)
        
        // Set the hosting view controller as the popover's content
        popover.contentViewController = hostingController
    }
}