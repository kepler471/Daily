//
//  TodoResetManager.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import Foundation
import SwiftData
import Combine
import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// MARK: - Todo Reset Manager

/// Manages the automatic reset of todos at a specified time each day
///
/// TodoResetManager is responsible for:
/// - Scheduling the daily reset of todos
/// - Handling manual reset requests
/// - Persisting todo completion state
/// - Notifying the UI of changes
/// - Supporting background reset for iOS
class TodoResetManager: ObservableObject {
    // MARK: Properties
    
    /// Timer that triggers the reset at the scheduled time
    private var timer: Timer?
    
    /// The SwiftData model context for database operations
    private var modelContext: ModelContext
    
    /// Set to store Combine subscription cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// The settings manager to get the reset hour
    private var settingsManager: SettingsManager?
    
    /// The hour (in 24-hour format) when todos should reset
    private var resetHour: Int {
        return settingsManager?.resetHour ?? 4 // Default to 4 AM if settings not available
    }
    
    /// Last reset date for tracking purposes
    private var lastResetDate: Date {
        get {
            let storedDate = UserDefaults.standard.object(forKey: "lastTodoResetDate") as? Date
            return storedDate ?? Date.distantPast
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastTodoResetDate")
        }
    }
    
    // MARK: - Initialization
    
    /// Creates a new TodoResetManager
    /// - Parameter modelContext: The SwiftData model context to use for resetting todos
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Schedule the initial reset timer
        scheduleNextReset()
        
        // Subscribe to app becoming active to reschedule if needed
        #if os(macOS)
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkAndRescheduleIfNeeded()
            }
            .store(in: &cancellables)
        #elseif os(iOS)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkAndRescheduleIfNeeded()
            }
            .store(in: &cancellables)
        #endif
        
        // Listen for settings changes to update reset hour
        NotificationCenter.default.publisher(for: .settingsUpdated)
            .sink { [weak self] _ in
                self?.scheduleNextReset()
            }
            .store(in: &cancellables)
    }
    
    /// Set the settings manager for accessing user preferences
    func setSettingsManager(_ manager: SettingsManager) {
        self.settingsManager = manager
        scheduleNextReset() // Reschedule with new settings
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
        // Check if we've passed the reset time since last reset
        if shouldResetTodos() {
            resetAllTodos()
        }
        
        // If we don't have a timer or it's invalid, reschedule
        if timer == nil || timer?.isValid == false {
            scheduleNextReset()
        }
    }
    
    /// Determines if todos should be reset based on the last reset date
    /// - Returns: True if todos should be reset, false otherwise
    private func shouldResetTodos() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        // Get today's reset time
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = resetHour
        components.minute = 0
        components.second = 0
        
        guard let todayResetDate = calendar.date(from: components) else {
            return false
        }
        
        // If it's past reset time and we haven't reset today
        if now > todayResetDate && 
            !calendar.isDate(lastResetDate, inSameDayAs: now) {
            return true
        }
        
        return false
    }
    
    // MARK: - Todo Reset Operations
    
    /// Resets all todos to incomplete
    ///
    /// This method:
    /// 1. Fetches all completed todos from the database
    /// 2. Marks them as incomplete
    /// 3. Saves the changes
    /// 4. Notifies the UI to update
    /// 5. Ensures notifications are synchronized with the database
    @discardableResult
    func resetAllTodos() -> Bool {
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
            
            // Update last reset date
            lastResetDate = Date()
            
            // Notify observers of the change
            objectWillChange.send()
            
            // Add a small delay to ensure UI is updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // This notification triggers UI updates
                NotificationCenter.default.post(name: .todosResetNotification, object: nil)
                
                // Synchronize notifications with the database after reset
                Task {
                    do {
                        let allTodos = try self.modelContext.fetchTodos()
                        await NotificationManager.shared.synchronizeNotificationsWithDatabase(todos: allTodos)
                    } catch {
                        print("Failed to synchronize notifications after reset: \(error.localizedDescription)")
                    }
                }
            }
            
            print("Successfully reset \(count) todos at \(Date().formatted(date: .abbreviated, time: .standard))")
            return true
        } catch {
            print("Failed to reset todos: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Manually trigger a reset (for testing or debugging)
    func resetTodosNow() {
        resetAllTodos()
        scheduleNextReset()
    }
    
    // MARK: - Background Operations (iOS)
    
    /// Resets todos when running in the background on iOS
    /// - Returns: True if reset was successful, false otherwise
    @MainActor
    func resetTodosInBackground() async -> Bool {
        // Check if we need to reset
        guard shouldResetTodos() else {
            print("Background task: No need to reset todos")
            return false
        }
        
        // Perform the reset
        let success = resetAllTodos()
        
        // Update badge count through notification manager
        if success {
            await NotificationManager.shared.refreshBadgeCount()
        }
        
        return success
    }
}

// No duplicate notification extension needed - using existing notification names instead