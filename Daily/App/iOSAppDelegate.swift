//
//  iOSAppDelegate.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/12/2025.
//

import SwiftUI
import UIKit
import SwiftData
import UserNotifications

// MARK: - iOS App Delegate

/// AppDelegate to handle the UIKit integration for iOS functionality
///
/// This AppDelegate is responsible for:
/// - Handling iOS-specific application lifecycle events
/// - Managing notification permissions and handling
/// - Providing shared dependencies to the app
class iOSAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // MARK: Properties
    
    /// The SwiftData model container for data persistence
    var modelContainer: ModelContainer?
    
    /// Manager for handling todo reset functionality
    var todoResetManager: TodoResetManager?
    
    /// Manager for app settings and preferences
    var settingsManager: SettingsManager?
    
    /// Manager for handling notifications
    private var notificationManager = CrossPlatformNotificationManager.shared
    
    // MARK: - Application Lifecycle
    
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
    
    /// Called when the application becomes active
    /// - Parameter application: The singleton UIApplication instance
    func applicationDidBecomeActive(_ application: UIApplication) {
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
                    notificationManager.refreshBadgeCount()
                }
            } else {
                // If model container isn't available, just refresh the badge
                notificationManager.refreshBadgeCount()
            }
        }
    }
    
    /// Called when the application is about to enter the background
    /// - Parameter application: The singleton UIApplication instance
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Refresh badge count when app enters background
        notificationManager.refreshBadgeCount()
    }
    
    /// Sets up the notification manager with the model context
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
    
    // MARK: - Scene Configuration
    
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
    
    // MARK: - User Notification Center Delegate
    
    /// Called when a notification is about to be presented in the foreground
    /// - Parameters:
    ///   - center: The notification center
    ///   - notification: The notification being presented
    ///   - completionHandler: A block to execute with presentation options
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Allow banner, sound, and badge for foreground notifications
        if #available(iOS 14.0, *) {
            completionHandler([.list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
        
        // Ensure badge count is updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.notificationManager.refreshBadgeCount()
        }
    }
    
    /// Called when the user responds to a notification
    /// - Parameters:
    ///   - center: The notification center
    ///   - response: The user's response
    ///   - completionHandler: A block to execute when you're done processing
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
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Refresh badge count
        CrossPlatformNotificationManager.shared.refreshBadgeCount()
    }
    
    /// Called when the scene enters the background
    /// - Parameter scene: The scene that entered the background
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Refresh badge count
        CrossPlatformNotificationManager.shared.refreshBadgeCount()
        
        // Save any changes to the model context
        do {
            let appDelegate = UIApplication.shared.delegate as? iOSAppDelegate
            if let container = appDelegate?.modelContainer {
                let context = ModelContext(container)
                try context.save()
            }
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
}
