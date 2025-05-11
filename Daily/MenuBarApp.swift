//
//  MenuBarApp.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import AppKit

// MARK: - Notification Constants

/// Extension for centralizing notification names used in the app
extension Notification.Name {
    /// Notification to show the add task sheet
    static let showAddTaskSheet = Notification.Name("ShowAddTaskSheet")

    /// Notification to show completed tasks view
    static let showCompletedTasks = Notification.Name("ShowCompletedTasks")

    /// Notification to reset today's tasks
    static let resetTodaysTasks = Notification.Name("ResetTodaysTasks")

    /// Notification to open settings using SwiftUI's SettingsLink
    static let openSettingsWithLink = Notification.Name("OpenSettingsWithLink")

    /// Notification to open the main app interface
    static let openDailyApp = Notification.Name("OpenDailyApp")

    /// Notification to show the popover (used internally)
    static let openDailyPopover = Notification.Name("OpenDailyPopover")

    /// Notification to show the focused task view
    static let showFocusedTask = Notification.Name("ShowFocusedTask")
}

// MARK: - Menu Bar Manager

/// Class responsible for managing the menu bar functionality of the app
///
/// This class handles:
/// - Creating and configuring the status item in the macOS menu bar
/// - Managing the popover that appears when clicking the status item
/// - Creating and handling the right-click context menu
/// - Detecting clicks outside the popover to automatically close it
class MenuBarManager: NSObject {
    // MARK: Properties
    
    /// The menu bar status item that displays the app icon
    private var statusItem: NSStatusItem?
    
    /// The popover that contains the main app interface
    private var popover: NSPopover?
    
    /// Event monitor for detecting clicks outside the popover
    private var eventMonitor: Any?
    
    // MARK: Setup Methods
    
    /// Set up the menu bar item and popover
    /// - Parameter popover: The configured NSPopover to display when clicking the menu bar item
    func setupMenuBar(with popover: NSPopover) {
        self.popover = popover
        
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let statusButton = statusItem?.button {
            // Set the menu bar icon (using SFSymbol "checkmark.circle")
            statusButton.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "Daily app")
            statusButton.action = #selector(togglePopover(_:))
            statusButton.target = self
            
            // Configure to recognize both left and right clicks
            statusButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Set up an event monitor to detect clicks outside the popover
        setupEventMonitor()
        
        // Set up notification handlers for keyboard shortcuts
        setupNotificationHandlers()
    }
    
    /// Set up notification handlers for keyboard shortcut actions
    private func setupNotificationHandlers() {
        // Handle popover opening notification (internal)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowPopover),
            name: .openDailyPopover,
            object: nil
        )
    }
    
    /// Handle request to show the popover from other components
    @objc private func handleShowPopover() {
        if let button = statusItem?.button, let popover = self.popover, !popover.isShown {
            // Ensure popover is properly sized when shown
            ensurePopoverSize(popover)

            // Show the popover with the correct size
            showPopover(button)
        }
    }

    /// Ensures the popover has the correct size before showing
    private func ensurePopoverSize(_ popover: NSPopover) {
        // Reset the correct size
        popover.contentSize = NSSize(width: 800, height: 600)

        // Update the view controller's preferred size
        if let popoverVC = popover.contentViewController {
            popoverVC.preferredContentSize = NSSize(width: 800, height: 600)

            // Force the view to update its size
            let view = popoverVC.view
            view.setFrameSize(NSSize(width: 800, height: 600))
            view.needsLayout = true
            view.layoutSubtreeIfNeeded()
        }
    }
    
    /// Set up the event monitor to detect clicks outside the popover
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let popover = self.popover else { return }
            
            if popover.isShown {
                self.closePopover()
            }
        }
    }
    
    // MARK: - Status Item Interaction
    
    /// Handle clicks on the status item
    /// - Parameter sender: The status bar button that was clicked
    @objc func togglePopover(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Handle right-click by showing context menu
            showContextMenu(for: sender)
        } else {
            // Handle left-click by toggling the popover
            togglePopoverVisibility(sender)

            // Show focused task view if there are any required tasks to complete
            checkAndShowFocusedTaskIfNeeded()
        }
    }

    /// Show or hide the popover based on its current state
    /// - Parameter sender: The status bar button
    private func togglePopoverVisibility(_ sender: NSStatusBarButton) {
        if let popover = self.popover {
            if popover.isShown {
                closePopover()
            } else {
                showPopover(sender)
            }
        }
    }

    /// Check if there are required tasks and show the focused task view
    private func checkAndShowFocusedTaskIfNeeded() {
        // Show focused task view after a short delay to let the popover appear first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Post notification to show the focused task view
            NotificationCenter.default.post(name: .showFocusedTask, object: nil)
        }
    }
    
    /// Show the popover below the status item
    /// - Parameter sender: The status bar button to anchor the popover to
    private func showPopover(_ sender: NSStatusBarButton) {
        guard let popover = self.popover, let statusBarButton = statusItem?.button else { return }

        // Ensure proper size before showing
        ensurePopoverSize(popover)

        // Position the popover below the status item
        popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: .minY)

        // Additional size enforcement after showing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Re-apply size after popover is visible
            if let vc = popover.contentViewController {
                vc.preferredContentSize = NSSize(width: 800, height: 600)
                popover.contentSize = NSSize(width: 800, height: 600)
            }
        }
    }
    
    /// Close the popover if it's open
    func closePopover() {
        popover?.performClose(nil)
    }
    
    // MARK: - Context Menu
    
    /// Show the context menu for right-click on the status item
    /// - Parameter button: The status bar button that was right-clicked
    private func showContextMenu(for button: NSStatusBarButton) {
        // Create the menu
        let menu = NSMenu()

        // Add menu items
        let focusedTaskItem = NSMenuItem(title: "Focus on Top Task", action: #selector(showFocusedTask), keyEquivalent: "f")
        focusedTaskItem.target = self
        menu.addItem(focusedTaskItem)

        let addTaskItem = NSMenuItem(title: "Add Task", action: #selector(addNewTask), keyEquivalent: "n")
        addTaskItem.target = self
        menu.addItem(addTaskItem)

        let completedItem = NSMenuItem(title: "Show Completed Tasks", action: #selector(showCompletedTasks), keyEquivalent: "c")
        completedItem.target = self
        menu.addItem(completedItem)

        let resetItem = NSMenuItem(title: "Reset Today's Tasks", action: #selector(resetTasks), keyEquivalent: "r")
        resetItem.target = self
        menu.addItem(resetItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Daily", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        // Display the menu at the standard position for status bar items
        // Convert the button's frame to window coordinates and use the bottom of the button
        let buttonRect = button.convert(button.bounds, to: nil)
        let screenRect = button.window?.convertToScreen(buttonRect)
        let menuPosition = NSPoint(x: screenRect?.midX ?? 0, y: (screenRect?.minY ?? 0) - 2)
        
        // Use standard AppKit behavior for positioning
        menu.popUp(positioning: nil, at: menuPosition, in: nil)
    }
    
    // MARK: - Menu Action Handlers
    
    /// Opens the main app interface by showing the popover
    @objc private func openDaily() {
        if let popover = self.popover, !popover.isShown {
            showPopover(statusItem?.button ?? NSStatusBarButton())

            // Show focused task view when opening the app
            checkAndShowFocusedTaskIfNeeded()
        }
    }
    
    /// Shows the add task sheet by posting a notification
    @objc private func addNewTask() {
        // First make sure popover is shown
        if let popover = self.popover, !popover.isShown {
            showPopover(statusItem?.button ?? NSStatusBarButton())
        }
        
        // Post notification to trigger add task sheet
        NotificationCenter.default.post(name: .showAddTaskSheet, object: nil)
    }
    
    /// Shows the completed tasks view by posting a notification
    @objc private func showCompletedTasks() {
        // First make sure popover is shown
        if let popover = self.popover, !popover.isShown {
            showPopover(statusItem?.button ?? NSStatusBarButton())
        }

        // Post notification to show completed tasks
        NotificationCenter.default.post(name: .showCompletedTasks, object: nil)
    }

    /// Shows the focused task view by posting a notification
    @objc private func showFocusedTask() {
        // First make sure popover is shown
        if let popover = self.popover, !popover.isShown {
            showPopover(statusItem?.button ?? NSStatusBarButton())
        }

        // Post notification to show focused task view
        NotificationCenter.default.post(name: .showFocusedTask, object: nil)
    }
    
    /// Resets all tasks to incomplete by posting a notification
    @objc private func resetTasks() {
        // Post notification to reset today's tasks
        NotificationCenter.default.post(name: .resetTodaysTasks, object: nil)
    }
    
    /// Opens the settings window using SwiftUI's SettingsLink API
    @objc private func openSettings() {
        // Post notification to open settings using SettingsLink
        NotificationCenter.default.post(name: .openSettingsWithLink, object: nil)
    }
    
    /// Terminates the application
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
