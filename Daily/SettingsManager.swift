//
//  SettingsManager.swift
//  Daily
//
//  Created with Claude Code.
//

import Foundation
import ServiceManagement
import AppKit
import Combine

/// Manages application settings and preferences
class SettingsManager: ObservableObject {
    // Keys for UserDefaults
    private enum Keys {
        static let launchAtLogin = "launchAtLogin"
        static let resetHour = "resetHour"
    }
    
    // Published properties for SwiftUI binding
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLoginItem()
        }
    }
    
    @Published var resetHour: Int {
        didSet {
            UserDefaults.standard.set(resetHour, forKey: Keys.resetHour)
        }
    }
    
    /// Helper for login item identifier
    private var loginItemIdentifier: String {
        return Bundle.main.bundleIdentifier! + ".LaunchAtLogin"
    }
    
    init() {
        // Load saved settings or use defaults
        self.launchAtLogin = UserDefaults.standard.bool(forKey: Keys.launchAtLogin)
        self.resetHour = UserDefaults.standard.integer(forKey: Keys.resetHour)
        
        // Default to 4am for reset hour if not set
        if self.resetHour == 0 {
            self.resetHour = 4
            UserDefaults.standard.set(self.resetHour, forKey: Keys.resetHour)
        }
        
        // Ensure login item status is synced on startup
        updateLoginItem()
    }
    
    /// Updates the application's login item status based on the launchAtLogin setting
    private func updateLoginItem() {
        if #available(macOS 13.0, *) {
            // Modern Service Management API (macOS 13+)
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Error updating login item status: \(error.localizedDescription)")
            }
        } else {
            // For older macOS versions, we'll simply set the preference in UserDefaults
            // and provide instructions for the user to manually set this in System Preferences
            // since the old APIs are now deprecated and difficult to work with in Swift
            print("Using modern macOS versions is recommended for automatic login item management")
            
            // When user enables this, show a dialog with instructions
            if launchAtLogin && !UserDefaults.standard.bool(forKey: "hasShownLoginItemInstructions") {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Launch at Login"
                    alert.informativeText = "To enable 'Launch at Login', open System Settings, go to 'General > Login Items', and add Daily to the list of applications."
                    alert.addButton(withTitle: "OK")
                    alert.addButton(withTitle: "Open Login Items")
                    
                    let response = alert.runModal()
                    if response == .alertSecondButtonReturn {
                        // Open Login Items preferences
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!)
                    }
                    
                    UserDefaults.standard.set(true, forKey: "hasShownLoginItemInstructions")
                }
            }
        }
    }
    
    /// Resets all settings to default values
    func resetToDefaults() {
        launchAtLogin = false
        resetHour = 4
    }
}