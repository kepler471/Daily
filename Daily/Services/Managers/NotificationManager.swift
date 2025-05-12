//
//  NotificationManager.swift
//  Daily
//
//  Created by Stelios Georgiou on 11/05/2025.
//

import Foundation
import UserNotifications
import SwiftUI
import AppKit
import SwiftData
import Observation

/// Centralized manager for handling app notifications
///
/// NotificationManager is responsible for:
/// - Requesting and checking notification permissions
/// - Scheduling notifications for tasks
/// - Handling notification interactions
/// - Managing notification categories and actions
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

    /// Set the model context for database operations
    func setModelContext(_ context: ModelContext) {
        self.modelContextReference = context

        // Store the container reference as well for creating new contexts if needed
        self.modelContainer = context.container
        print("ModelContainer stored in NotificationManager")
    }
    
    // MARK: - Constants

    /// Category identifier for task notifications
    static let taskCategoryIdentifier = "com.kepler471.Daily.taskNotification"

    /// Action identifier for completing a task from a notification
    static let completeTaskActionIdentifier = "com.kepler471.Daily.completeTask"

    /// Notification identifier prefix for task notifications
    static let taskNotificationIdentifierPrefix = "com.kepler471.Daily.task."
    
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
        // Open the System Preferences/Settings and go to Notifications
        if let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(settingsURL)
        }
    }
    
    // MARK: - Notification Categories Setup

    /// Sets up notification categories and actions
    private func setupNotificationCategories() {
        // Create the "Complete" action for task notifications
        let completeAction = UNNotificationAction(
            identifier: Self.completeTaskActionIdentifier,
            title: "Complete",
            options: .foreground
        )

        // Create the category for task notifications with the complete action
        let taskCategory = UNNotificationCategory(
            identifier: Self.taskCategoryIdentifier,
            actions: [completeAction],
            intentIdentifiers: [],
            options: []
        )

        // Register the category with the notification center
        notificationCenter.setNotificationCategories([taskCategory])
    }

    // MARK: - Task Notification Management

    /// Schedule a notification for a task
    /// - Parameters:
    ///   - task: The task to schedule a notification for
    ///   - settings: The settings manager to check notification preferences
    ///
    /// The notification will repeat daily at the specified time using a calendar trigger
    /// with hour and minute components, ensuring notifications continue even if the app
    /// is not running at reset time.
    @MainActor
    func scheduleNotification(for task: Daily.Task, settings: SettingsManager) async {
        // First ensure we have notification permission
        if !isAuthorized {
            return
        }

        // Log the task's UUID for debugging
        print("Scheduling notification for task: \(task.title) with UUID: \(task.uuid.uuidString)")

        // Check if notifications are enabled for this task category
        switch task.category {
        case .required:
            if !settings.requiredTaskNotificationsEnabled {
                return
            }
        case .suggested:
            if !settings.suggestedTaskNotificationsEnabled {
                return
            }
        }

        // Ensure the task has a scheduled time
        guard let scheduledTime = task.scheduledTime else {
            return
        }

        // Cancel any existing notification for this task
        await cancelNotification(for: task)

        // Don't schedule notifications for completed tasks
        if task.isCompleted {
            return
        }

        // With repeating notifications that only specify hour and minute,
        // the system will automatically schedule for the next occurrence of that time

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = task.category == .required ? "Required Task" : "Suggested Task"
        content.body = task.title
        content.sound = .default
        content.categoryIdentifier = Self.taskCategoryIdentifier

        // Store the task UUID in the userInfo dictionary
        let taskID = task.uuid.uuidString
        content.userInfo = ["taskId": taskID]

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
            identifier: Self.taskNotificationIdentifierPrefix + taskID,
            content: content,
            trigger: trigger
        )

        // Add the request to the notification center
        do {
            try await notificationCenter.add(request)
            print("Scheduled notification for task: \(task.title)")
        } catch {
            print("Error scheduling notification: \(error.localizedDescription)")
        }
    }

    /// Cancel a notification for a specific task
    /// - Parameter task: The task whose notification should be canceled
    @MainActor
    func cancelNotification(for task: Daily.Task) async {
        let taskID = task.uuid.uuidString

        let identifier = Self.taskNotificationIdentifierPrefix + taskID
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel all scheduled task notifications
    @MainActor
    func cancelAllTaskNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Reschedule notifications for all tasks based on current settings
    /// - Parameters:
    ///   - tasks: The tasks to schedule notifications for
    ///   - settings: The settings manager to check notification preferences
    @MainActor
    func rescheduleAllNotifications(tasks: [Daily.Task], settings: SettingsManager) async {
        // First cancel all existing notifications
        cancelAllTaskNotifications()

        // Then schedule notifications for each task
        for task in tasks {
            await scheduleNotification(for: task, settings: settings)
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
        // Show notifications even when the app is in the foreground
        return [.banner, .sound, .badge]
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
        case Self.completeTaskActionIdentifier:
            // Handle completing a task from a notification
            if let taskId = userInfo["taskId"] as? String {
                await completeTaskFromNotification(taskId: taskId)
            }

        case UNNotificationDefaultActionIdentifier:
            // Handle the default action (notification tapped)
            if let taskId = userInfo["taskId"] as? String {
                // Store task ID in UserDefaults for retrieval on app launch
                UserDefaults.standard.set(taskId, forKey: "pendingTaskId")
                UserDefaults.standard.set(Date(), forKey: "pendingTaskIdTimestamp")

                // Activate the app first to ensure it's in foreground
                NSApplication.shared.activate(ignoringOtherApps: true)

                // Give a slight delay to ensure the app is active before posting the notification
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Post notification to show the specific task in focused view
                    NotificationCenter.default.post(
                        name: .showFocusedTaskWithId,
                        object: nil,
                        userInfo: ["taskId": taskId]
                    )
                    print("Notification tapped for task ID: \(taskId)")

                    // Also post the generic open app notification to ensure the window is visible
                    NotificationCenter.default.post(name: .openDailyApp, object: nil)
                }
            }

        default:
            break
        }
    }

    /// Completes a task from a notification action
    /// - Parameter taskId: The UUID string of the task to complete
    @MainActor
    private func completeTaskFromNotification(taskId: String) async {
        // Ensure we have a model context
        guard let context = activeModelContext else {
            print("Error: No active model context available for task completion")

            // Store the task ID to complete it when the app becomes active
            UserDefaults.standard.set(taskId, forKey: "pendingTaskCompletion")
            UserDefaults.standard.set(Date(), forKey: "pendingTaskCompletionTimestamp")

            // Activate the app to ensure the context becomes available
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        do {
            print("Attempting to complete task with UUID: \(taskId)")

            // Try to find the task by its UUID
            if let task = try context.fetchTaskByUUID(taskId) {
                // Mark the task as completed
                task.isCompleted = true

                // Cancel the notification for this task since it's now completed
                await cancelNotification(for: task)

                // Save the changes to the database
                try context.save()

                print("Successfully completed task from notification: \(task.title)")

                // Post a notification to refresh the UI
                NotificationCenter.default.post(name: .tasksResetNotification, object: nil)
            } else {
                print("Error: Could not find task with UUID \(taskId)")
            }
        } catch {
            print("Error completing task from notification: \(error.localizedDescription)")
        }
    }
}