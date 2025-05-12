//
//  Todo+Extensions.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import Foundation
import SwiftData

// MARK: - Todo Query Predicates

extension Todo {
    /// Predefined predicates for common Todo queries
    ///
    /// This nested enum provides reusable SwiftData predicates for filtering todos
    /// in various ways, making database queries more consistent and maintainable.
    enum Predicates {
        // MARK: Category Filters

        /// Creates a predicate to filter todos by category, or all categories if nil
        /// - Parameter category: The category to filter by, or nil for all categories
        /// - Returns: A predicate that can be used with SwiftData fetch descriptors
        static func byCategory(_ category: TodoCategory?) -> Predicate<Todo> {
            if let category = category {
                return #Predicate<Todo> { todo in
                    todo.categoryRaw == category.rawValue
                }
            } else {
                // Return a predicate that matches all todos
                return #Predicate<Todo> { _ in true }
            }
        }

        // MARK: Completion Filters

        /// Creates a predicate to filter todos by completion status
        /// - Parameter isCompleted: Whether to find completed or incomplete todos
        /// - Returns: A predicate that can be used with SwiftData fetch descriptors
        static func byCompletion(isCompleted: Bool) -> Predicate<Todo> {
            #Predicate<Todo> { todo in
                todo.isCompleted == isCompleted
            }
        }

        /// Creates a predicate for todos in a category with specific completion status
        /// - Parameters:
        ///   - category: The category to filter by
        ///   - isCompleted: Whether to find completed or incomplete todos
        /// - Returns: A predicate that can be used with SwiftData fetch descriptors
        static func byCategoryAndCompletion(category: TodoCategory, isCompleted: Bool) -> Predicate<Todo> {
            #Predicate<Todo> { todo in
                todo.categoryRaw == category.rawValue && todo.isCompleted == isCompleted
            }
        }

        // MARK: Schedule Filters

        /// Creates a predicate for todos that have a scheduled time
        /// - Returns: A predicate that can be used with SwiftData fetch descriptors
        static func withScheduledTime() -> Predicate<Todo> {
            #Predicate<Todo> { todo in
                todo.scheduledTime != nil
            }
        }
    }
}

// MARK: - ModelContext Todo Extensions

/// Extension to provide convenience methods for fetching and counting todos
extension ModelContext {
    // MARK: - Helper Methods

    /// Create a fetch descriptor with a predicate and sort descriptors
    /// - Parameters:
    ///   - predicate: The predicate to filter todos
    ///   - sortBy: Sort descriptors to order the results (defaults to todo order)
    /// - Returns: A configured FetchDescriptor
    private func createTodoDescriptor(
        predicate: Predicate<Todo>,
        sortBy: [SortDescriptor<Todo>] = []
    ) -> FetchDescriptor<Todo> {
        var descriptor = FetchDescriptor<Todo>(predicate: predicate)
        descriptor.sortBy = sortBy.isEmpty ? [SortDescriptor(\Todo.order)] : sortBy
        return descriptor
    }

    // MARK: - Fetch Methods

    /// Fetches all todos for a specific category or all categories if nil
    /// - Parameters:
    ///   - category: Optional category to filter by
    ///   - sortBy: Sort descriptors to order the results (defaults to todo order)
    /// - Returns: Array of matching Todo objects
    /// - Throws: Error if the fetch operation fails
    func fetchTodos(category: TodoCategory? = nil, sortBy: [SortDescriptor<Todo>] = []) throws -> [Todo] {
        let predicate = Todo.Predicates.byCategory(category)
        let descriptor = createTodoDescriptor(predicate: predicate, sortBy: sortBy)
        return try fetch(descriptor)
    }

    /// Fetches todos with specified completion status for a category or all categories
    /// - Parameters:
    ///   - isCompleted: The completion status to filter by
    ///   - category: Optional category to filter by
    ///   - sortBy: Sort descriptors to order the results (defaults to todo order)
    /// - Returns: Array of matching Todo objects
    /// - Throws: Error if the fetch operation fails
    func fetchTodos(
        isCompleted: Bool,
        category: TodoCategory? = nil,
        sortBy: [SortDescriptor<Todo>] = []
    ) throws -> [Todo] {
        let predicate = category != nil
            ? Todo.Predicates.byCategoryAndCompletion(category: category!, isCompleted: isCompleted)
            : Todo.Predicates.byCompletion(isCompleted: isCompleted)

        let descriptor = createTodoDescriptor(predicate: predicate, sortBy: sortBy)
        return try fetch(descriptor)
    }

    /// Fetches incomplete todos for a specific category or all categories if nil
    /// - Parameters:
    ///   - category: Optional category to filter by
    ///   - sortBy: Sort descriptors to order the results (defaults to todo order)
    /// - Returns: Array of matching incomplete Todo objects
    /// - Throws: Error if the fetch operation fails
    func fetchIncompleteTodos(category: TodoCategory? = nil, sortBy: [SortDescriptor<Todo>] = []) throws -> [Todo] {
        return try fetchTodos(isCompleted: false, category: category, sortBy: sortBy)
    }

    /// Fetches completed todos for a specific category or all categories if nil
    /// - Parameters:
    ///   - category: Optional category to filter by
    ///   - sortBy: Sort descriptors to order the results (defaults to todo order)
    /// - Returns: Array of matching completed Todo objects
    /// - Throws: Error if the fetch operation fails
    func fetchCompletedTodos(category: TodoCategory? = nil, sortBy: [SortDescriptor<Todo>] = []) throws -> [Todo] {
        return try fetchTodos(isCompleted: true, category: category, sortBy: sortBy)
    }

    // MARK: - Count Methods

    /// Counts todos with the given predicate
    /// - Parameter predicate: The predicate to filter todos
    /// - Returns: The number of matching todos
    /// - Throws: Error if the count operation fails
    private func countTodosWithPredicate(_ predicate: Predicate<Todo>) throws -> Int {
        let descriptor = FetchDescriptor<Todo>(predicate: predicate)
        return try fetchCount(descriptor)
    }

    /// Counts all todos in a specific category or all categories if nil
    /// - Parameter category: Optional category to filter by
    /// - Returns: The number of matching todos
    /// - Throws: Error if the count operation fails
    func countTodos(category: TodoCategory? = nil) throws -> Int {
        let predicate = Todo.Predicates.byCategory(category)
        return try countTodosWithPredicate(predicate)
    }

    /// Counts todos with specified completion status for a category or all categories
    /// - Parameters:
    ///   - isCompleted: The completion status to filter by
    ///   - category: Optional category to filter by
    /// - Returns: The number of matching todos
    /// - Throws: Error if the count operation fails
    func countTodos(isCompleted: Bool, category: TodoCategory? = nil) throws -> Int {
        let predicate = category != nil
            ? Todo.Predicates.byCategoryAndCompletion(category: category!, isCompleted: isCompleted)
            : Todo.Predicates.byCompletion(isCompleted: isCompleted)

        return try countTodosWithPredicate(predicate)
    }

    /// Counts incomplete todos in a specific category or all categories if nil
    /// - Parameter category: Optional category to filter by
    /// - Returns: The number of matching incomplete todos
    /// - Throws: Error if the count operation fails
    func countIncompleteTodos(category: TodoCategory? = nil) throws -> Int {
        return try countTodos(isCompleted: false, category: category)
    }

    /// Counts completed todos in a specific category or all categories if nil
    /// - Parameter category: Optional category to filter by
    /// - Returns: The number of matching completed todos
    /// - Throws: Error if the count operation fails
    func countCompletedTodos(category: TodoCategory? = nil) throws -> Int {
        return try countTodos(isCompleted: true, category: category)
    }

    /// Fetches a todo by its UUID string (used for notification lookup)
    /// - Parameter uuidString: The string representation of the todo's UUID
    /// - Returns: The todo if found, nil otherwise
    /// - Throws: Error if the fetch operation fails
    func fetchTodoByUUID(_ uuidString: String) throws -> Todo? {
        // We need to fetch all todos and filter by the UUID
        let allTodos = try fetchTodos()

        // Find the todo whose UUID string matches the provided string
        return allTodos.first { $0.uuid.uuidString == uuidString }
    }
}
