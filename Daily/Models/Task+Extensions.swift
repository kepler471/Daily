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
    // MARK: - Helper Methods

    /// Create a fetch descriptor with a predicate and sort descriptors
    /// - Parameters:
    ///   - predicate: The predicate to filter tasks
    ///   - sortBy: Sort descriptors to order the results (defaults to task order)
    /// - Returns: A configured FetchDescriptor
    private func createTaskDescriptor(
        predicate: Predicate<Task>,
        sortBy: [SortDescriptor<Task>] = []
    ) -> FetchDescriptor<Task> {
        var descriptor = FetchDescriptor<Task>(predicate: predicate)
        descriptor.sortBy = sortBy.isEmpty ? [SortDescriptor(\Task.order)] : sortBy
        return descriptor
    }

    // MARK: - Fetch Methods

    /// Fetches all tasks for a specific category or all categories if nil
    /// - Parameters:
    ///   - category: Optional category to filter by
    ///   - sortBy: Sort descriptors to order the results (defaults to task order)
    /// - Returns: Array of matching Task objects
    /// - Throws: Error if the fetch operation fails
    func fetchTasks(category: TaskCategory? = nil, sortBy: [SortDescriptor<Task>] = []) throws -> [Task] {
        let predicate = Task.Predicates.byCategory(category)
        let descriptor = createTaskDescriptor(predicate: predicate, sortBy: sortBy)
        return try fetch(descriptor)
    }

    /// Fetches tasks with specified completion status for a category or all categories
    /// - Parameters:
    ///   - isCompleted: The completion status to filter by
    ///   - category: Optional category to filter by
    ///   - sortBy: Sort descriptors to order the results (defaults to task order)
    /// - Returns: Array of matching Task objects
    /// - Throws: Error if the fetch operation fails
    func fetchTasks(
        isCompleted: Bool,
        category: TaskCategory? = nil,
        sortBy: [SortDescriptor<Task>] = []
    ) throws -> [Task] {
        let predicate = category != nil
            ? Task.Predicates.byCategoryAndCompletion(category: category!, isCompleted: isCompleted)
            : Task.Predicates.byCompletion(isCompleted: isCompleted)

        let descriptor = createTaskDescriptor(predicate: predicate, sortBy: sortBy)
        return try fetch(descriptor)
    }

    /// Fetches incomplete tasks for a specific category or all categories if nil
    /// - Parameters:
    ///   - category: Optional category to filter by
    ///   - sortBy: Sort descriptors to order the results (defaults to task order)
    /// - Returns: Array of matching incomplete Task objects
    /// - Throws: Error if the fetch operation fails
    func fetchIncompleteTasks(category: TaskCategory? = nil, sortBy: [SortDescriptor<Task>] = []) throws -> [Task] {
        return try fetchTasks(isCompleted: false, category: category, sortBy: sortBy)
    }

    /// Fetches completed tasks for a specific category or all categories if nil
    /// - Parameters:
    ///   - category: Optional category to filter by
    ///   - sortBy: Sort descriptors to order the results (defaults to task order)
    /// - Returns: Array of matching completed Task objects
    /// - Throws: Error if the fetch operation fails
    func fetchCompletedTasks(category: TaskCategory? = nil, sortBy: [SortDescriptor<Task>] = []) throws -> [Task] {
        return try fetchTasks(isCompleted: true, category: category, sortBy: sortBy)
    }

    // MARK: - Count Methods

    /// Counts tasks with the given predicate
    /// - Parameter predicate: The predicate to filter tasks
    /// - Returns: The number of matching tasks
    /// - Throws: Error if the count operation fails
    private func countTasksWithPredicate(_ predicate: Predicate<Task>) throws -> Int {
        let descriptor = FetchDescriptor<Task>(predicate: predicate)
        return try fetchCount(descriptor)
    }

    /// Counts all tasks in a specific category or all categories if nil
    /// - Parameter category: Optional category to filter by
    /// - Returns: The number of matching tasks
    /// - Throws: Error if the count operation fails
    func countTasks(category: TaskCategory? = nil) throws -> Int {
        let predicate = Task.Predicates.byCategory(category)
        return try countTasksWithPredicate(predicate)
    }

    /// Counts tasks with specified completion status for a category or all categories
    /// - Parameters:
    ///   - isCompleted: The completion status to filter by
    ///   - category: Optional category to filter by
    /// - Returns: The number of matching tasks
    /// - Throws: Error if the count operation fails
    func countTasks(isCompleted: Bool, category: TaskCategory? = nil) throws -> Int {
        let predicate = category != nil
            ? Task.Predicates.byCategoryAndCompletion(category: category!, isCompleted: isCompleted)
            : Task.Predicates.byCompletion(isCompleted: isCompleted)

        return try countTasksWithPredicate(predicate)
    }

    /// Counts incomplete tasks in a specific category or all categories if nil
    /// - Parameter category: Optional category to filter by
    /// - Returns: The number of matching incomplete tasks
    /// - Throws: Error if the count operation fails
    func countIncompleteTasks(category: TaskCategory? = nil) throws -> Int {
        return try countTasks(isCompleted: false, category: category)
    }

    /// Counts completed tasks in a specific category or all categories if nil
    /// - Parameter category: Optional category to filter by
    /// - Returns: The number of matching completed tasks
    /// - Throws: Error if the count operation fails
    func countCompletedTasks(category: TaskCategory? = nil) throws -> Int {
        return try countTasks(isCompleted: true, category: category)
    }

    /// Fetches a task by its hash identifier (used for notification lookup)
    /// - Parameter hashId: The string hash identifier of the task
    /// - Returns: The task if found, nil otherwise
    /// - Throws: Error if the fetch operation fails
    func fetchTaskByHashId(_ hashId: String) throws -> Task? {
        // We need to fetch all tasks and filter by the hash value
        // since we can't directly query by the hash of the id
        let allTasks = try fetchTasks()

        // Find the task whose id hash matches the provided hash
        return allTasks.first { String($0.id.hashValue) == hashId }
    }
}
