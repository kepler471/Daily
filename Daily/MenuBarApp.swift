//
//  MenuBarApp.swift
//  Daily
//
//  Created with Claude Code.
//

import SwiftUI
import AppKit

/// Class responsible for managing the menu bar functionality of the app
class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    
    /// Set up the menu bar item and popover
    func setupMenuBar(with popover: NSPopover) {
        self.popover = popover
        
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let statusButton = statusItem?.button {
            // Set the menu bar icon (using SFSymbol "checkmark.circle")
            statusButton.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "Daily app")
            statusButton.action = #selector(togglePopover(_:))
            statusButton.target = self
            
            // Set up right-click menu (will be implemented later)
            statusButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Set up an event monitor to detect clicks outside the popover
        setupEventMonitor()
    }
    
    /// Toggle the popover when clicking the status item
    @objc func togglePopover(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type == .rightMouseUp {
            // Handle right-click by showing context menu
            showContextMenu(for: sender)
        } else {
            // Handle left-click by toggling the popover
            togglePopoverVisibility(sender)
        }
    }
    
    /// Show the context menu for right-click
    private func showContextMenu(for button: NSStatusBarButton) {
        // Create the menu
        let menu = NSMenu()
        
        // Add menu items
        menu.addItem(NSMenuItem(title: "Open Daily", action: #selector(openDaily), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Add Task", action: #selector(addNewTask), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Show Completed Tasks", action: #selector(showCompletedTasks), keyEquivalent: "c"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Reset Today's Tasks", action: #selector(resetTasks), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        // Set menu appearance
        menu.appearance = NSAppearance(named: .aqua)
        
        // Display the menu
        menu.popUp(positioning: nil, at: NSPoint(x: button.frame.origin.x, y: button.frame.origin.y - 2), in: button)
    }
    
    // Menu item action handlers
    @objc private func openDaily() {
        if let popover = self.popover, !popover.isShown {
            showPopover(statusItem?.button ?? NSStatusBarButton())
        }
    }
    
    @objc private func addNewTask() {
        // First make sure popover is shown
        if let popover = self.popover, !popover.isShown {
            showPopover(statusItem?.button ?? NSStatusBarButton())
        }
        
        // Post notification to trigger add task sheet
        NotificationCenter.default.post(name: NSNotification.Name("ShowAddTaskSheet"), object: nil)
    }
    
    @objc private func showCompletedTasks() {
        // First make sure popover is shown
        if let popover = self.popover, !popover.isShown {
            showPopover(statusItem?.button ?? NSStatusBarButton())
        }
        
        // Post notification to show completed tasks
        NotificationCenter.default.post(name: NSNotification.Name("ShowCompletedTasks"), object: nil)
    }
    
    @objc private func resetTasks() {
        // Post notification to reset today's tasks
        NotificationCenter.default.post(name: NSNotification.Name("ResetTodaysTasks"), object: nil)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    /// Show or hide the popover
    private func togglePopoverVisibility(_ sender: NSStatusBarButton) {
        if let popover = self.popover {
            if popover.isShown {
                closePopover()
            } else {
                showPopover(sender)
            }
        }
    }
    
    /// Show the popover
    private func showPopover(_ sender: NSStatusBarButton) {
        guard let popover = self.popover, let statusBarButton = statusItem?.button else { return }
        
        // Position the popover below the status item
        popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: .minY)
    }
    
    /// Close the popover
    func closePopover() {
        popover?.performClose(nil)
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
}