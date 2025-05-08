//
//  TaskResetManager.swift
//  Daily
//
//  Created by Claude on 08/05/2025.
//

import Foundation
import SwiftData
import Combine
import AppKit
import SwiftUI

/// Manages the automatic reset of tasks at a specified time each day
class TaskResetManager: ObservableObject {
    private var timer: Timer?
    private var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    /// The hour (in 24-hour format) when tasks should reset
    private let resetHour: Int = 4
    
    /// Creates a new TaskResetManager
    /// - Parameter modelContext: The SwiftData model context to use for resetting tasks
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        scheduleNextReset()
        
        // Also subscribe to app becoming active to reschedule if needed
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkAndRescheduleIfNeeded()
            }
            .store(in: &cancellables)
    }
    
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
    
    /// Calculates the next 4am reset date
    /// - Returns: The next date when tasks should reset
    private func calculateNextResetDate() -> Date {
        let now = Date()
        let calendar = Calendar.current
        
        // Get today's reset time (4am)
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = resetHour
        components.minute = 0
        components.second = 0
        
        guard let todayResetDate = calendar.date(from: components) else {
            fatalError("Failed to create reset date")
        }
        
        // If it's already past 4am today, schedule for tomorrow
        if now > todayResetDate {
            return calendar.date(byAdding: .day, value: 1, to: todayResetDate) ?? todayResetDate
        } else {
            return todayResetDate
        }
    }
    
    /// Checks if the scheduled reset is still valid and reschedules if not
    private func checkAndRescheduleIfNeeded() {
        // If we don't have a timer or it's invalid, reschedule
        if timer == nil || timer?.isValid == false {
            scheduleNextReset()
        }
    }
    
    /// Resets all tasks to incomplete
    func resetAllTasks() {
        do {
            // Fetch all completed tasks
            let completedTasks = try modelContext.fetchCompletedTasks()
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
                NotificationCenter.default.post(name: NSNotification.Name("TasksResetNotification"), object: nil)
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

// Define the environment key for accessing the TaskResetManager
struct ResetTaskManagerKey: EnvironmentKey {
    static let defaultValue: TaskResetManager? = nil
}

// Extend the environment values to provide access to the TaskResetManager
extension EnvironmentValues {
    var resetTaskManager: TaskResetManager? {
        get { self[ResetTaskManagerKey.self] }
        set { self[ResetTaskManagerKey.self] = newValue }
    }
}
