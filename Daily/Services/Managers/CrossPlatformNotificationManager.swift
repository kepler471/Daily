//
//  CrossPlatformNotificationManager.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/12/2025.
//

import Foundation
import UserNotifications
import SwiftUI
import SwiftData
import Observation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Centralized manager for handling app notifications across platforms
///
/// NotificationManager is responsible for:
/// - Requesting and checking notification permissions
/// - Scheduling notifications for todos
/// - Handling notification interactions
/// - Managing notification categories and actions
/// - Badge management across platforms
class CrossPlatformNotificationManager: NSObject, ObservableObject {
    // MARK: - Shared Instance
    
    /// Shared instance for the notification manager (singleton)
    static let shared = CrossPlatformNotificationManager()
    
    // MARK: - Properties

    /// Current authorization status for notifications
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Whether notifications are authorized
    var isAuthorized: Bool {
        return authorizationStatus == .authorized
    }

    /// Whether notifications are in a denied state
    var isDenied: Bool {
        return authorizationStatus == .denied
    }

    /// The notification center for the app
    private let notificationCenter = UNUserNotificationCenter.current()

    /// The model context for database operations
    private var modelContextReference: ModelContext?

    /// The model container reference used to create new contexts when needed
    private var modelContainer: ModelContainer?

    /// Get an active model context for performing database operations
    private var activeModelContext: ModelContext? {
        // If we have a direct reference, use it
        if let context = modelContextReference {
            return context
        }

        // If we have a container, create a new context
        if let container = modelContainer {
            return ModelContext(container)
        }

        return nil
    }

    /// Set the model context for database operations
    func setModelContext(_ context: ModelContext) {
        self.modelContextReference = context

        // Store the container reference as well for creating new contexts if needed
        self.modelContainer = context.container
        print("ModelContainer stored in NotificationManager")
    }
    
    // MARK: - Constants

    /// Category identifier for todo notifications
    static let todoCategoryIdentifier = "com.kepler471.Daily.todoNotification"

    /// Action identifier for completing a todo from a notification
    static let completeTodoActionIdentifier = "com.kepler471.Daily.completeTodo"

    /// Action identifier for dismissing a notification
    static let dismissActionIdentifier = "com.kepler471.Daily.dismissNotification"

    /// Notification identifier prefix for todo notifications
    static let todoNotificationIdentifierPrefix = "com.kepler471.Daily.todo."
    
    // MARK: - Initialization

    /// Private initializer to enforce singleton pattern
    private override init() {
        super.init()

        // Set this class as the notification center delegate
        notificationCenter.delegate = self

        // Set up notification categories and actions
        setupNotificationCategories()

        // Get the current authorization status using a synchronous approach
        notificationCenter.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus

                // If authorized, refresh the badge count
                if settings.authorizationStatus == .authorized {
                    self.refreshBadgeCount()
                }
            }
        }
    }
    
    // MARK: - Permission Management
    
    /// Refreshes the current notification authorization status
    /// - Returns: The current authorization status
    @MainActor
    func refreshAuthorizationStatus() async {
        let status = await getAuthorizationStatus()
        self.authorizationStatus = status
    }
    
    /// Gets the current authorization status from the notification center
    /// - Returns: The current authorization status
    private func getAuthorizationStatus() async -> UNAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            notificationCenter.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }
    
    /// Requests authorization for notifications with modern error handling
    /// - Returns: A tuple containing whether authorization was granted and any error
    @discardableResult
    @MainActor
    func requestAuthorization() async -> (Bool, Error?) {
        do {
            // Request authorization for alerts, sounds, and badges
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            // Update the stored authorization status
            await refreshAuthorizationStatus()

            return (granted, nil)
        } catch {
            print("Error requesting notification authorization: \(error.localizedDescription)")
            return (false, error)
        }
    }
    
    /// Opens the system notification settings for the app
    func openNotificationSettings() {
        #if os(macOS)
        // Open the System Preferences/Settings and go to Notifications
        if let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(settingsURL)
        }
        #elseif os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
    
    // MARK: - Notification Categories Setup

    /// Sets up notification categories and actions
    private func setupNotificationCategories() {
        // Create the "Complete" action for todo notifications
        let completeAction = UNNotificationAction(
            identifier: Self.completeTodoActionIdentifier,
            title: "Complete",
            options: .foreground
        )

        // Create the "Dismiss" action for explicit dismissal
        let dismissAction = UNNotificationAction(
            identifier: Self.dismissActionIdentifier,
            title: "Dismiss",
            options: .destructive
        )

        // Create the category for todo notifications with the complete action
        let categoryOptions: UNNotificationCategoryOptions = []

        let todoCategory = UNNotificationCategory(
            identifier: Self.todoCategoryIdentifier,
            actions: [completeAction, dismissAction],
            intentIdentifiers: [],
            options: categoryOptions
        )

        // Register the category with the notification center
        notificationCenter.setNotificationCategories([todoCategory])
    }

    // MARK: - Todo Notification Management

    /// Schedule a notification for a todo
    /// - Parameters:
    ///   - todo: The todo to schedule a notification for
    ///   - settings: The settings manager to check notification preferences
    ///
    /// The notification will repeat daily at the specified time using a calendar trigger
    /// with hour and minute components, ensuring notifications continue even if the app
    /// is not running at reset time.
    @MainActor
    func scheduleNotification(for todo: Daily.Todo, settings: SettingsManager) async {
        // First ensure we have notification permission
        if !isAuthorized {
            return
        }

        // Log the todo's UUID for debugging
        print("Scheduling notification for todo: \(todo.title) with UUID: \(todo.uuid.uuidString)")

        // Check if notifications are enabled for this todo category
        switch todo.category {
        case .required:
            if !settings.requiredTodoNotificationsEnabled {
                return
            }
        case .suggested:
            if !settings.suggestedTodoNotificationsEnabled {
                return
            }
        }

        // Ensure the todo has a scheduled time
        guard let scheduledTime = todo.scheduledTime else {
            return
        }

        // Cancel any existing notification for this todo
        await cancelNotification(for: todo)

        // Don't schedule notifications for completed todos
        if todo.isCompleted {
            return
        }

        // With repeating notifications that only specify hour and minute,
        // the system will automatically schedule for the next occurrence of that time

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = todo.category == .required ? "⚠️ Required Todo" : "💡 Suggested Todo"
        content.body = todo.title
        // Use the Funk sound for an upbeat notification
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "Funk.aiff"))
        content.categoryIdentifier = Self.todoCategoryIdentifier

        // Add subtitle to make it more noticeable 
        if #available(macOS 12.0, iOS 15.0, *) {
            // Add subtitle for more context if available
            content.subtitle = "Time to complete: \(todo.scheduledTime?.formatted(date: .omitted, time: .shortened) ?? "now")"
        }

        // Set a unique thread ID to prevent grouping of notifications
        // Using the todo's UUID ensures each notification is treated individually
        content.threadIdentifier = "todo-\(todo.uuid.uuidString)"

        // Store the todo UUID in the userInfo dictionary
        let todoID = todo.uuid.uuidString
        let userInfo = ["todoId": todoID, "category": todo.category.rawValue] as [String: Any]
        content.userInfo = userInfo

        // Create date components trigger for the scheduled time
        // Only use hour and minute for repeating daily notifications
        let triggerComponents = Calendar.current.dateComponents(
            [.hour, .minute],
            from: scheduledTime
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerComponents,
            repeats: true
        )

        // Create the notification request
        let request = UNNotificationRequest(
            identifier: Self.todoNotificationIdentifierPrefix + todoID,
            content: content,
            trigger: trigger
        )

        // Add the request to the notification center
        do {
            try await notificationCenter.add(request)
            print("Scheduled notification for todo: \(todo.title)")

            // Update the badge count based on all delivered notifications
            refreshBadgeCount()
        } catch {
            print("Error scheduling notification: \(error.localizedDescription)")
        }
    }

    /// Cancel a notification for a specific todo
    /// - Parameter todo: The todo whose notification should be canceled
    @MainActor
    func cancelNotification(for todo: Daily.Todo) async {
        let todoID = todo.uuid.uuidString

        let identifier = Self.todoNotificationIdentifierPrefix + todoID
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])

        // Refresh badge count after canceling a notification
        refreshBadgeCount()
    }

    /// Cancel all scheduled todo notifications
    @MainActor
    func cancelAllTodoNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()

        // Reset badge count after canceling all notifications
        refreshBadgeCount()
    }

    /// Reschedule notifications for all todos based on current settings
    /// - Parameters:
    ///   - todos: The todos to schedule notifications for
    ///   - settings: The settings manager to check notification preferences
    @MainActor
    func rescheduleAllNotifications(todos: [Daily.Todo], settings: SettingsManager) async {
        // First cancel all existing notifications
        cancelAllTodoNotifications()

        // Then schedule notifications for each todo
        for todo in todos {
            await scheduleNotification(for: todo, settings: settings)
        }

        // Refresh badge count after rescheduling
        refreshBadgeCount()
    }

    /// Synchronizes notifications with the database, removing any orphaned notifications
    /// - Parameter todos: All current todos in the database
    @MainActor
    func synchronizeNotificationsWithDatabase(todos: [Daily.Todo]) async {
        // Get all delivered notifications
        let deliveredNotifications = await withCheckedContinuation { continuation in
            notificationCenter.getDeliveredNotifications { notifications in
                continuation.resume(returning: notifications)
            }
        }

        // Create a set of valid todo IDs for quick lookup
        let validTodoIds = Set(todos.map { $0.uuid.uuidString })

        // Find orphaned notifications (those whose todoId doesn't exist in the database)
        var orphanedIdentifiers: [String] = []

        for notification in deliveredNotifications {
            // Extract the todo ID from the notification
            if let todoId = notification.request.content.userInfo["todoId"] as? String {
                // If this ID is not in our valid todos set, it's orphaned
                if !validTodoIds.contains(todoId) {
                    orphanedIdentifiers.append(notification.request.identifier)
                }
            }
        }

        // Remove orphaned notifications if any were found
        if !orphanedIdentifiers.isEmpty {
            print("Removing \(orphanedIdentifiers.count) orphaned notifications")
            notificationCenter.removeDeliveredNotifications(withIdentifiers: orphanedIdentifiers)

            // Refresh the badge count after cleaning up
            refreshBadgeCount()
        }
    }

    // MARK: - Badge Management

    /// Refreshes the badge count based on delivered notifications
    /// This is the central function for badge management - all badge updates should go through here
    @MainActor
    func refreshBadgeCount() {
        notificationCenter.getDeliveredNotifications { notifications in
            Task { @MainActor in
                // Count active notifications
                let count = notifications.count
                print("Badge refresh: Found \(count) delivered notifications")

                // Set the badge count using the platform-specific method
                #if os(macOS)
                // Set or clear the badge based on notification count
                NSApplication.shared.setBadgeCount(count)
                #elseif os(iOS)
                // Set badge to the exact number of delivered notifications
                UIApplication.shared.setBadgeCount(count)
                #endif
            }
        }
    }
    
    // MARK: - Platform-Specific Activation
    
    /// Activate the app and bring it to the foreground
    func activateApp() {
        #if os(macOS)
        NSApplication.shared.activate(ignoringOtherApps: true)
        #elseif os(iOS)
        // On iOS, this happens automatically when the user taps a notification
        // or via scene configuration
        #endif
    }
    
    // MARK: - Notification Handling - Platform Specific
    
    /// Handle a todo being completed from a notification
    @MainActor
    func completeTodoFromNotification(todoId: String) async {
        // Ensure we have a model context
        guard let context = activeModelContext else {
            print("Error: No active model context available for todo completion")

            // Store the todo ID to complete it when the app becomes active
            UserDefaults.standard.set(todoId, forKey: "pendingTodoCompletion")
            UserDefaults.standard.set(Date(), forKey: "pendingTodoCompletionTimestamp")

            // Activate the app to ensure the context becomes available
            self.activateApp()
            return
        }

        do {
            print("Attempting to complete todo with UUID: \(todoId)")

            // Try to find the todo by its UUID
            if let todo = try context.fetchTodoByUUID(todoId) {
                print("📣 Found todo to complete: \(todo.title) (category: \(todo.category.rawValue))")

                // First post the notification so stacks can animate the todo before it's completed
                print("📣 NotificationManager: Posting todoCompletedExternally notification for todo: \(todo.title)")
                print("📣 NotificationManager: Todo UUID: \(todo.uuid.uuidString)")
                NotificationCenter.default.post(
                    name: .todoCompletedExternally,
                    object: nil,
                    userInfo: [
                        "completedTodoId": todo.uuid.uuidString,
                        "category": todo.category.rawValue
                    ]
                )

                // Wait for animation to begin
                try await Task.sleep(nanoseconds: 500_000_000) // 500ms delay

                // After animation has started, mark the todo as completed
                todo.isCompleted = true

                // Cancel the notification for this todo since it's now completed
                await cancelNotification(for: todo)

                // Save the changes to the database
                try context.save()

                print("Successfully completed todo from notification: \(todo.title)")

                // Post a notification to refresh the UI
                NotificationCenter.default.post(name: .todosResetNotification, object: nil)

                // Refresh the badge count
                refreshBadgeCount()
            } else {
                print("Error: Could not find todo with UUID \(todoId)")
            }
        } catch {
            print("Error completing todo from notification: \(error.localizedDescription)")
        }
    }
}

// MARK: - Notification Center Delegate

extension CrossPlatformNotificationManager: UNUserNotificationCenterDelegate {
    /// Called when a notification is delivered to a foreground app
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notifications even when the app is in the foreground
        if #available(iOS 14.0, macOS 12.0, *) {
            return [.list, .sound, .badge]
        } else {
            // For older versions
            return [.alert, .sound, .badge]
        }
    }

    /// Called when a user responds to a notification
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Get the notification action identifier
        let actionIdentifier = response.actionIdentifier

        // Get the notification user info dictionary
        let userInfo = response.notification.request.content.userInfo

        // Handle different notification actions
        switch actionIdentifier {
        case Self.completeTodoActionIdentifier:
            // Handle completing a todo from a notification
            if let todoId = userInfo["todoId"] as? String {
                await completeTodoFromNotification(todoId: todoId)
                refreshBadgeCount()
            }

        case Self.dismissActionIdentifier:
            // Handle dismissing a notification
            print("Notification explicitly dismissed by user")
            // Refresh badge count after explicit dismissal
            refreshBadgeCount()

        case UNNotificationDefaultActionIdentifier:
            // Handle the default action (notification tapped)
            if let todoId = userInfo["todoId"] as? String {
                // Store todo ID in UserDefaults for retrieval on app launch
                UserDefaults.standard.set(todoId, forKey: "pendingTodoId")
                UserDefaults.standard.set(Date(), forKey: "pendingTodoIdTimestamp")

                // Activate the app first to ensure it's in foreground
                self.activateApp()

                // Give a slight delay to ensure the app is active before posting the notification
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Post notification to show the specific todo in focused view
                    NotificationCenter.default.post(
                        name: .showFocusedTodoWithId,
                        object: nil,
                        userInfo: ["todoId": todoId]
                    )
                    print("Notification tapped for todo ID: \(todoId)")

                    // Also post the generic open app notification to ensure the window is visible
                    NotificationCenter.default.post(name: .openDailyApp, object: nil)
                }
            }

        case UNNotificationDismissActionIdentifier:
            // Handle system-level dismissal (X button, swipe away, etc.)
            print("Notification dismissed by system action")
            // Refresh badge count after system dismissal
            refreshBadgeCount()

        default:
            print("Unhandled notification action: \(actionIdentifier)")
            break
        }
    }
}