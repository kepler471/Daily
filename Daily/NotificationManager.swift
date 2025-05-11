import Foundation
import UserNotifications
import SwiftUI
import SwiftData
import AppKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notificationsEnabled = false {
        didSet {
            if !notificationsEnabled {
                // Remove all pending notifications when disabled
                cancelAllNotifications()
            } else if oldValue != notificationsEnabled {
                // Schedule notifications when re-enabled
                scheduleNotifications()
            }
        }
    }
    @Published var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
    @Published var notifyForRequiredTasks = true
    @Published var notifyForSuggestedTasks = false
    
    // Category identifiers for different actions
    private let taskCategoryIdentifier = "TASK_CATEGORY"
    private let completeActionIdentifier = "COMPLETE_ACTION"
    
    override init() {
        super.init()
        // Initialize notification categories first
        registerCategories()

        // Check current authorization status
        checkNotificationAuthorization()

        // Register for defaults change notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func userDefaultsDidChange() {
        // Check if this is the first launch by inspecting a user default flag
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "hasLaunchedBefore") {
            print("First launch detected via UserDefaults")
            // Mark app as launched
            defaults.set(true, forKey: "hasLaunchedBefore")
            // Request notification permissions
            DispatchQueue.main.async {
                self.requestPermission()
            }
        }
    }
    
    func requestPermission() {
        print("Requesting notification permission...")
        
        // First check if we already have permission to avoid showing dialog again
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let authStatus = settings.authorizationStatus
            
            switch authStatus {
            case .authorized:
                // Already authorized, just update state and schedule
                DispatchQueue.main.async {
                    self.notificationsEnabled = true
                    self.scheduleNotifications()
                }
                
            case .denied, .provisional, .ephemeral:
                // Permission already explicitly denied, open settings directly
                DispatchQueue.main.async {
                    print("Notifications were previously denied. Opening settings...")
                    if let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                        NSWorkspace.shared.open(settingsURL)
                    }
                }
                
            case .notDetermined:
                // First time request, show the system permission dialog
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        self.notificationsEnabled = granted
                        print("Notification permission granted: \(granted)")
                        if granted {
                            self.scheduleNotifications()
                        } else {
                            // If denied, open settings
                            if let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                                NSWorkspace.shared.open(settingsURL)
                            }
                        }
                    }
                    
                    if let error = error {
                        print("Error requesting notification permission: \(error.localizedDescription)")
                    }
                }
                
            @unknown default:
                // Handle future cases
                print("Unknown authorization status: \(authStatus.rawValue)")
            }
        }
    }
    
    func checkNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let isAuthorized = settings.authorizationStatus == .authorized
                self.notificationsEnabled = isAuthorized
                print("Notifications authorized: \(isAuthorized) (\(settings.authorizationStatus.rawValue))")
                
                // If authorized, make sure notifications are scheduled
                if isAuthorized {
                    self.refreshNotifications()
                }
            }
        }
    }
    
    private func registerCategories() {
        // Create the complete action
        let completeAction = UNNotificationAction(
            identifier: completeActionIdentifier,
            title: "Complete",
            options: .foreground
        )
        
        // Create the category with the complete action
        let taskCategory = UNNotificationCategory(
            identifier: taskCategoryIdentifier,
            actions: [completeAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([taskCategory])
    }
    
    func scheduleNotifications() {
        // Remove any existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard notificationsEnabled else {
            print("Not scheduling notifications because they are disabled")
            return 
        }
        
        print("Scheduling notifications...")
        
        // Get all incomplete tasks from the current model context
        // This needs to be called from a view or controller that has access to the model context
        NotificationCenter.default.post(name: Notification.Name("RequestTaskNotificationScheduling"), object: nil)
    }
    
    @MainActor
    func scheduleNotificationsWithTasks(_ incompleteTasks: [Task]) {
        // Only schedule if notifications are enabled
        guard notificationsEnabled else {
            print("Not scheduling task notifications: notifications are disabled")
            return
        }
        
        // Filter tasks based on user preferences
        let filteredTasks = incompleteTasks.filter { task in
            // Only schedule for tasks with designated time or based on user preferences
            if task.scheduledTime != nil {
                return true
            } else if task.category == .required {
                return self.notifyForRequiredTasks
            } else {
                return self.notifyForSuggestedTasks
            }
        }
        
        print("Scheduling notifications for \(filteredTasks.count) tasks after filtering")
        
        // Schedule a notification for each task
        for task in filteredTasks {
            self.scheduleTaskNotification(task)
        }
        
        // Also schedule a daily reminder for tasks without specific times
        self.scheduleReminderNotification()
        
        // Verify scheduled notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("\(requests.count) notifications scheduled in total")
        }
    }
    
    func scheduleTaskNotification(_ task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = "\(task.category == .required ? "Required" : "Suggested") task: \(task.title)"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = taskCategoryIdentifier

        // Extract UUID part from ID and use it as a clean identifier
        let fullIDString = String(describing: task.id)

        // Extract UUID part from the ID string (pattern typically looks like: "PersistentIdentifier<Task>(xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)")
        var cleanIDString = fullIDString
        if let uuidMatch = fullIDString.range(of: #"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"#, options: .regularExpression) {
            cleanIDString = String(fullIDString[uuidMatch])
        }

        print("Scheduling notification for task: \(task.title)")
        print("Full ID: \(fullIDString)")
        print("Clean ID: \(cleanIDString)")

        // Add both the full ID and the clean ID to help with matching later
        content.userInfo = [
            "taskID": cleanIDString,
            "fullTaskID": fullIDString,
            "taskTitle": task.title
        ]

        // Use either the task's scheduled time or the default reminder time
        var notificationTime: Date
        if let scheduledTime = task.scheduledTime {
            notificationTime = scheduledTime
        } else {
            notificationTime = reminderTime
        }

        // Create calendar-based trigger that repeats daily
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute], from: notificationTime)

        // Create the trigger (repeats daily)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create the request with the clean ID as identifier
        let identifier = "task-\(cleanIDString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Successfully scheduled notification for task: \(task.title) with ID: \(cleanIDString)")
            }
        }
    }
    
    func scheduleReminderNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Tasks Reminder"
        content.body = "Don't forget to complete your daily tasks!"
        content.sound = UNNotificationSound.default
        
        // Create calendar-based trigger for the reminder time that repeats daily
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling reminder notification: \(error.localizedDescription)")
            }
        }
    }
    
    func refreshNotifications() {
        if notificationsEnabled {
            scheduleNotifications()
        } else {
            cancelAllNotifications()
        }
    }
    
    func cancelAllNotifications() {
        // Remove all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("All notifications canceled")
    }
    
    // Handle notification when a task is completed
    func handleTaskCompletion(_ task: Task) {
        // Remove the specific notification for this task
        let idString = String(describing: task.id)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["task-\(idString)"]
        )
        
        // Post a notification that a task has been completed
        // The app will handle checking if all required tasks are completed
        NotificationCenter.default.post(
            name: Notification.Name("TaskCompletedNotification"),
            object: nil,
            userInfo: ["taskID": idString]
        )
    }
    
    func sendCongratulationsNotification() {
        // Send a congratulations notification
        let content = UNMutableNotificationContent()
        content.title = "All Required Tasks Completed!"
        content.body = "Great job completing all your required tasks for today!"
        content.sound = UNNotificationSound.default
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "all-completed", 
            content: content, 
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Notification Response Handling
    
    /// Handle notification responses from the user
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        // To be handled by the AppDelegate to avoid Task ambiguity with the SwiftModel
    }
}