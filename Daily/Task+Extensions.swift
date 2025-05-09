// 
//  Task+Extensions.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import Foundation
import SwiftData

// MARK: - Task Query Predicates

extension Task {
    /// Predefined predicates for common Task queries
    ///
    /// This nested enum provides reusable SwiftData predicates for filtering tasks
    /// in various ways, making database queries more consistent and maintainable.
    enum Predicates {
        // MARK: Category Filters
        
        /// Creates a predicate to filter tasks by category, or all categories if nil
        /// - Parameter category: The category to filter by, or nil for all categories
        /// - Returns: A predicate that can be used with SwiftData fetch descriptors
        static func byCategory(_ category: TaskCategory?) -> Predicate<Task> {
            if let category = category {
                return #Predicate<Task> { task in
                    task.categoryRaw == category.rawValue
                }
            } else {
                // Return a predicate that matches all tasks
                return #Predicate<Task> { _ in true }
            }
        }
        
        // MARK: Completion Filters
        
        /// Creates a predicate to filter tasks by completion status
        /// - Parameter isCompleted: Whether to find completed or incomplete tasks
        /// - Returns: A predicate that can be used with SwiftData fetch descriptors
        static func byCompletion(isCompleted: Bool) -> Predicate<Task> {
            #Predicate<Task> { task in
                task.isCompleted == isCompleted
            }
        }
        
        /// Creates a predicate for tasks in a category with specific completion status
        /// - Parameters:
        ///   - category: The category to filter by
        ///   - isCompleted: Whether to find completed or incomplete tasks
        /// - Returns: A predicate that can be used with SwiftData fetch descriptors
        static func byCategoryAndCompletion(category: TaskCategory, isCompleted: Bool) -> Predicate<Task> {
            #Predicate<Task> { task in
                task.categoryRaw == category.rawValue && task.isCompleted == isCompleted
            }
        }
        
        // MARK: Schedule Filters
        
        /// Creates a predicate for tasks that have a scheduled time
        /// - Returns: A predicate that can be used with SwiftData fetch descriptors
        static func withScheduledTime() -> Predicate<Task> {
            #Predicate<Task> { task in
                task.scheduledTime != nil
            }
        }
    }
}

// MARK: - ModelContext Task Extensions

/// Extension to provide convenience methods for fetching and counting tasks
extension ModelContext {
    // MARK: Fetch Methods
    
    /// Fetches all tasks for a specific category or all categories if nil
    /// - Parameters:
    ///   - category: Optional category to filter by
    ///   - sortBy: Sort descriptors to order the results (defaults to task order)
    /// - Returns: Array of matching Task objects
    /// - Throws: Error if the fetch operation fails
    func fetchTasks(category: TaskCategory? = nil, sortBy: [SortDescriptor<Task>] = []) throws -> [Task] {
        var descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCategory(category))
        descriptor.sortBy = sortBy.isEmpty ? [SortDescriptor(\Task.order)] : sortBy
        return try fetch(descriptor)
    }
    
    /// Fetches incomplete tasks for a specific category or all categories if nil
    /// - Parameters:
    ///   - category: Optional category to filter by
    ///   - sortBy: Sort descriptors to order the results (defaults to task order)
    /// - Returns: Array of matching incomplete Task objects
    /// - Throws: Error if the fetch operation fails
    func fetchIncompleteTasks(category: TaskCategory? = nil, sortBy: [SortDescriptor<Task>] = []) throws -> [Task] {
        if let category = category {
            var descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCategoryAndCompletion(category: category, isCompleted: false))
            descriptor.sortBy = sortBy.isEmpty ? [SortDescriptor(\Task.order)] : sortBy
            return try fetch(descriptor)
        } else {
            var descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCompletion(isCompleted: false))
            descriptor.sortBy = sortBy.isEmpty ? [SortDescriptor(\Task.order)] : sortBy
            return try fetch(descriptor)
        }
    }
    
    /// Fetches completed tasks for a specific category or all categories if nil
    /// - Parameters:
    ///   - category: Optional category to filter by
    ///   - sortBy: Sort descriptors to order the results (defaults to task order)
    /// - Returns: Array of matching completed Task objects
    /// - Throws: Error if the fetch operation fails
    func fetchCompletedTasks(category: TaskCategory? = nil, sortBy: [SortDescriptor<Task>] = []) throws -> [Task] {
        if let category = category {
            var descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCategoryAndCompletion(category: category, isCompleted: true))
            descriptor.sortBy = sortBy.isEmpty ? [SortDescriptor(\Task.order)] : sortBy
            return try fetch(descriptor)
        } else {
            var descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCompletion(isCompleted: true))
            descriptor.sortBy = sortBy.isEmpty ? [SortDescriptor(\Task.order)] : sortBy
            return try fetch(descriptor)
        }
    }
    
    // MARK: Count Methods
    
    /// Counts all tasks in a specific category or all categories if nil
    /// - Parameter category: Optional category to filter by
    /// - Returns: The number of matching tasks
    /// - Throws: Error if the count operation fails
    func countTasks(category: TaskCategory? = nil) throws -> Int {
        let descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCategory(category))
        return try fetchCount(descriptor)
    }
    
    /// Counts incomplete tasks in a specific category or all categories if nil
    /// - Parameter category: Optional category to filter by
    /// - Returns: The number of matching incomplete tasks
    /// - Throws: Error if the count operation fails
    func countIncompleteTasks(category: TaskCategory? = nil) throws -> Int {
        if let category = category {
            let descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCategoryAndCompletion(category: category, isCompleted: false))
            return try fetchCount(descriptor)
        } else {
            let descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCompletion(isCompleted: false))
            return try fetchCount(descriptor)
        }
    }
    
    /// Counts completed tasks in a specific category or all categories if nil
    /// - Parameter category: Optional category to filter by
    /// - Returns: The number of matching completed tasks
    /// - Throws: Error if the count operation fails
    func countCompletedTasks(category: TaskCategory? = nil) throws -> Int {
        if let category = category {
            let descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCategoryAndCompletion(category: category, isCompleted: true))
            return try fetchCount(descriptor)
        } else {
            let descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCompletion(isCompleted: true))
            return try fetchCount(descriptor)
        }
    }
}
