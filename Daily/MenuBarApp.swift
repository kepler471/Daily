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
            // Handle right-click (will be implemented later)
            print("Right-clicked on menu bar icon")
            
            // TODO: Implement right-click menu
            // For now, we'll just toggle the popover like left-click
            togglePopoverVisibility(sender)
        } else {
            // Handle left-click
            togglePopoverVisibility(sender)
        }
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