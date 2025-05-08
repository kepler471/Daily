// 
//  Task+Extensions.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import Foundation
import SwiftData

extension Task {
    /// Predefined predicates for common Task queries
    enum Predicates {
        /// Predicate to filter tasks by category, or all categories if nil
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
        
        /// Predicate to filter tasks by completion status
        static func byCompletion(isCompleted: Bool) -> Predicate<Task> {
            #Predicate<Task> { task in
                task.isCompleted == isCompleted
            }
        }
        
        /// Predicate for tasks in a category with specific completion status
        static func byCategoryAndCompletion(category: TaskCategory, isCompleted: Bool) -> Predicate<Task> {
            #Predicate<Task> { task in
                task.categoryRaw == category.rawValue && task.isCompleted == isCompleted
            }
        }
        
        /// Predicate for tasks with a scheduled time
        static func withScheduledTime() -> Predicate<Task> {
            #Predicate<Task> { task in
                task.scheduledTime != nil
            }
        }
    }
}

// Extension to provide convenience methods for fetching tasks
extension ModelContext {
    /// Fetch all tasks for a specific category or all categories if nil
    func fetchTasks(category: TaskCategory? = nil, sortBy: [SortDescriptor<Task>] = []) throws -> [Task] {
        var descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCategory(category))
        descriptor.sortBy = sortBy.isEmpty ? [SortDescriptor(\Task.order)] : sortBy
        return try fetch(descriptor)
    }
    
    /// Fetch incomplete tasks for a specific category or all categories if nil
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
    
    /// Fetch completed tasks for a specific category or all categories if nil
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
    
    /// Count tasks in a specific category or all categories if nil
    func countTasks(category: TaskCategory? = nil) throws -> Int {
        var descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCategory(category))
        return try fetchCount(descriptor)
    }
    
    /// Count incomplete tasks in a specific category or all categories if nil
    func countIncompleteTasks(category: TaskCategory? = nil) throws -> Int {
        if let category = category {
            var descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCategoryAndCompletion(category: category, isCompleted: false))
            return try fetchCount(descriptor)
        } else {
            var descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCompletion(isCompleted: false))
            return try fetchCount(descriptor)
        }
    }
    
    /// Count completed tasks in a specific category or all categories if nil
    func countCompletedTasks(category: TaskCategory? = nil) throws -> Int {
        if let category = category {
            var descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCategoryAndCompletion(category: category, isCompleted: true))
            return try fetchCount(descriptor)
        } else {
            var descriptor = FetchDescriptor<Task>(predicate: Task.Predicates.byCompletion(isCompleted: true))
            return try fetchCount(descriptor)
        }
    }
}