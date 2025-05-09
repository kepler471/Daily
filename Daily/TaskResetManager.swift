//
//  TaskResetManager.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import Foundation
import SwiftData
import Combine
import AppKit
import SwiftUI

// MARK: - Notification Constants

/// Extension for centralizing notification names used in the task reset system
extension Notification.Name {
    /// Notification sent when tasks are reset (for UI updates)
    static let tasksResetNotification = Notification.Name("TasksResetNotification")
}

// MARK: - ModelContext Extensions
// Note: ModelContext extensions are centralized in Task+Extensions.swift

// MARK: - Task Reset Manager

/// Manages the automatic reset of tasks at a specified time each day
///
/// TaskResetManager is responsible for:
/// - Scheduling the daily reset of tasks
/// - Handling manual reset requests
/// - Persisting task completion state
/// - Notifying the UI of changes
class TaskResetManager: ObservableObject {
    // MARK: Properties
    
    /// Timer that triggers the reset at the scheduled time
    private var timer: Timer?
    
    /// The SwiftData model context for database operations
    private var modelContext: ModelContext
    
    /// Set to store Combine subscription cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// The hour (in 24-hour format) when tasks should reset
    private let resetHour: Int = 4
    
    // MARK: - Initialization
    
    /// Creates a new TaskResetManager
    /// - Parameter modelContext: The SwiftData model context to use for resetting tasks
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Schedule the initial reset timer
        scheduleNextReset()
        
        // Subscribe to app becoming active to reschedule if needed
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkAndRescheduleIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Reset Scheduling
    
    /// Schedules the next reset based on the current time
    func scheduleNextReset() {
        // Cancel any existing timer
        timer?.invalidate()
        
        // Calculate the next reset time
        let nextResetDate = calculateNextResetDate()
        let timeInterval = nextResetDate.timeIntervalSinceNow
        
        print("Tasks will reset at \(nextResetDate.formatted(date: .complete, time: .complete))")
        
        // Schedule the timer
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.resetAllTasks()
            self?.scheduleNextReset() // Schedule the next day's reset
        }
    }
    
    /// Calculates the next reset date based on the reset hour
    /// - Returns: The next date when tasks should reset
    internal func calculateNextResetDate() -> Date {
        let now = Date()
        let calendar = Calendar.current
        
        // Get today's reset time (at the configured hour)
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = resetHour
        components.minute = 0
        components.second = 0
        
        guard let todayResetDate = calendar.date(from: components) else {
            fatalError("Failed to create reset date")
        }
        
        // If it's already past the reset time today, schedule for tomorrow
        if now > todayResetDate {
            return calendar.date(byAdding: .day, value: 1, to: todayResetDate) ?? todayResetDate
        } else {
            return todayResetDate
        }
    }
    
    /// Checks if the scheduled reset is still valid and reschedules if not
    ///
    /// This is called when the app becomes active to ensure the timer is still valid
    /// after the system has been asleep or the app has been inactive.
    private func checkAndRescheduleIfNeeded() {
        // If we don't have a timer or it's invalid, reschedule
        if timer == nil || timer?.isValid == false {
            scheduleNextReset()
        }
    }
    
    // MARK: - Task Reset Operations
    
    /// Resets all tasks to incomplete
    ///
    /// This method:
    /// 1. Fetches all completed tasks from the database
    /// 2. Marks them as incomplete
    /// 3. Saves the changes
    /// 4. Notifies the UI to update
    func resetAllTasks() {
        do {
            // Fetch all completed tasks
            let completedTasks = try modelContext.fetchCompletedTasks(category: nil)
            let count = completedTasks.count
            
            // Mark each as incomplete
            for task in completedTasks {
                task.isCompleted = false
            }
            
            // Save changes
            try modelContext.save()
            
            // Notify observers of the change
            objectWillChange.send()
            
            // Add a small delay to ensure UI is updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // This notification triggers UI updates
                NotificationCenter.default.post(name: .tasksResetNotification, object: nil)
            }
            
            print("Successfully reset \(count) tasks at \(Date().formatted(date: .abbreviated, time: .standard))")
        } catch {
            print("Failed to reset tasks: \(error.localizedDescription)")
        }
    }
    
    /// Manually trigger a reset (for testing or debugging)
    func resetTasksNow() {
        resetAllTasks()
        scheduleNextReset()
    }
}

// MARK: - Environment Key for TaskResetManager

/// Define the environment key for accessing the TaskResetManager
struct ResetTaskManagerKey: EnvironmentKey {
    static let defaultValue: TaskResetManager? = nil
}

/// Extend the environment values to provide access to the TaskResetManager
extension EnvironmentValues {
    /// Access the task reset manager through the SwiftUI environment
    var resetTaskManager: TaskResetManager? {
        get { self[ResetTaskManagerKey.self] }
        set { self[ResetTaskManagerKey.self] = newValue }
    }
}
