//
//  AppDelegate.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import SwiftUI
import SwiftData
import UserNotifications

// Import platform-specific frameworks
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// MARK: - Shared Protocol for AppDelegates

/// Protocol that defines common properties and methods needed by all platform-specific app delegates
protocol DailyAppDelegateProtocol {
    /// The SwiftData model container for data persistence
    var modelContainer: ModelContainer? { get set }
    
    /// Manager for handling todo reset functionality
    var todoResetManager: TodoResetManager? { get set }
    
    /// Manager for app settings and preferences
    var settingsManager: SettingsManager? { get set }
}

// MARK: - macOS AppDelegate

#if os(macOS)
/// AppDelegate implementation for macOS
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate, DailyAppDelegateProtocol {
    /// The SwiftData model container for data persistence
    var modelContainer: ModelContainer?
    
    /// Manager for handling todo reset functionality
    var todoResetManager: TodoResetManager?
    
    /// Manager for app settings and preferences
    var settingsManager: SettingsManager?
    
    /// Manager for handling notifications
    private var notificationManager = NotificationManager.shared
    
    /// The application menu manager that handles the app menus
    private var appMenuManager = AppMenuManager()
    
    /// Manager for handling keyboard shortcuts
    private var keyboardShortcutManager = KeyboardShortcutManager()
    
    /// Called when the application has finished launching
    /// - Parameter notification: The notification object
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure the application as a regular windowed app
        NSApp.setActivationPolicy(.regular)
        
        // Set up the application menu
        appMenuManager.setupApplicationMenu()
        
        // Start monitoring for keyboard shortcuts
        keyboardShortcutManager.startMonitoring()
        
        // Set up notification handling
        UNUserNotificationCenter.current().delegate = self
        setupNotifications()
    }
    
    /// Called when the application is about to terminate
    /// - Parameter notification: The notification object
    func applicationWillTerminate(_ notification: Notification) {
        // Stop keyboard shortcut monitoring when the app terminates
        keyboardShortcutManager.stopMonitoring()
    }
    
    /// Called when the application becomes active
    /// - Parameter notification: The notification object
    func applicationDidBecomeActive(_ notification: Notification) {
        syncNotificationsWithDatabase()
    }
    
    /// Called when the application deactivates
    /// - Parameter notification: The notification object
    @MainActor
    func applicationDidResignActive(_ notification: Notification) {
        // Refresh the badge count when the app deactivates
        Task {
            await notificationManager.refreshBadgeCount()
        }
    }
    
    /// Sets up the application context and dependencies
    func setupPopoverWithContext() {
        // Set up the model context for the notification manager
        guard let container = modelContainer else {
            print("Warning: ModelContainer not available.")
            return
        }
        
        // Set the model context for the notification manager
        let context = ModelContext(container)
        notificationManager.setModelContext(context)
        
        print("ModelContext set for NotificationManager in macOS AppDelegate")
    }
    
    /// Synchronizes notifications with the database
    private func syncNotificationsWithDatabase() {
        // When app becomes active, synchronize notifications with database
        Task {
            // Get all todos from the database
            if let container = modelContainer {
                let context = ModelContext(container)
                do {
                    // Fetch all todos from the database
                    let todos = try context.fetchTodos()
                    
                    // Synchronize notifications with the database
                    await notificationManager.synchronizeNotificationsWithDatabase(todos: todos)
                } catch {
                    print("Error fetching todos for notification sync: \(error)")
                    // If we can't fetch todos, just refresh the badge count
                    Task {
                        await notificationManager.refreshBadgeCount()
                    }
                }
            } else {
                // If model container isn't available, just refresh the badge
                Task {
                    await notificationManager.refreshBadgeCount()
                }
            }
        }
    }
    
    /// Sets up notification handling and requests permissions
    private func setupNotifications() {
        // Request notification permission using async/await pattern
        Task {
            let (granted, error) = await notificationManager.requestAuthorization()
            
            if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            }
            
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Called when a notification is about to be presented in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Allow banner, sound, and badge for foreground notifications
        completionHandler([.banner, .sound, .badge])
        
        // Ensure badge count is updated after the notification is shown
        Task { @MainActor in
            // Small delay to ensure notification is processed
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            await notificationManager.refreshBadgeCount()
        }
    }
    
    /// Called when the user responds to a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Forward handling to the notification manager
        Task {
            await notificationManager.userNotificationCenter(center, didReceive: response)
            completionHandler()
        }
    }
}

#elseif os(iOS)
// MARK: - iOS AppDelegate

/// AppDelegate implementation for iOS
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, DailyAppDelegateProtocol {
    /// The SwiftData model container for data persistence
    var modelContainer: ModelContainer?
    
    /// Manager for handling todo reset functionality
    var todoResetManager: TodoResetManager?
    
    /// Manager for app settings and preferences
    var settingsManager: SettingsManager?
    
    /// Manager for handling notifications
    private var notificationManager = NotificationManager.shared
    
    /// Called when the application finishes launching
    /// - Parameters:
    ///   - application: The singleton UIApplication instance
    ///   - launchOptions: A dictionary indicating the reason the app was launched
    /// - Returns: True if the app should continue to finish launching
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Set up UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions
        setupNotifications()
        
        return true
    }
    
    /// Called when a new scene session is being created
    /// - Parameters:
    ///   - application: The singleton UIApplication instance
    ///   - connectingSceneSession: The session being created
    ///   - options: Options for configuring the scene
    /// - Returns: The scene configuration object
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Create a default scene configuration
        let sceneConfig = UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
        
        // Set the delegate class
        sceneConfig.delegateClass = iOSSceneDelegate.self
        
        return sceneConfig
    }
    
    /// Called when the application is about to enter the background
    /// - Parameter application: The singleton UIApplication instance
    @MainActor
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Refresh badge count when app enters background
        Task {
            await notificationManager.refreshBadgeCount()
        }
    }
    
    /// Called when the application becomes active
    /// - Parameter application: The singleton UIApplication instance
    @MainActor
    func applicationDidBecomeActive(_ application: UIApplication) {
        syncNotificationsWithDatabase()
    }
    
    /// Sets up the application context and dependencies
    func setupWithContext() {
        // Set up the model context for the notification manager
        guard let container = modelContainer else {
            print("Warning: ModelContainer not available.")
            return
        }
        
        // Set the model context for the notification manager
        let context = ModelContext(container)
        notificationManager.setModelContext(context)
        
        print("ModelContext set for NotificationManager in iOS AppDelegate")
    }
    
    /// Synchronizes notifications with the database
    private func syncNotificationsWithDatabase() {
        // When app becomes active, synchronize notifications with database
        Task {
            // Get all todos from the database
            if let container = modelContainer {
                let context = ModelContext(container)
                do {
                    // Fetch all todos from the database
                    let todos = try context.fetchTodos()
                    
                    // Synchronize notifications with the database
                    await notificationManager.synchronizeNotificationsWithDatabase(todos: todos)
                } catch {
                    print("Error fetching todos for notification sync: \(error)")
                    // If we can't fetch todos, just refresh the badge count
                    Task {
                        await notificationManager.refreshBadgeCount()
                    }
                }
            } else {
                // If model container isn't available, just refresh the badge
                Task {
                    await notificationManager.refreshBadgeCount()
                }
            }
        }
    }
    
    /// Sets up notification handling and requests permissions
    private func setupNotifications() {
        // Request notification permission using async/await pattern
        Task {
            let (granted, error) = await notificationManager.requestAuthorization()
            
            if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            }
            
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Called when a notification is about to be presented in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Allow banner, sound, and badge for foreground notifications
        if #available(iOS 14.0, *) {
            completionHandler([.list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
        
        // Ensure badge count is updated
        Task {
            await notificationManager.refreshBadgeCount()
        }
    }
    
    /// Called when the user responds to a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Forward handling to the notification manager
        Task {
            await notificationManager.userNotificationCenter(center, didReceive: response)
            completionHandler()
        }
    }
}

// MARK: - iOS Scene Delegate

/// Manages the UIScene lifecycle for the iOS app
class iOSSceneDelegate: UIResponder, UIWindowSceneDelegate {
    /// The app's window
    var window: UIWindow?
    
    /// Called when the scene has been connected to the app
    /// - Parameters:
    ///   - scene: The scene that has connected
    ///   - session: The session the scene is associated with
    ///   - connectionOptions: Options for configuring the scene
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Handle scene connection
        
        // Process notification if app was launched from a notification
        if let userInfo = connectionOptions.notificationResponse?.notification.request.content.userInfo,
           let todoId = userInfo["todoId"] as? String {
            // Store todo ID in UserDefaults for retrieval by the main view
            UserDefaults.standard.set(todoId, forKey: "pendingTodoId")
            UserDefaults.standard.set(Date(), forKey: "pendingTodoIdTimestamp")
            
            // Post a notification that will be handled in the SwiftUI view hierarchy
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NotificationCenter.default.post(
                    name: .showFocusedTodoWithId,
                    object: nil,
                    userInfo: ["todoId": todoId]
                )
            }
        }
    }
    
    /// Called when the scene becomes active
    /// - Parameter scene: The scene that became active
    @MainActor
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Refresh badge count
        Task {
            await NotificationManager.shared.refreshBadgeCount()
        }
    }
    
    /// Called when the scene enters the background
    /// - Parameter scene: The scene that entered the background
    @MainActor
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Refresh badge count
        Task {
            await NotificationManager.shared.refreshBadgeCount()
        }
        
        // Save any changes to the model context
        do {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            if let container = appDelegate?.modelContainer {
                let context = ModelContext(container)
                try context.save()
            }
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
}
#endif