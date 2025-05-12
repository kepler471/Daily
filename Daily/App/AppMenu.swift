//
//  AppMenu.swift
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

    /// Notification to show the focused task view
    static let showFocusedTask = Notification.Name("ShowFocusedTask")

    /// Notification to show a specific task in the focused task view
    static let showFocusedTaskWithId = Notification.Name("ShowFocusedTaskWithId")
}

// MARK: - Application Menu Manager

/// Class responsible for setting up the application menus
///
/// This class handles:
/// - Creating standard application menus
/// - Setting up action handlers for menu items
/// - Handling keyboard shortcuts through the menu system
class AppMenuManager: NSObject {
    // MARK: Setup Methods

    /// Set up the application menus
    func setupApplicationMenu() {
        // Create the main menu
        let mainMenu = NSMenu()

        // 1. Application menu (Daily)
        let appMenu = NSMenu()
        let appMenuItem = NSMenuItem(title: "Daily", action: nil, keyEquivalent: "")
        appMenuItem.submenu = appMenu

        // Add items to the app menu
        appMenu.addItem(withTitle: "About Daily", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)

        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide Daily", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")

        let hideOthersItem = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)

        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Daily", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitItem)

        // 2. Tasks menu
        let tasksMenu = NSMenu(title: "Tasks")
        let tasksMenuItem = NSMenuItem(title: "Tasks", action: nil, keyEquivalent: "")
        tasksMenuItem.submenu = tasksMenu

        // Add items to the tasks menu
        let addTaskItem = NSMenuItem(title: "Add Task", action: #selector(addNewTask), keyEquivalent: "n")
        addTaskItem.target = self
        tasksMenu.addItem(addTaskItem)

        let focusedTaskItem = NSMenuItem(title: "Focus on Top Task", action: #selector(showFocusedTask), keyEquivalent: "f")
        focusedTaskItem.target = self
        tasksMenu.addItem(focusedTaskItem)

        let completedItem = NSMenuItem(title: "Show Completed Tasks", action: #selector(showCompletedTasks), keyEquivalent: "c")
        completedItem.target = self
        tasksMenu.addItem(completedItem)

        tasksMenu.addItem(NSMenuItem.separator())

        let resetItem = NSMenuItem(title: "Reset Today's Tasks", action: #selector(resetTasks), keyEquivalent: "r")
        resetItem.target = self
        tasksMenu.addItem(resetItem)

        // 3. Edit menu (standard)
        let editMenu = NSMenu(title: "Edit")
        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        editMenuItem.submenu = editMenu

        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Delete", action: #selector(NSText.delete(_:)), keyEquivalent: "\u{8}")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        // 4. Window menu
        let windowMenu = NSMenu(title: "Window")
        let windowMenuItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        windowMenuItem.submenu = windowMenu

        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")

        // Add menu items to main menu
        mainMenu.addItem(appMenuItem)
        mainMenu.addItem(editMenuItem)
        mainMenu.addItem(tasksMenuItem)
        mainMenu.addItem(windowMenuItem)

        // Set as the application's main menu
        NSApplication.shared.mainMenu = mainMenu

        // Ensure the app has focus to show the menu
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Menu Action Handlers

    /// Shows the add task sheet by posting a notification
    @objc private func addNewTask() {
        // Post notification to trigger add task sheet
        NotificationCenter.default.post(name: .showAddTaskSheet, object: nil)
    }

    /// Shows the completed tasks view by posting a notification
    @objc private func showCompletedTasks() {
        // Post notification to show completed tasks
        NotificationCenter.default.post(name: .showCompletedTasks, object: nil)
    }

    /// Shows the focused task view by posting a notification
    @objc private func showFocusedTask() {
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
}
