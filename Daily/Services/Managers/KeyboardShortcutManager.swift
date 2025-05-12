//
//  KeyboardShortcutManager.swift
//  Daily
//
//  Created by Stelios Georgiou on 09/05/2025.
//

import SwiftUI

#if os(macOS)
import AppKit

/// Manages global keyboard shortcuts for the application
///
/// This class registers global keyboard event monitors to capture keyboard shortcuts
/// even when the app's UI isn't focused, and dispatches actions via NotificationCenter
/// to maintain the same behavior as menu-triggered actions.
class KeyboardShortcutManager: NSObject {
    // MARK: Properties

    /// The local event monitor for keyboard events
    private var localEventMonitor: Any?

    /// Stores registered keyboard shortcuts and their associated actions
    private var shortcuts: [KeyboardShortcut] = []

    // MARK: - Setup Methods

    /// Initialize and register keyboard shortcuts
    override init() {
        super.init()
        registerShortcuts()
    }

    /// Register standard keyboard shortcuts matching the menu items
    private func registerShortcuts() {
        // Register all the shortcuts that match the menu items
        shortcuts = [
            KeyboardShortcut(key: "f", modifiers: [.command], action: {
                NotificationCenter.default.post(name: .showFocusedTodo, object: nil)
            }),
            KeyboardShortcut(key: "n", modifiers: [.command], action: {
                NotificationCenter.default.post(name: .showAddTodoSheet, object: nil)
            }),
            KeyboardShortcut(key: "c", modifiers: [.command], action: {
                NotificationCenter.default.post(name: .showCompletedTodos, object: nil)
            }),
            KeyboardShortcut(key: "r", modifiers: [.command], action: {
                NotificationCenter.default.post(name: .resetTodaysTodos, object: nil)
            }),
            KeyboardShortcut(key: ",", modifiers: [.command], action: {
                NotificationCenter.default.post(name: .openSettingsWithLink, object: nil)
            })
            // Note: We don't add a Quit shortcut as Cmd+Q is already handled by the system
        ]
    }

    // MARK: - Event Monitor Setup

    /// Start monitoring for keyboard events
    func startMonitoring() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            // Check if the event matches any registered shortcut
            if self.handleKeyEvent(event) {
                // If handled, don't pass the event along
                return nil
            }

            // Otherwise, pass the event along for normal processing
            return event
        }
    }

    /// Stop monitoring for keyboard events
    func stopMonitoring() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    // MARK: - Event Handling

    /// Handle a key event by checking against registered shortcuts
    /// - Parameter event: The NSEvent to check
    /// - Returns: True if the event was handled, false otherwise
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // Extract key and modifiers from the event
        guard let characters = event.charactersIgnoringModifiers else { return false }
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Check each shortcut for a match
        for shortcut in shortcuts {
            if shortcut.matches(key: characters, modifiers: modifiers) {
                // Execute the action for the matching shortcut
                shortcut.action()
                return true
            }
        }

        return false
    }
}

// MARK: - Keyboard Shortcut Model

/// Represents a keyboard shortcut with a key, modifier flags, and action
struct KeyboardShortcut {
    /// The key character (e.g., "n" for new)
    let key: String

    /// Modifier flags (e.g., Command, Option)
    let modifiers: NSEvent.ModifierFlags

    /// The action to perform when the shortcut is triggered
    let action: () -> Void

    /// Check if the given key and modifiers match this shortcut
    /// - Parameters:
    ///   - key: The key string to check
    ///   - modifiers: The modifier flags to check
    /// - Returns: True if the shortcut matches, false otherwise
    func matches(key: String, modifiers: NSEvent.ModifierFlags) -> Bool {
        return self.key == key && self.modifiers == modifiers
    }
}

// MARK: - Notification Extension

// Note: Other notification names are defined in AppMenu.swift

#else
// iOS stub for KeyboardShortcutManager
class KeyboardShortcutManager: NSObject {
    static let shared = KeyboardShortcutManager()

    func startMonitoring() {
        // No-op on iOS
    }

    func stopMonitoring() {
        // No-op on iOS
    }
}
#endif
