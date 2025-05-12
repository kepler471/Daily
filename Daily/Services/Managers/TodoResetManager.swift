//
//  TodoResetManager.swift
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

/// Extension for centralizing notification names used in the todo reset system
extension Notification.Name {
    /// Notification sent when todos are reset (for UI updates)
    static let todosResetNotification = Notification.Name("TodosResetNotification")
}

// MARK: - ModelContext Extensions
// Note: ModelContext extensions are centralized in Todo+Extensions.swift

// MARK: - Todo Reset Manager

/// Manages the automatic reset of todos at a specified time each day
///
/// TodoResetManager is responsible for:
/// - Scheduling the daily reset of todos
/// - Handling manual reset requests
/// - Persisting todo completion state
/// - Notifying the UI of changes
class TodoResetManager: ObservableObject {
    // MARK: Properties
    
    /// Timer that triggers the reset at the scheduled time
    private var timer: Timer?
    
    /// The SwiftData model context for database operations
    private var modelContext: ModelContext
    
    /// Set to store Combine subscription cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// The hour (in 24-hour format) when todos should reset
    private let resetHour: Int = 4
    
    // MARK: - Initialization
    
    /// Creates a new TodoResetManager
    /// - Parameter modelContext: The SwiftData model context to use for resetting todos
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
        
        print("Todos will reset at \(nextResetDate.formatted(date: .complete, time: .complete))")
        
        // Schedule the timer
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.resetAllTodos()
            self?.scheduleNextReset() // Schedule the next day's reset
        }
    }
    
    /// Calculates the next reset date based on the reset hour
    /// - Returns: The next date when todos should reset
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
    
    // MARK: - Todo Reset Operations
    
    /// Resets all todos to incomplete
    ///
    /// This method:
    /// 1. Fetches all completed todos from the database
    /// 2. Marks them as incomplete
    /// 3. Saves the changes
    /// 4. Notifies the UI to update
    func resetAllTodos() {
        do {
            // Fetch all completed todos
            let completedTodos = try modelContext.fetchCompletedTodos(category: nil)
            let count = completedTodos.count
            
            // Mark each as incomplete
            for todo in completedTodos {
                todo.isCompleted = false
            }
            
            // Save changes
            try modelContext.save()
            
            // Notify observers of the change
            objectWillChange.send()
            
            // Add a small delay to ensure UI is updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // This notification triggers UI updates
                NotificationCenter.default.post(name: .todosResetNotification, object: nil)
            }
            
            print("Successfully reset \(count) todos at \(Date().formatted(date: .abbreviated, time: .standard))")
        } catch {
            print("Failed to reset todos: \(error.localizedDescription)")
        }
    }
    
    /// Manually trigger a reset (for testing or debugging)
    func resetTodosNow() {
        resetAllTodos()
        scheduleNextReset()
    }
}

// MARK: - Environment Key for TodoResetManager

/// Define the environment key for accessing the TodoResetManager
struct ResetTodoManagerKey: EnvironmentKey {
    static let defaultValue: TodoResetManager? = nil
}

/// Extend the environment values to provide access to the TodoResetManager
extension EnvironmentValues {
    /// Access the todo reset manager through the SwiftUI environment
    var resetTodoManager: TodoResetManager? {
        get { self[ResetTodoManagerKey.self] }
        set { self[ResetTodoManagerKey.self] = newValue }
    }
}
