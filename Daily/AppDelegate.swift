//
//  AppDelegate.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import SwiftUI
import AppKit
import SwiftData
import UserNotifications

// MARK: - App Delegate

/// AppDelegate to handle the AppKit integration for the menu bar functionality
///
/// This AppDelegate is responsible for:
/// - Configuring the application as a menu bar app
/// - Setting up the menu bar icon and behavior
/// - Creating and configuring the popover that displays the main interface
/// - Coordinating between AppKit and SwiftUI components
class AppDelegate: NSObject, NSApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate {
    // MARK: Properties
    
    /// The menu bar manager that handles the status item and context menu
    private var menuBarManager = MenuBarManager()
    
    /// The popover that contains the main app interface
    private var popover = NSPopover()
    
    /// The SwiftData model container for data persistence
    var modelContainer: ModelContainer?
    
    /// Manager for handling task reset functionality
    var taskResetManager: TaskResetManager?
    
    /// Manager for app settings and preferences
    var settingsManager: SettingsManager?
    
    /// Manager for handling keyboard shortcuts
    private var keyboardShortcutManager = KeyboardShortcutManager()

    /// Manager for handling user notifications
    var notificationManager = NotificationManager.shared
    
    // MARK: - Application Lifecycle
    
    /// Called when the application has finished launching
    /// - Parameter notification: The notification object
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure the application as a menu bar accessory app
        NSApp.setActivationPolicy(.accessory)

        // Set up the menu bar item with our configured popover
        menuBarManager.setupMenuBar(with: popover)

        // Start monitoring for keyboard shortcuts
        keyboardShortcutManager.startMonitoring()

        // Configure notification handling
        setupNotifications()

        // Listen for notification scheduling requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTaskNotificationRequest),
            name: Notification.Name("RequestTaskNotificationScheduling"),
            object: nil
        )

        // Listen for task completion notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTaskCompletion),
            name: Notification.Name("TaskCompletedNotification"),
            object: nil
        )

        // Listen for app becoming active to refresh notification status and fix size
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        // Listen for app being shown to ensure proper size
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ensureProperPopoverSize),
            name: .openDailyPopover,
            object: nil
        )
    }

    /// Ensures the popover has the correct size when shown
    @objc private func ensureProperPopoverSize() {
        // Set the correct size for the popover
        popover.contentSize = NSSize(width: 800, height: 600)

        // Ensure the view controller has the correct size
        if let popoverVC = popover.contentViewController {
            popoverVC.preferredContentSize = NSSize(width: 800, height: 600)

            // Force the view to update its size
            popoverVC.view.setFrameSize(NSSize(width: 800, height: 600))
            popoverVC.view.needsLayout = true
            popoverVC.view.layoutSubtreeIfNeeded()
        }
    }
    
    // MARK: - Popover Configuration
    
    /// Configures the popover with the necessary data context and dependencies
    ///
    /// This method is called after the model container and managers
    /// are passed from DailyApp to the AppDelegate.
    func setupPopoverWithContext() {
        // Ensure all required dependencies are available
        guard let container = modelContainer, 
              let resetManager = taskResetManager,
              let settings = settingsManager else {
            print("Warning: Required dependencies not available.")
            return
        }
        
        // Configure the popover appearance and behavior
        popover.contentSize = NSSize(width: 800, height: 600)
        popover.behavior = .transient // Auto-close when clicking outside
        
        // Create the SwiftUI view for the popover with the proper environment
        let contentView = MainView()
            .modelContainer(container)
            .environmentObject(resetManager)
            .environmentObject(settings)
            .environmentObject(notificationManager)
        
        // Create a hosting controller for the SwiftUI view
        let hostingController = NSHostingController(rootView: contentView)
        
        // Set the hosting view controller as the popover's content
        popover.contentViewController = hostingController
    }
    
    /// Called when the application is about to terminate
    /// - Parameter notification: The notification object
    func applicationWillTerminate(_ notification: Notification) {
        // Stop keyboard shortcut monitoring when the app terminates
        keyboardShortcutManager.stopMonitoring()
    }

    // MARK: - Notification Handling

    /// Set up the notification center delegate and request permission
    private func setupNotifications() {
        // Set this class as the notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Check if this is the first launch
        let defaults = UserDefaults.standard
        let hasLaunchedBefore = defaults.bool(forKey: "hasLaunchedBefore")

        if !hasLaunchedBefore {
            // First launch - explicitly request permission with a slight delay
            // to ensure UI is fully initialized
            print("First launch detected in AppDelegate.setupNotifications()")

            // Use a slight delay to ensure UI is ready and avoid multiple requests
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.notificationManager.requestPermission()
            }
        } else {
            // Initial permission check if needed
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    if settings.authorizationStatus == .notDetermined {
                        // Permission status is undetermined but not first launch
                        // This can happen if previous request didn't complete
                        print("Not first launch but permission not determined - requesting notification permission")
                        self.notificationManager.requestPermission()
                    } else {
                        // Not first launch - just check and update status
                        self.checkAndUpdateNotificationStatus()
                    }
                }
            }
        }
    }

    /// Checks current notification permission status and updates the app state
    @objc private func applicationDidBecomeActive() {
        // Check notification status whenever app becomes active
        print("App became active, checking notification status...")
        checkAndUpdateNotificationStatus()
    }

    private func checkAndUpdateNotificationStatus() {
        // Check the current notification permission status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let isAuthorized = settings.authorizationStatus == .authorized
            let authStatus = settings.authorizationStatus

            print("Current notification auth status: \(authStatus.rawValue) (\(authStatus == .authorized ? "authorized" : authStatus == .denied ? "denied" : authStatus == .notDetermined ? "not determined" : "other"))")

            DispatchQueue.main.async {
                // Update app's knowledge of notification status
                if self.notificationManager.notificationsEnabled != isAuthorized {
                    print("Notification permission changed to: \(isAuthorized)")
                    self.notificationManager.notificationsEnabled = isAuthorized

                    // If this is first launch (.notDetermined) then request permission
                    if authStatus == .notDetermined {
                        print("Not determined status - requesting permission")
                        self.notificationManager.requestPermission()
                    }

                    // Schedule notifications if newly authorized
                    if isAuthorized {
                        self.handleTaskNotificationRequest()
                    }
                }
            }
        }
    }
    
    // MARK: - Notification Request Handlers
    
    @MainActor
    @objc private func handleTaskNotificationRequest() {
        guard let container = modelContainer else {
            print("Cannot schedule notifications: no model container")
            return
        }

        // Only proceed if notifications are enabled
        guard notificationManager.notificationsEnabled else {
            print("Not scheduling notifications because they are disabled")
            return
        }

        print("Fetching tasks for notification scheduling...")

        // Fetch all incomplete tasks
        let descriptor = FetchDescriptor<Task>()

        do {
            let incompleteTasks = try container.mainContext.fetch(descriptor)
            // Forward to notification manager
            // Filter incomplete tasks
            let filteredTasks = incompleteTasks.filter { !$0.isCompleted }
            print("Scheduling notifications for \(filteredTasks.count) incomplete tasks")
            notificationManager.scheduleNotificationsWithTasks(filteredTasks)
        } catch {
            print("Error fetching tasks for notifications: \(error)")
        }
    }
    
    @MainActor
    @objc private func handleTaskCompletion(notification: Notification) {
        guard let container = modelContainer else {
            return
        }
        
        // Check if all required tasks are completed
        let descriptor = FetchDescriptor<Task>()
        
        do {
            let incompleteTasks = try container.mainContext.fetch(descriptor)
            // Filter to get only incomplete required tasks
            let incompleteRequiredTasks = incompleteTasks.filter { !$0.isCompleted && $0.category == .required }
            if incompleteRequiredTasks.isEmpty {
                notificationManager.sendCongratulationsNotification()
            }
        } catch {
            print("Error checking for incomplete tasks: \(error)")
        }
    }
    
    // Handle when the app is launched from a notification
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        // Set proper window size before showing
        if let popoverVC = popover.contentViewController {
            // Ensure proper size is set and respected
            popover.contentSize = NSSize(width: 800, height: 600)
            popoverVC.view.setFrameSize(NSSize(width: 800, height: 600))
            popoverVC.preferredContentSize = NSSize(width: 800, height: 600)
        }

        // Add a slight delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Open the app
            NotificationCenter.default.post(name: .openDailyPopover, object: nil)

            // Handle the notification response
            if response.actionIdentifier == "COMPLETE_ACTION" {
                print("Handling COMPLETE_ACTION response")

                // Extract task ID from userInfo - attempt multiple formats
                let userInfo = response.notification.request.content.userInfo
                print("Notification userInfo: \(userInfo)")

                // Try to get the clean ID first, then the full ID, then fall back to the request identifier
                if let taskIDString = userInfo["taskID"] as? String {
                    print("Found clean taskID in userInfo: \(taskIDString)")
                    self.completeTaskFromNotification(taskIDString: taskIDString)
                } else if let fullTaskID = userInfo["fullTaskID"] as? String {
                    print("Found full taskID in userInfo: \(fullTaskID)")
                    self.completeTaskFromNotification(taskIDString: fullTaskID)
                } else if let taskTitle = userInfo["taskTitle"] as? String {
                    // If we have a title but no ID, try to find by title (fallback)
                    print("Found taskTitle in userInfo: \(taskTitle)")
                    self.completeTaskByTitle(title: taskTitle)
                } else {
                    // Last resort - try to extract from the notification identifier
                    let identifier = response.notification.request.identifier
                    print("No taskID in userInfo, trying to extract from identifier: \(identifier)")

                    if identifier.hasPrefix("task-") {
                        let idString = String(identifier.dropFirst(5)) // Remove "task-" prefix
                        print("Extracted taskID from identifier: \(idString)")
                        self.completeTaskFromNotification(taskIDString: idString)
                    } else {
                        print("Could not extract taskID from notification")
                    }
                }
            }
        }

        completionHandler()
    }

    // Helper to complete a task from a notification on the main actor
    @MainActor
    private func completeTaskFromNotification(taskIDString: String) {
        guard let container = self.modelContainer else {
            print("Error: No model container available for task completion")
            return
        }

        // Find and complete the task
        let descriptor = FetchDescriptor<Task>()

        do {
            // Fetch all tasks
            let tasks = try container.mainContext.fetch(descriptor)
            print("Found \(tasks.count) tasks in database, looking for task with ID: \(taskIDString)")

            // Debug all task IDs
            for task in tasks {
                let currentID = String(describing: task.id)
                print("Task: \(task.title), ID: \(currentID), Matches: \(currentID == taskIDString)")
            }

            // Find the task with matching ID string - using more flexible matching
            let matchingTasks = tasks.filter { task -> Bool in
                let currentID = String(describing: task.id)
                return currentID.contains(taskIDString) || taskIDString.contains(currentID)
            }

            if let task = matchingTasks.first {
                print("Found matching task: \(task.title)")
                // Mark as complete
                task.isCompleted = true
                try container.mainContext.save()
                print("Task marked as completed and saved successfully")

                // Notify completion
                notificationManager.handleTaskCompletion(task)

                // Post notification to update UI if needed
                NotificationCenter.default.post(name: NSNotification.Name("TaskCompletedFromNotification"), object: nil)
            } else {
                print("No matching task found for ID: \(taskIDString)")

                // Try a different approach with UUID parsing
                if let uuidString = taskIDString.components(separatedBy: "(").last?.components(separatedBy: ")").first {
                    print("Trying with extracted UUID: \(uuidString)")

                    if let task = tasks.first(where: { String(describing: $0.id).contains(uuidString) }) {
                        print("Found matching task using UUID extraction: \(task.title)")
                        // Mark as complete
                        task.isCompleted = true
                        try container.mainContext.save()
                        print("Task marked as completed and saved successfully")

                        // Notify completion
                        notificationManager.handleTaskCompletion(task)

                        // Post notification to update UI if needed
                        NotificationCenter.default.post(name: NSNotification.Name("TaskCompletedFromNotification"), object: nil)
                    }
                }
            }
        } catch {
            print("Error completing task from notification: \(error)")
        }
    }
    
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    // Helper to complete a task by title as a fallback mechanism
    @MainActor
    private func completeTaskByTitle(title: String) {
        guard let container = self.modelContainer else {
            print("Error: No model container available for task completion by title")
            return
        }

        // Find and complete the task
        let descriptor = FetchDescriptor<Task>()

        do {
            // Fetch all tasks
            let tasks = try container.mainContext.fetch(descriptor)
            print("Found \(tasks.count) tasks, looking for task with title: \(title)")

            // Find exact title match first
            if let task = tasks.first(where: { $0.title == title }) {
                print("Found exact title match: \(task.title)")
                task.isCompleted = true
                try container.mainContext.save()
                notificationManager.handleTaskCompletion(task)
                NotificationCenter.default.post(name: NSNotification.Name("TaskCompletedFromNotification"), object: nil)
                return
            }

            // If no exact match, try case-insensitive match
            if let task = tasks.first(where: { $0.title.lowercased() == title.lowercased() }) {
                print("Found case-insensitive title match: \(task.title)")
                task.isCompleted = true
                try container.mainContext.save()
                notificationManager.handleTaskCompletion(task)
                NotificationCenter.default.post(name: NSNotification.Name("TaskCompletedFromNotification"), object: nil)
                return
            }

            // Finally, try contains match
            if let task = tasks.first(where: { $0.title.lowercased().contains(title.lowercased()) || title.lowercased().contains($0.title.lowercased()) }) {
                print("Found partial title match: \(task.title)")
                task.isCompleted = true
                try container.mainContext.save()
                notificationManager.handleTaskCompletion(task)
                NotificationCenter.default.post(name: NSNotification.Name("TaskCompletedFromNotification"), object: nil)
                return
            }

            print("No task found with title: \(title)")
        } catch {
            print("Error completing task by title: \(error)")
        }
    }
}
