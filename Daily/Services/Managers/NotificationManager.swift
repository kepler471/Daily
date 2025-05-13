//
//  NotificationManager.swift
//  Daily
//
//  Created by Stelios Georgiou on 13/05/2025.
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
/// - Synchronizing notifications with the database
class NotificationManager: NSObject, ObservableObject {
    // MARK: - Shared Instance

    /// Shared instance for the notification manager (singleton)
    static let shared = NotificationManager()
    
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
                    Task { @MainActor in
                        await self.refreshBadgeCount()
                    }
                }
            }
        }
    }
    
    // MARK: - Model Context Management
    
    /// Set the model context for database operations
    func setModelContext(_ context: ModelContext) {
        self.modelContextReference = context

        // Store the container reference as well for creating new contexts if needed
        self.modelContainer = context.container
        print("ModelContext stored in NotificationManager")
    }
    
    // MARK: - Setup
    
    /// Set up notification handling and request permissions
    func setupNotifications() async {
        await refreshAuthorizationStatus()
        
        // Only request authorization if status is not determined
        if authorizationStatus == .notDetermined {
            await requestAuthorization()
        }
        
        // If authorized, refresh the badge count
        if authorizationStatus == .authorized {
            await refreshBadgeCount()
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
            
            print("Notification authorization \(granted ? "granted" : "denied")")
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

        // Create the category for todo notifications with actions
        let todoCategory = UNNotificationCategory(
            identifier: Self.todoCategoryIdentifier,
            actions: [completeAction, dismissAction],
            intentIdentifiers: [],
            options: []
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

        // MARK: Create Notification Content

        let content = UNMutableNotificationContent()
        content.title = todo.category == .required ? "⚠️ Required Todo" : "💡 Suggested Todo"
        content.body = todo.title
        // Use the Funk sound or default if not available
        let funkSound = UNNotificationSoundName(rawValue: "Funk.aiff")
        content.sound = UNNotificationSound(named: funkSound)
        content.categoryIdentifier = Self.todoCategoryIdentifier

        // Add subtitle to make it more noticeable
        if #available(macOS 12.0, iOS 15.0, *) {
            content.subtitle = "Time to complete: \(todo.scheduledTime?.formatted(date: .omitted, time: .shortened) ?? "now")"
        }

        // Set a unique thread ID to prevent grouping of notifications
        content.threadIdentifier = "todo-\(todo.uuid.uuidString)"

        // Store the todo UUID in the userInfo dictionary
        let todoID = todo.uuid.uuidString
        let userInfo = ["todoId": todoID, "category": todo.category.rawValue] as [String: Any]
        content.userInfo = userInfo

        // MARK: Create Notification Trigger

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

            // Update the badge count
            await refreshBadgeCount()
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
        
        print("Cancelled notification for todo: \(todo.title)")
        
        // Refresh badge count after canceling a notification
        await refreshBadgeCount()
    }

    /// Cancel all scheduled todo notifications
    @MainActor
    func cancelAllTodoNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        
        print("Cancelled all notifications")

        // Reset badge count after canceling all notifications
        await refreshBadgeCount()
    }

    /// Reschedule notifications for all todos based on current settings
    /// - Parameters:
    ///   - todos: The todos to schedule notifications for
    ///   - settings: The settings manager to check notification preferences
    @MainActor
    func rescheduleAllNotifications(todos: [Daily.Todo], settings: SettingsManager) async {
        // First cancel all existing notifications
        await cancelAllTodoNotifications()

        // Then schedule notifications for each todo
        for todo in todos {
            await scheduleNotification(for: todo, settings: settings)
        }

        // Refresh badge count after rescheduling
        await refreshBadgeCount()
    }

    /// Synchronizes notifications with the database, removing any orphaned notifications
    /// - Parameter todos: All current todos in the database
    @MainActor
    func synchronizeNotificationsWithDatabase(todos: [Daily.Todo]) async {
        // MARK: Authorization Check

        // Skip if not authorized
        guard isAuthorized else {
            print("Cannot synchronize notifications - no authorization")
            return
        }

        // MARK: Fetch Current Notifications

        // Get all delivered notifications
        let deliveredNotifications = await withCheckedContinuation { continuation in
            notificationCenter.getDeliveredNotifications { notifications in
                continuation.resume(returning: notifications)
            }
        }
        
        // Get all pending notification requests
        let pendingRequests = await notificationCenter.pendingNotificationRequests()

        // Create a set of valid todo IDs for quick lookup
        let validTodoIds = Set(todos.map { $0.uuid.uuidString })

        // MARK: Identify Orphaned Notifications

        // Find orphaned notifications (those whose todoId doesn't exist in the database)
        var orphanedDeliveredIdentifiers: [String] = []
        var orphanedPendingIdentifiers: [String] = []

        // For all delivered notifications, extract todoIds directly from identifiers
        for notification in deliveredNotifications {
            let identifier = notification.request.identifier

            // Only check notifications that match our app's prefix
            if identifier.hasPrefix(Self.todoNotificationIdentifierPrefix) {
                let todoId = String(identifier.dropFirst(Self.todoNotificationIdentifierPrefix.count))

                // If this todoId is not in our database, it's orphaned
                if !validTodoIds.contains(todoId) {
                    orphanedDeliveredIdentifiers.append(identifier)
                }
            }
        }

        // For all pending notifications, extract todoIds directly from identifiers
        for request in pendingRequests {
            let identifier = request.identifier

            // Only check notifications that match our app's prefix
            if identifier.hasPrefix(Self.todoNotificationIdentifierPrefix) {
                let todoId = String(identifier.dropFirst(Self.todoNotificationIdentifierPrefix.count))

                // If this todoId is not in our database, it's orphaned
                if !validTodoIds.contains(todoId) {
                    orphanedPendingIdentifiers.append(identifier)
                }
            }
        }

        // MARK: Cleanup Orphaned Notifications

        // Clean up orphaned notifications with detailed logging
        if !orphanedDeliveredIdentifiers.isEmpty {
            print("Cleaning up \(orphanedDeliveredIdentifiers.count) orphaned delivered notifications")
            notificationCenter.removeDeliveredNotifications(withIdentifiers: orphanedDeliveredIdentifiers)
        }

        if !orphanedPendingIdentifiers.isEmpty {
            print("Cleaning up \(orphanedPendingIdentifiers.count) orphaned pending notifications")
            notificationCenter.removePendingNotificationRequests(withIdentifiers: orphanedPendingIdentifiers)
        }

        // Log summary of orphaned notifications
        let totalOrphaned = orphanedDeliveredIdentifiers.count + orphanedPendingIdentifiers.count
        if totalOrphaned > 0 {
            print("✅ Found \(totalOrphaned) orphaned notifications to remove")
        }

        // Find and cancel notifications for completed todos or those without scheduled times
        var completedOrUnscheduledCount = 0
        for todo in todos {
            if todo.isCompleted || todo.scheduledTime == nil {
                // If there's a notification for this todo, cancel it
                let identifier = Self.todoNotificationIdentifierPrefix + todo.uuid.uuidString
                notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
                completedOrUnscheduledCount += 1
            }
        }

        // Log if we canceled any notifications for completed todos
        if completedOrUnscheduledCount > 0 {
            print("Canceled notifications for \(completedOrUnscheduledCount) completed or unscheduled todos")
        }

        // Final report on cleanup results
        if totalOrphaned > 0 || completedOrUnscheduledCount > 0 {
            print("✅ Notification cleanup complete")
        } else {
            print("✅ Notification synchronization complete: no cleanup needed")
        }

        // Refresh the badge count after cleaning up
        await refreshBadgeCount()
    }

    // MARK: - Badge Management

    /// Refreshes the badge count based on incomplete todos
    @MainActor
    func refreshBadgeCount() async {
        guard let context = activeModelContext else {
            print("Cannot refresh badge count - no active model context")
            return
        }
        
        do {
            // Count incomplete todos
            let requiredCount = try context.countIncompleteTodos(category: .required)
            let suggestedCount = try context.countIncompleteTodos(category: .suggested)
            let totalCount = requiredCount + suggestedCount
            
            // Set the badge count based on platform
            #if os(iOS)
            await UNUserNotificationCenter.current().setBadgeCustom(totalCount)
            #elseif os(macOS)
            NSApplication.shared.dockTile.badgeLabel = totalCount > 0 ? "\(totalCount)" : ""
            #endif
            
            print("Badge count updated to \(totalCount)")
        } catch {
            print("Error refreshing badge count: \(error.localizedDescription)")
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
    
    // MARK: - Notification Handling
    
    /// Handle a todo being completed from a notification
    @MainActor
    func completeTodoFromNotification(todoId: String) async {
        // MARK: Context Validation

        // Ensure we have a model context
        guard let context = activeModelContext else {
            print("Error: No active model context available for todo completion")

            // Store the todo ID to complete it when the app becomes active
            UserDefaults.standard.set(todoId, forKey: "pendingTodoCompletion")
            UserDefaults.standard.set(Date(), forKey: "pendingTodoCompletionTimestamp")

            // Post a notification that the app should complete a todo when it becomes active
            NotificationCenter.default.post(name: .completeTodoPending, object: nil, userInfo: ["todoId": todoId])
            
            // Activate the app to ensure the context becomes available
            self.activateApp()
            return
        }

        do {
            print("Attempting to complete todo with UUID: \(todoId)")

            // MARK: Todo Lookup & Completion

            // Try to find the todo by its UUID
            if let todo = try context.fetchTodoByUUID(todoId) {
                print("📣 Found todo to complete: \(todo.title) (category: \(todo.category.rawValue))")

                // First post the notification so stacks can animate the todo before it's completed
                print("📣 NotificationService: Posting todoCompletedExternally notification for todo: \(todo.title)")
                print("📣 NotificationService: Todo UUID: \(todo.uuid.uuidString)")
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
                await refreshBadgeCount()
            } else {
                print("Error: Could not find todo with UUID \(todoId)")
                
                // Store the todo ID to attempt completion when the app is fully active
                UserDefaults.standard.set(todoId, forKey: "pendingTodoCompletion")
                UserDefaults.standard.set(Date(), forKey: "pendingTodoCompletionTimestamp")
            }
        } catch {
            print("Error completing todo from notification: \(error.localizedDescription)")
        }
    }
}

// MARK: - Notification Center Delegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Called when a notification is delivered to a foreground app
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Platform-specific presentation options
        #if os(macOS)
        // Show notifications even when the app is in the foreground on macOS
        return [.banner, .sound, .badge]
        #elseif os(iOS)
        // iOS-specific presentation options
        if #available(iOS 14.0, *) {
            return [.list, .sound, .badge]
        } else {
            return [.alert, .sound, .badge]
        }
        #endif
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

        // Extract todo ID from the notification
        guard let todoId = userInfo["todoId"] as? String else {
            print("No todo ID found in notification user info")
            return
        }

        // MARK: Action Handling

        // Handle different notification actions
        switch actionIdentifier {
        case Self.completeTodoActionIdentifier:
            // Handle completing a todo from a notification
            await completeTodoFromNotification(todoId: todoId)
            await refreshBadgeCount()

        case Self.dismissActionIdentifier:
            // Handle dismissing a notification
            print("Notification explicitly dismissed by user")
            // Refresh badge count after explicit dismissal
            await refreshBadgeCount()

        case UNNotificationDefaultActionIdentifier:
            // Handle the default action (notification tapped)
            // Store todo ID in UserDefaults for retrieval on app launch
            UserDefaults.standard.set(todoId, forKey: "pendingTodoId")
            UserDefaults.standard.set(Date(), forKey: "pendingTodoIdTimestamp")

            // Activate the app first to ensure it's in foreground
            self.activateApp()

            // Complete the todo if tapped
            await completeTodoFromNotification(todoId: todoId)

            // Give a slight delay to ensure the app is active before posting notifications
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms delay

            // Post notification to show the specific todo in focused view
            NotificationCenter.default.post(
                name: .showFocusedTodoWithId,
                object: nil,
                userInfo: ["todoId": todoId]
            )
            print("📣 Notification tapped for todo ID: \(todoId)")

            // Also post the generic open app notification to ensure the window is visible
            NotificationCenter.default.post(name: .openDailyApp, object: nil)

        case UNNotificationDismissActionIdentifier:
            // Handle system-level dismissal (X button, swipe away, etc.)
            print("Notification dismissed by system action")
            // Refresh badge count after system dismissal
            await refreshBadgeCount()

        default:
            print("Unhandled notification action: \(actionIdentifier)")
        }
    }
}

// MARK: - Platform-Specific Extensions

#if os(iOS)
extension UNUserNotificationCenter {
    /// Sets the app's badge count (iOS)
    @available(iOS, introduced: 15.0, deprecated: 17.0, message: "Use the system's setBadgeCount directly in iOS 17+")
    @MainActor
    func setBadgeCustom(_ count: Int) async {
        if #available(iOS 17.0, *) {
            // Use the built-in API in iOS 17+
            do {
                try await self.setBadgeCount(count)
            } catch {
                print("Error setting badge count: \(error.localizedDescription)")
            }
        } else {
            // Legacy approach for older iOS versions
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
}
#endif

// MARK: - Notification Name Extensions

/// Extension for centralizing all notification names used in the app
extension Notification.Name {
    // MARK: UI Notifications

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

    // MARK: Data Notifications

    /// Notification to indicate a todo was completed from outside the TodoStackView
    static let todoCompletedExternally = Notification.Name("TodoCompletedExternally")

    /// Notification to indicate todos were reset
    static let todosResetNotification = Notification.Name("TodosResetNotification")

    /// Notification sent when a todo completion is pending due to missing context
    static let completeTodoPending = Notification.Name("CompleteTodoPending")

    // MARK: Settings Notifications

    /// Notification to indicate the launch instructions for login items
    static let showLoginItemInstructions = Notification.Name("ShowLoginItemInstructions")

    /// Notification for settings updates
    static let settingsUpdated = Notification.Name("SettingsUpdated")
}
