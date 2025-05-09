//
//  Task.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import Foundation
import SwiftData

// MARK: - Enums

/// Represents the category of a task in the Daily app
/// - required: Tasks that must be completed daily
/// - suggested: Optional tasks for daily completion
enum TaskCategory: String, Codable, Hashable {
    case required
    case suggested
}

// MARK: - Task Model

/// Represents a daily task that can be tracked and completed
/// 
/// The `Task` model is the core data structure used in the Daily app. It stores
/// information about tasks that need to be completed, including their title,
/// order, category, completion status, and creation time.
@Model
final class Task {
    // MARK: Properties
    
    /// The title or description of the task
    var title: String
    
    /// The display order for the task (lower numbers appear first)
    var order: Int
    
    /// The raw string representation of the task category (for SwiftData compatibility)
    var categoryRaw: String
    
    /// Optional scheduled time for when the task should be completed
    var scheduledTime: Date?
    
    /// Whether the task has been completed
    var isCompleted: Bool
    
    /// When the task was created
    var createdAt: Date
    
    // MARK: Computed Properties
    
    /// The category of the task (required or suggested)
    var category: TaskCategory {
        get {
            TaskCategory(rawValue: categoryRaw) ?? .required
        }
        set {
            categoryRaw = newValue.rawValue
        }
    }
    
    // MARK: Initializers
    
    /// Creates a new task with the specified attributes
    /// - Parameters:
    ///   - title: The title of the task
    ///   - order: The display order (lower numbers appear first)
    ///   - category: The category of the task (default: .required)
    ///   - scheduledTime: Optional scheduled time for the task
    init(title: String, order: Int, category: TaskCategory = .required, scheduledTime: Date? = nil) {
        self.title = title
        self.order = order
        self.categoryRaw = category.rawValue
        self.scheduledTime = scheduledTime
        self.isCompleted = false
        self.createdAt = Date()
    }
    
    /// Empty initializer required by SwiftData for model creation
    init() {
        self.title = ""
        self.order = 0
        self.categoryRaw = TaskCategory.required.rawValue
        self.scheduledTime = nil
        self.isCompleted = false
        self.createdAt = Date()
    }
}