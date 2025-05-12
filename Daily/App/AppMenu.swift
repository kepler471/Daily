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
    /// Notification to show the add todo sheet
    static let showAddTodoSheet = Notification.Name("ShowAddTodoSheet")

    /// Notification to show completed todos view
    static let showCompletedTodos = Notification.Name("ShowCompletedTodos")

    /// Notification to reset today's todos
    static let resetTodaysTodos = Notification.Name("ResetTodaysTodos")

    /// Notification to open settings using SwiftUI's SettingsLink
    static let openSettingsWithLink = Notification.Name("OpenSettingsWithLink")

    /// Notification to open the main app interface
    static let openDailyApp = Notification.Name("OpenDailyApp")

    /// Notification to show the focused todo view
    static let showFocusedTodo = Notification.Name("ShowFocusedTodo")

    /// Notification to show a specific todo in the focused todo view
    static let showFocusedTodoWithId = Notification.Name("ShowFocusedTodoWithId")

    /// Notification to indicate a todo was completed from outside the TodoStackView
    static let todoCompletedExternally = Notification.Name("TodoCompletedExternally")
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

        // 2. Todos menu
        let todosMenu = NSMenu(title: "Todos")
        let todosMenuItem = NSMenuItem(title: "Todos", action: nil, keyEquivalent: "")
        todosMenuItem.submenu = todosMenu

        // Add items to the todos menu
        let addTodoItem = NSMenuItem(title: "Add Todo", action: #selector(addNewTodo), keyEquivalent: "n")
        addTodoItem.target = self
        todosMenu.addItem(addTodoItem)

        let focusedTodoItem = NSMenuItem(title: "Focus on Top Todo", action: #selector(showFocusedTodo), keyEquivalent: "f")
        focusedTodoItem.target = self
        todosMenu.addItem(focusedTodoItem)

        let completedItem = NSMenuItem(title: "Show Completed Todos", action: #selector(showCompletedTodos), keyEquivalent: "c")
        completedItem.target = self
        todosMenu.addItem(completedItem)

        todosMenu.addItem(NSMenuItem.separator())

        let resetItem = NSMenuItem(title: "Reset Today's Todos", action: #selector(resetTodos), keyEquivalent: "r")
        resetItem.target = self
        todosMenu.addItem(resetItem)

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
        mainMenu.addItem(todosMenuItem)
        mainMenu.addItem(windowMenuItem)

        // Set as the application's main menu
        NSApplication.shared.mainMenu = mainMenu

        // Ensure the app has focus to show the menu
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Menu Action Handlers

    /// Shows the add todo sheet by posting a notification
    @objc private func addNewTodo() {
        // Post notification to trigger add todo sheet
        NotificationCenter.default.post(name: .showAddTodoSheet, object: nil)
    }

    /// Shows the completed todos view by posting a notification
    @objc private func showCompletedTodos() {
        // Post notification to show completed todos
        NotificationCenter.default.post(name: .showCompletedTodos, object: nil)
    }

    /// Shows the focused todo view by posting a notification
    @objc private func showFocusedTodo() {
        // Post notification to show focused todo view
        NotificationCenter.default.post(name: .showFocusedTodo, object: nil)
    }

    /// Resets all todos to incomplete by posting a notification
    @objc private func resetTodos() {
        // Post notification to reset today's todos
        NotificationCenter.default.post(name: .resetTodaysTodos, object: nil)
    }

    /// Opens the settings window using SwiftUI's SettingsLink API
    @objc private func openSettings() {
        // Post notification to open settings using SettingsLink
        NotificationCenter.default.post(name: .openSettingsWithLink, object: nil)
    }
}
