//
//  DataManager.swift
//  Daily
//
//  Created by Stelios Georgiou on 13/05/2025.
//

import Foundation
import SwiftData
import SwiftUI

/// Manager class for handling various data operations in the Daily app
///
/// DataManager is responsible for:
/// - Resetting all app data
/// - Creating and managing todos
/// - Performing bulk data operations
/// - Coordinating with NotificationManager for notification synchronization
class DataManager: ObservableObject {
    // MARK: - Properties
    
    /// Shared instance for the data manager (singleton)
    static let shared = DataManager()
    
    /// The model container reference used to create new contexts when needed
    private var modelContainer: ModelContainer?
    
    /// The notification manager reference
    private var notificationManager: NotificationManager {
        return NotificationManager.shared
    }
    
    /// The settings manager reference
    @Published var settingsManager: SettingsManager?
    
    /// Get an active model context for performing database operations
    private var activeModelContext: ModelContext? {
        // If we have a container, create a new context
        if let container = modelContainer {
            return ModelContext(container)
        }
        return nil
    }
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Set the model container for data operations
    func setModelContainer(_ container: ModelContainer) {
        self.modelContainer = container
        print("ModelContainer stored in DataManager")
    }
    
    /// Set the settings manager
    func setSettingsManager(_ settings: SettingsManager) {
        self.settingsManager = settings
    }
    
    // MARK: - Data Operations
    
    /// Resets all data by deleting all todos and recreating sample todos
    /// - Parameters:
    ///   - onReset: Optional callback that gets triggered after data reset
    /// - Returns: Boolean indicating if reset was successful
    @MainActor
    func resetAllData(onReset: (() -> Void)? = nil) async -> Bool {
        guard let context = activeModelContext else {
            print("Cannot reset data - no model context available")
            return false
        }
        
        // First cancel all notifications to prevent orphaned notifications
        await notificationManager.cancelAllTodoNotifications()
        
        do {
            // Delete all todos
            try context.delete(model: Todo.self)
            
            // Re-add sample data
            try TodoMockData.createSampleTodos(in: context)
            
            // Sync notifications with the database to handle the new todos
            let todos = try context.fetchTodos()
            await notificationManager.synchronizeNotificationsWithDatabase(todos: todos)
            
            // Call the onReset callback if provided
            onReset?()
            
            print("Successfully reset all data")
            return true
        } catch {
            print("Error resetting data: \(error)")
            return false
        }
    }
    
    // MARK: - Todo Management
    
    /// Creates and saves a new todo with the provided details
    /// - Parameters:
    ///   - title: The title of the todo
    ///   - category: The category of the todo
    ///   - scheduledTime: Optional scheduled time for the todo
    /// - Returns: The newly created todo, or nil if creation failed
    @discardableResult
    func addTodo(title: String, category: TodoCategory, scheduledTime: Date? = nil) -> Todo? {
        guard let context = activeModelContext else {
            print("Cannot add todo - no model context available")
            return nil
        }
        
        // Calculate next order
        let nextOrder = getNextOrder(for: category, in: context)
        
        // Create the todo
        let newTodo = Todo(
            title: title,
            order: nextOrder,
            category: category,
            scheduledTime: scheduledTime
        )
        
        // Insert into database
        context.insert(newTodo)
        
        // Schedule notification if needed
        if newTodo.scheduledTime != nil {
            Task {
                await newTodo.scheduleNotification(settings: settingsManager ?? SettingsManager())
            }
        }
        
        return newTodo
    }
    
    /// Calculates the next available order value for sorting todos
    /// - Parameters:
    ///   - category: The category to find the order for
    ///   - context: The model context to use
    /// - Returns: The next order value for the selected category
    private func getNextOrder(for category: TodoCategory, in context: ModelContext) -> Int {
        do {
            let categoryString = category.rawValue
            var descriptor = FetchDescriptor<Todo>(
                sortBy: [SortDescriptor(\Todo.order, order: .reverse)]
            )
            descriptor.predicate = #Predicate<Todo> { todo in
                todo.categoryRaw == categoryString
            }
            descriptor.fetchLimit = 1
            
            let result = try context.fetch(descriptor)
            return (result.first?.order ?? 0) + 1
        } catch {
            print("Error fetching next order: \(error)")
            return 0
        }
    }
}
